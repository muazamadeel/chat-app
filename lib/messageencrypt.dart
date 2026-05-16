import 'dart:convert';

class MessageEncryptionService {
  static final MessageEncryptionService _instance =
      MessageEncryptionService._internal();
  factory MessageEncryptionService() => _instance;
  MessageEncryptionService._internal();

  static const String _secretKey = 'MyMessageKey123';

  /// Encrypt text message
  String encryptMessage(String message) {
    final messageBytes = utf8.encode(message);
    final keyBytes = utf8.encode(_secretKey);

    final encryptedBytes = List<int>.generate(messageBytes.length, (i) {
      final key = keyBytes[i % keyBytes.length];
      return (messageBytes[i] ^ key) + 7;
    });

    return base64Encode(encryptedBytes);
  }

  /// Decrypt text message (SAFE)
  String decryptMessage(String input) {
    // ✅ If not base64, return as-is
    if (!_isBase64(input)) {
      return input;
    }

    try {
      final encryptedBytes = base64Decode(input);
      final keyBytes = utf8.encode(_secretKey);

      final decryptedBytes = List<int>.generate(encryptedBytes.length, (i) {
        final key = keyBytes[i % keyBytes.length];
        return (encryptedBytes[i] - 7) ^ key;
      });

      return utf8.decode(decryptedBytes);
    } catch (e) {
      // ✅ Never crash UI
      return input;
    }
  }

  /// Check if string is Base64
  bool _isBase64(String value) {
    if (value.isEmpty || value.length % 4 != 0) return false;
    final base64Regex = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    return base64Regex.hasMatch(value);
  }
}
