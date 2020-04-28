@TestOn('mac-os') // only run on my machine b/c I have nodeos running

import 'dart:io';

import 'package:dartesr/eos_service.dart';
import 'package:eosdart/eosdart.dart';
import 'package:safe_config/safe_config.dart';
import 'package:test/test.dart';

class TestConfiguration extends Configuration {
  TestConfiguration(String fileName) : super.fromFile(File(fileName));

  String ttEndpoint;
  String actor;
  String testPrivateKey;
}

void main() {
  var config, trxEos;

  config = TestConfiguration('test/telos_testnet.yaml');
  print('Telos Test Endpoint    :   ${config.ttEndpoint}');
  print('Test Account A         :   ${config.actor}');
  print('Test Private Key       :   ${config.testPrivateKey}');

  trxEos = EosService(config.ttEndpoint, config.actor, config.testPrivateKey);

  group('ESR Group', () {
    test('Get node info', () async {
      trxEos.client.getInfo().then((NodeInfo nodeInfo) {
        expect(nodeInfo.headBlockNum > 0, isTrue);
      });
    });

    test('Decode trx: voteproducer', () async {
      var trx = 'esr:gmPgYwCDVwahIMqjeK8dIyNEiIEJSivABGA0F5RmCfHxD4aIAwA';

      var action = await trxEos.toAction(trx);
      expect(action.account, 'eosio');
      expect(action.name, 'buyram');
      expect(action.data['payer'], '............1');
      expect(action.data['receiver'], '............1');
      expect(action.data['quant'], '0.0010 TLOS');
    });

    test('Decode trx: transfer, no memo', () async {
      var trx =
          'esr:gmPgY2BY1mTC_MoglIGBIVzX5uxZRkYGCGCC0ooGmvN67fgn2jEwGKz9xbbCE6aAJcTHPxjEAAoAAA';

      var trxResponse = await trxEos.send(trx);
      print('Transaction ID      : ' + trxResponse['transaction_id']);
      //expect (trxResponse['transaction_id'])
    });
  });
}
