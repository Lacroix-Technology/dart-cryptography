// Copyright 2019-2020 Gohilla Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/src/utils/hex.dart';
import 'package:test/test.dart';

void main() {
  group('CipherWithAppendedMac:', () {
    const plainText = <int>[1, 2, 3];
    final secretKey = chacha20.newSecretKeySync();
    final nonce = chacha20.newNonce();
    const hmac = Hmac(sha256);
    const cipher = CipherWithAppendedMac(chacha20, hmac);
    final cipherTextWithoutMac = chacha20.encryptSync(
      plainText,
      secretKey: secretKey,
      nonce: nonce,
    );
    final mac = hmac.calculateMacSync(
      cipherTextWithoutMac,
      secretKey: secretKey,
    );
    final cipherText = [
      ...cipherTextWithoutMac,
      ...mac.bytes,
    ];

    test('name', () {
      expect(cipher.name, 'chacha20-Hmac(sha256)');
    });

    test('isAuthenticated', () {
      expect(cipher.isAuthenticated, true);
    });

    test('secretKeyLength', () {
      expect(cipher.secretKeyLength, 32);
    });

    test('newSecretKey()', () {
      expect(cipher.newSecretKeySync().extractSync().length, 32);
    });

    test('nonceLength', () {
      expect(cipher.nonceLength, 12);
    });

    test('newNonce()', () {
      final nonce = cipher.newNonce();
      expect(nonce.bytes.length, 12);
    });

    test('encrypt(...)', () async {
      final actual = await cipher.encrypt(
        plainText,
        secretKey: secretKey,
        nonce: nonce,
      );
      expect(
        hexFromBytes(actual),
        hexFromBytes(cipherText),
      );
    });

    test('encryptSync(...)', () {
      final actual = cipher.encryptSync(
        plainText,
        secretKey: secretKey,
        nonce: nonce,
      );
      expect(
        hexFromBytes(actual),
        hexFromBytes(cipherText),
      );
    });

    test('decrypt(...)', () async {
      final actual = await cipher.decrypt(
        cipherText,
        secretKey: secretKey,
        nonce: nonce,
      );
      expect(
        hexFromBytes(actual),
        hexFromBytes(plainText),
      );
    });

    test('decryptSync(...)', () {
      final actual = cipher.decryptSync(
        cipherText,
        secretKey: secretKey,
        nonce: nonce,
      );
      expect(
        hexFromBytes(actual),
        hexFromBytes(plainText),
      );
    });

    test('decrypt(...) throws when MAC is incorrect', () async {
      final newCipherText = Uint8List.fromList(cipherText);
      newCipherText[newCipherText.length - 1] ^= 0xFF;

      await expectLater(
        cipher.decrypt(
          newCipherText,
          secretKey: secretKey,
          nonce: nonce,
        ),
        throwsA(isA<MacValidationException>()),
      );
    });

    test('decryptSync(...) throws when MAC is incorrect', () {
      final newCipherText = Uint8List.fromList(cipherText);
      newCipherText[newCipherText.length - 1] ^= 0xFF;

      expect(
        () => cipher.decryptSync(
          newCipherText,
          secretKey: secretKey,
          nonce: nonce,
        ),
        throwsA(isA<MacValidationException>()),
      );
    });
  });
}
