import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project/manager/app_startup_diagnostics.dart';

void main() {
  test(
    'logs the existing DID, local interface addresses and public IPv4',
    () async {
      final messages = <String>[];
      await logStartupDeviceAndNetwork(
        deviceId: 'existing-did',
        readInterfaces: () async => [
          _Interface('wlan0', [
            InternetAddress('192.168.1.10'),
            InternetAddress('2001:db8::10'),
          ]),
          _Interface('rmnet0', [InternetAddress('10.0.0.2')]),
        ],
        readPublicIp: () async => {'ip': '203.0.113.10'},
        log: messages.add,
      );
      expect(messages, [
        '[AppStartup] DID=existing-did',
        '[AppStartup] Local IP (wlan0/IPv4)=192.168.1.10',
        '[AppStartup] Local IP (wlan0/IPv6)=2001:db8::10',
        '[AppStartup] Local IP (rmnet0/IPv4)=10.0.0.2',
        '[AppStartup] Public IP (ipify)=203.0.113.10',
      ]);
    },
  );

  test('no local IP or DID is explicit, and public IPv6 is accepted', () async {
    final messages = <String>[];
    await logStartupDeviceAndNetwork(
      deviceId: '',
      readInterfaces: () async => [
        _Interface('lo', [
          InternetAddress.loopbackIPv4,
          InternetAddress.loopbackIPv6,
        ]),
        _Interface('eth0', [
          InternetAddress('169.254.1.2'),
          InternetAddress('fe80::1'),
        ]),
      ],
      readPublicIp: () async => {'ip': '2001:db8::20'},
      log: messages.add,
    );
    expect(messages, [
      '[AppStartup] DID=unavailable',
      '[AppStartup] Local IP=unavailable (no network address)',
      '[AppStartup] Public IP (ipify)=2001:db8::20',
    ]);
  });

  test(
    'native interface errors do not prevent public IP logging or startup',
    () async {
      final messages = <String>[];
      await logStartupDeviceAndNetwork(
        deviceId: 'did',
        readInterfaces: () async => throw const SocketException('Unavailable'),
        readPublicIp: () async => {'ip': '203.0.113.10'},
        log: messages.add,
      );
      expect(messages[1], startsWith('[AppStartup] Local IP=unavailable'));
      expect(messages.last, '[AppStartup] Public IP (ipify)=203.0.113.10');
    },
  );

  test('offline public IP lookup keeps DID and local IP logs intact', () async {
    final messages = <String>[];
    await logStartupDeviceAndNetwork(
      deviceId: 'did',
      readInterfaces: () async => [
        _Interface('wlan0', [InternetAddress('192.168.1.10')]),
      ],
      readPublicIp: () async => throw const SocketException('Offline'),
      log: messages.add,
    );
    expect(messages[0], '[AppStartup] DID=did');
    expect(messages[1], '[AppStartup] Local IP (wlan0/IPv4)=192.168.1.10');
    expect(messages[2], startsWith('[AppStartup] Public IP=unavailable'));
  });

  for (final response in [
    null,
    'invalid',
    {'ip': 'not an IP'},
    {'ip': '127.0.0.1'},
  ]) {
    test(
      'malformed public IP responses are logged, not thrown: $response',
      () async {
        final messages = <String>[];
        await logStartupDeviceAndNetwork(
          deviceId: 'did',
          readInterfaces: () async => [],
          readPublicIp: () async => response,
          log: messages.add,
        );
        expect(messages.last, contains('Invalid public IP response'));
      },
    );
  }
}

class _Interface implements NetworkInterface {
  _Interface(this.name, this.addresses);
  @override
  final String name;
  @override
  final List<InternetAddress> addresses;
  @override
  int get index => 0;
}
