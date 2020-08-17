import 'dart:convert';

import 'package:dartesr/eosio_signing_request.dart';
import 'package:eosdart/eosdart.dart';
import 'package:test/test.dart';

import 'eosio.token.dart';

void main() {
  group('Sign ESR', () {
    test('Transfer transaction', () async {
      var trx =
          'esr:gmPgY2BY1mTC_MoglIGBIVzX5uxZRkYGCGCC0ooGmvN67fgn2jEwGKz9xbbCE6aAJcTHPxjEAAoAAA';

      var request = await EosioSigningRequest.factory(
        null,
        trx,
        'sevenflash42',
        contractAbi: Abi.fromJson(json.decode(tokenAbi)),
      );

      expect(request.action.account, 'eosio.token');
    });

    test('Identity request', () async {
      var esr =
          'esr:AgACAwACO2h0dHBzOi8vY2IuYW5jaG9yLmxpbmsvODE3NzNjYWUtYjUzZS00YTdmLTg2ZjctNzJmOTQzZjhiYTk3AQRsaW5rKgAIAAAA06oHAAKLu05xjZ9d38TXa0W9f_WH76gGXk4wxIzEw31kEpVMQg';

      var request = await EosioSigningRequest.factory(
        null,
        esr,
        'sevenflash42',
      );

      expect(request.action.name, 'identity');
      expect(request.callback, 'https://cb.anchor.link/81773cae-b53e-4a7f-86f7-72f943f8ba97');
    });
  });
}
