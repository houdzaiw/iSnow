import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';

class CryptUtil {
  static Future<String> encrypt(String data) async {
    final algorithm = Chacha20.poly1305Aead();
    final secretKey = await algorithm.newSecretKey();

    // Encrypt
    final secretBox = await algorithm.encrypt(
      data.codeUnits,
      secretKey: secretKey,
    );

    final secretKeyBytes = await secretKey.extractBytes();
    final secretKeyHex = hex.encode(secretKeyBytes);

    return secretKeyHex +
        hex.encode(secretBox.nonce) +
        hex.encode(secretBox.mac.bytes) +
        hex.encode(secretBox.cipherText);
  }

  static Future<String> decrypt(String data) async {
    final algorithm = Chacha20.poly1305Aead();
    final secretKey = SecretKey(hex.decode(data.substring(0, 64)));
    final nonce = hex.decode(data.substring(64, 88));
    final mac = Mac(hex.decode(data.substring(88, 120)));
    final cipherText = hex.decode(data.substring(120));

    // Decrypt
    final decrypted = await algorithm.decrypt(
      SecretBox(
        cipherText,
        nonce: nonce,
        mac: mac,
      ),
      secretKey: secretKey,
    );

    return String.fromCharCodes(decrypted);
  }
}
