@TestOn('mac-os')  // only run on my machine b/c I have nodeos running

import 'package:test/test.dart';
import 'package:dartesr/eos_service.dart';
import 'package:eosdart/eosdart.dart';
import 'package:safe_config/safe_config.dart';
import 'dart:io';

class TestConfiguration extends Configuration {
  TestConfiguration(String fileName) : super.fromFile(File(fileName));

  String endpoint;
  String accountA;
  String accountB;
  String testPublicKey;
  String testPrivateKey;
}

void main() {
  var config, trxEos;

  config = TestConfiguration('test/local_test.yaml');
  print('Endpoint               :   ${config.endpoint}');
  print('Test Account A         :   ${config.accountA}');
  print('Test Account B         :   ${config.accountB}');
  print('Test Public Key        :   ${config.testPublicKey}');
  print('Test Private Key       :   ${config.testPrivateKey}');

  trxEos = EosService(config.endpoint, config.accountA, config.testPrivateKey);

  group('Local Transaction Group', () {
    test('Get node info', () async {
      trxEos.client.getInfo().then((NodeInfo nodeInfo) {
        expect(nodeInfo.headBlockNum > 0, isTrue);
      });
    });

    test('Submit transfer', () async {

      var trx = Transaction ()
      ..actions = [
        Action()
        ..account = 'eosio.token'
        ..name = 'transfer'
        ..authorization = [
          Authorization()
            ..actor = config.accountA
            ..permission = 'active'
        ]
        ..data = {
            'from': config.accountA,
            'to': config.accountB,
            'quantity': '0.01 TOKEN',
            'memo': 'test memo',
          }
      ];

      trxEos.client.pushTransaction(trx, broadcast: true).then((trx) {
        print(trx);
      });

    });
  });
}
