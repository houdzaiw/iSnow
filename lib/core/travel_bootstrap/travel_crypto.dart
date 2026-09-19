import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';

import 'travel_bootstrap_exception.dart';

final class TravelAesGcm {
  TravelAesGcm({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  Uint8List randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256)),
  );

  String encode(Uint8List bytes) => base64Url.encode(bytes).replaceAll('=', '');

  Uint8List decode(String value) {
    try {
      return Uint8List.fromList(base64Url.decode(base64Url.normalize(value)));
    } on FormatException catch (error, stackTrace) {
      throw TravelBootstrapException(
        'Travel response contains invalid Base64URL.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Uint8List encrypt({
    required Uint8List key,
    required Uint8List iv,
    required String aad,
    required String plaintext,
  }) {
    return _process(
      true,
      key: key,
      iv: iv,
      aad: aad,
      input: Uint8List.fromList(utf8.encode(plaintext)),
    );
  }

  String decrypt({
    required Uint8List key,
    required Uint8List iv,
    required String aad,
    required Uint8List ciphertext,
  }) {
    try {
      return utf8.decode(
        _process(false, key: key, iv: iv, aad: aad, input: ciphertext),
      );
    } on InvalidCipherTextException catch (error, stackTrace) {
      throw TravelBootstrapException(
        'Travel response authentication failed.',
        requiresSessionRefresh: true,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Uint8List _process(
    bool encrypting, {
    required Uint8List key,
    required Uint8List iv,
    required String aad,
    required Uint8List input,
  }) {
    if (key.length != 32 || iv.length != 12) {
      throw const TravelBootstrapException(
        'Travel AES-GCM key or IV is invalid.',
      );
    }
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        encrypting,
        AEADParameters<KeyParameter>(
          KeyParameter(key),
          128,
          iv,
          Uint8List.fromList(utf8.encode(aad)),
        ),
      );
    return cipher.process(input);
  }

  Uint8List rsaOaepSha256({
    required String publicKeyPem,
    required Uint8List plaintext,
  }) {
    try {
      final encoded = publicKeyPem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll(RegExp(r'\s'), '');
      final outer =
          ASN1Parser(Uint8List.fromList(base64Decode(encoded))).nextObject()
              as ASN1Sequence;
      final keyBits = outer.elements[1] as ASN1BitString;
      final rsaKey =
          ASN1Parser(keyBits.contentBytes()).nextObject() as ASN1Sequence;
      final publicKey = RSAPublicKey(
        (rsaKey.elements[0] as ASN1Integer).valueAsBigInteger,
        (rsaKey.elements[1] as ASN1Integer).valueAsBigInteger,
      );
      final cipher = OAEPEncoding.withSHA256(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      return cipher.process(plaintext);
    } on Object catch (error, stackTrace) {
      throw TravelBootstrapException(
        'Travel RSA encryption failed.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
