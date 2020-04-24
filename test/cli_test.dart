import 'package:test/test.dart';
import 'package:dartesr/eos_service.dart';
import 'package:eosdart/eosdart.dart';
import 'package:safe_config/safe_config.dart';
import 'dart:io';

class TestConfiguration extends Configuration {
  TestConfiguration(String fileName) : super.fromFile(File(fileName));

  String endpoint;
  String decoderEndpoint;
  String accountA;
  String accountB;
  String testPublicKey;
  String testPrivateKey;
}

void main() {
  var config, decoderEos, trxEos;

  config = TestConfiguration('test/config.yaml');
  print('Endpoint               :   ${config.endpoint}');
  print('Decoder Endpoint       :   ${config.decoderEndpoint}');
  print('Test Account A         :   ${config.accountA}');
  print('Test Account B         :   ${config.accountB}');
  print('Test Public Key        :   ${config.testPublicKey}');
  print('Test Private Key       :   ${config.testPrivateKey}');

  decoderEos = EosService(config.decoderEndpoint, config.accountA, config.testPrivateKey);
  trxEos = EosService(config.endpoint, config.accountA, config.testPrivateKey);

  group('ESR Group', () {
    test('Decode trx: voteproducer', () async {
      var trx = 'esr:gmNgZGRkAIFXBqEFopc6760yugsVYWBggtKCMIEFRnclpF9eTWUACgAA';
      var action = await decoderEos.toAction(trx);
      expect(action.account, 'eosio');
      expect(action.name, 'voteproducer');
    });

    test('Decode trx: transfer, no memo', () async {
      var trx =
          'esr:gmPgY2BY1mTC_MoglIGBIVzX5uxZRkYGCGCC0ooGmvN67fgn2jEwGKz9xbbCE6aAJcTHPxjEAAoAAA';

      var action = await decoderEos.toAction(trx);
      expect(action.account, 'eosio.token');
      expect(action.name, 'transfer');
      expect(action.data['from'], 'buckyjohnson');
      expect(action.data['to'], 'dao.hypha');
      expect(action.data['quantity'], '0.0001 TLOS');
      expect(action.data['memo'], '');
    });

    test('Decode trx: transfer, with memo', () async {
      var trx =
          'esr:gmPgY2BY1mTC_MoglIGBIVzX5uxZRkYGCGCC0qoGmvN67fgn2jn4Or1btXLGdJgClhAf_2AQXZJaXAIUBAA';

      var action = await decoderEos.toAction(trx);
      expect(action.account, 'eosio.token');
      expect(action.name, 'transfer');
      expect(action.data['from'], 'buckyjohnson');
      expect(action.data['to'], 'mygenericdao');
      expect(action.data['quantity'], '0.0001 TLOS');
      expect(action.data['memo'], 'test');
    });

    test('Decode transactions: EOS with memo', () async {
      var trx =
          'esr:gmNgZGBY1mTC_MoglIGBIVzX5uxZRqAQGDBBaVUgXsCs_DmJQdM2fKn35ySYAhZX_2AwXZJaXAIUBAA';

      var action = await decoderEos.toAction(trx);
      expect(action.account, 'eosio.token');
      expect(action.name, 'transfer');
      expect(action.data['from'], 'gftma.x');
      expect(action.data['to'], 'gftorderbook');
      expect(action.data['quantity'], '0.0001 EOS');
      expect(action.data['memo'], 'test');
    });

    test('Decode transactions, short names', () async {
      var trx =
          'esr:gmNgYmBY1mTC_MoglIGBIVzX5uxZRkYGCGCC0qogomGPxAQGBoO1v9hWeMIUsIT4-AeD6JLU4hKgIAA';

      var action = await decoderEos.toAction(trx);
      expect(action.account, 'eosio.token');
      expect(action.name, 'transfer');
      expect(action.data['from'], 'm.gft');
      expect(action.data['to'], 'dao.hypha');
      expect(action.data['quantity'], '0.0001 TLOS');
      expect(action.data['memo'], 'test');
    });

    test('Get node info', () async {
      trxEos.client.getInfo().then((NodeInfo nodeInfo) {
        expect(nodeInfo.headBlockNum > 0, isTrue);
      });
    });
  });
}
