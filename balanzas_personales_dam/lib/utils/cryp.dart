import 'dart:convert';
import 'package:crypto/crypto.dart';

List<int> deriveKey(String password) {
  final passBytes = utf8.encode(password);
  final digest = sha256.convert(passBytes).bytes;
  return digest;
}

List<int> pbkdf2({
  required String password,
  required List<int> salt,
  required int iterations,
  required int keyLength,
}) {
  final hmac = Hmac(sha256, utf8.encode(password));
  List<int> key = List.filled(keyLength, 0);
  var block = 1;

  while ((block - 1) * 32 < keyLength) {
    var u = hmac.convert(salt + _int32(block)).bytes;
    var output = u;

    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < output.length; j++) {
        output[j] ^= u[j];
      }
    }

    for (
      int i = 0;
      i < output.length && ((block - 1) * 32 + i) < keyLength;
      i++
    ) {
      key[(block - 1) * 32 + i] = output[i];
    }

    block++;
  }

  return key;
}

List<int> _int32(int i) {
  return [(i >> 24) & 0xff, (i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff];
}

List<int> xorEncrypt(List<int> data, List<int> key) {
  return List<int>.generate(data.length, (i) => data[i] ^ key[i % key.length]);
}
