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

      var readableRequest = await decoderEos.toAction(trx);
      print('Action Contract       : ' + readableRequest['account']);
      print('Action Name           : ' + readableRequest['action']);
      print('Action Data           : ' + readableRequest['data']);
      expect(readableRequest['account'], 'eosio');
      expect(readableRequest['action'], 'voteproducer');
      expect(readableRequest['data'],
          '{voter: ............1, proxy: greymassvote, producers: []}');
    });

    test('Decode trx: transfer, no memo', () async {
      var trx =
          'esr:gmPgY2BY1mTC_MoglIGBIVzX5uxZRkYGCGCC0ooGmvN67fgn2jEwGKz9xbbCE6aAJcTHPxjEAAoAAA';

      var readableRequest = await decoderEos.toAction(trx);
      print('Action Contract       : ' + readableRequest['account']);
      print('Action Name           : ' + readableRequest['action']);
      print('Action Data           : ' + readableRequest['data']);
      expect(readableRequest['account'], 'eosio.token');
      expect(readableRequest['action'], 'transfer');
      expect(readableRequest['data'],
          '{from: buckyjohnson, to: dao.hypha, quantity: 0.0001 TLOS, memo: }');
    });

    test('Decode trx: transfer, with memo', () async {
      var trx =
          'esr:gmPgY2BY1mTC_MoglIGBIVzX5uxZRkYGCGCC0qoGmvN67fgn2jn4Or1btXLGdJgClhAf_2AQXZJaXAIUBAA';

      var readableRequest = await decoderEos.toAction(trx);
      print('Action Contract       : ' + readableRequest['account']);
      print('Action Name           : ' + readableRequest['action']);
      print('Action Data           : ' + readableRequest['data']);
      expect(readableRequest['account'], 'eosio.token');
      expect(readableRequest['action'], 'transfer');
      expect(readableRequest['data'],
          '{from: buckyjohnson, to: mygenericdao, quantity: 0.0001 TLOS, memo: test}');
    });

    test('Decode transactions', () async {
      var trx =
          'esr:gmNgZGBY1mTC_MoglIGBIVzX5uxZRqAQGDBBaVUgXsCs_DmJQdM2fKn35ySYAhZX_2AwXZJaXAIUBAA';

      var readableRequest = await decoderEos.toAction(trx);
      print('Action Contract       : ' + readableRequest['account']);
      print('Action Name           : ' + readableRequest['action']);
      print('Action Data           : ' + readableRequest['data']);
      expect(readableRequest['account'], 'eosio.token');
      expect(readableRequest['action'], 'transfer');
      expect(readableRequest['data'],
          '{from: gftma.x, to: gftorderbook, quantity: 0.0001 EOS, memo: test}');
    });

    test('Decode transactions', () async {
      // var trx = 'esr:gmNgYmBY1mTC_MoglIGBIVzX5uxZRkYGCGCC0qogomGPxAQGBoO1v9hWeMIUsIT4-AeD6JLU4hKgIAA';
      var trx =
          'esr:gmNgYmBY1mTC_MoglIGBIVzX5uxZRkYGCGCC0qogomGPxAQGBoO1v9hWeMIUsIT4-AeD6JLU4hKgIAA';

      var readableRequest = await decoderEos.toAction(trx);
      print('Action Contract       : ' + readableRequest['account']);
      print('Action Name           : ' + readableRequest['action']);
      print('Action Data           : ' + readableRequest['data']);
      expect(readableRequest['account'], 'eosio.token');
      expect(readableRequest['action'], 'transfer');
      expect(readableRequest['data'],
          '{from: m.gft, to: dao.hypha, quantity: 0.0001 TLOS, memo: test}');
    });

    test('Get node info', () async {
      trxEos.client.getInfo().then((NodeInfo nodeInfo) {
        expect(nodeInfo.headBlockNum > 0, isTrue);
      });
    });
  });
}
