import 'dart:io';

import 'package:flutter/foundation.dart';

import '../configs/app_device.dart';
import 'http_api.dart';
import 'http_dio_manager.dart';

/// Startup-only diagnostics. Failures are logged, never propagated to app startup.
Future<void> logStartupDeviceAndNetwork({
  String? deviceId,
  Future<List<NetworkInterface>> Function()? readInterfaces,
  Future<Object?> Function()? readPublicIp,
  void Function(String)? log,
}) async {
  final write = log ?? debugPrint;
  final did = (deviceId ?? AppDevice().deviceId).trim();
  write('[AppStartup] DID=${did.isEmpty ? 'unavailable' : did}');

  try {
    final interfaces = await (readInterfaces ?? _readInterfaces)().timeout(
      const Duration(seconds: 2),
    );
    var foundAddress = false;
    for (final network in interfaces) {
      for (final address in network.addresses) {
        if (address.isLoopback || address.isLinkLocal) continue;
        foundAddress = true;
        final type = address.type == InternetAddressType.IPv4 ? 'IPv4' : 'IPv6';
        write(
          '[AppStartup] Local IP (${network.name}/$type)=${address.address}',
        );
      }
    }
    if (!foundAddress) {
      write('[AppStartup] Local IP=unavailable (no network address)');
    }
  } catch (error) {
    write('[AppStartup] Local IP=unavailable ($error)');
  }

  try {
    final response = await (readPublicIp ?? _readPublicIp)().timeout(
      const Duration(seconds: 5),
    );
    final ip = response is Map ? response['ip'] : null;
    final address = ip is String ? InternetAddress.tryParse(ip.trim()) : null;
    if (address == null || address.isLoopback || address.isLinkLocal) {
      throw const FormatException('Invalid public IP response');
    }
    write('[AppStartup] Public IP (ipify)=${address.address}');
  } catch (error) {
    write('[AppStartup] Public IP=unavailable ($error)');
  }
}

Future<List<NetworkInterface>> _readInterfaces() => NetworkInterface.list(
  includeLoopback: false,
  includeLinkLocal: false,
  type: InternetAddressType.any,
);

Future<Object?> _readPublicIp() => HttpDioManager().getExternalJson(
  HttpApi.publicIp,
  queryParameters: const {'format': 'json'},
  timeout: const Duration(seconds: 4),
);
