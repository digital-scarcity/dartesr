// import 'package:dartesr/main.dart';
import 'package:test/test.dart';
import 'package:dartesr/eos_service.dart';
import 'package:safe_config/safe_config.dart';
import 'dart:io';

class ApplicationConfiguration extends Configuration {
 	ApplicationConfiguration(String fileName) : super.fromFile(File(fileName));
	
	String endpoint;
  String privateKey;
  String accountName;
  String transaction;
}

void main() {

  var config, eos;

  config = ApplicationConfiguration('config.yaml');
  print ('Endpoint              :  ${config.endpoint}');
  print ('Private Key           :  ${config.privateKey}');
  print ('Account Name          :  ${config.accountName}');
  eos = EosService (config.endpoint, config.accountName, config.privateKey);
  // setUp(() async {
    
  // });

  test('Decode trx: voteproducer', () async {
    var trx = 'esr:gmNgZGRkAIFXBqEFopc6760yugsVYWBggtKCMIEFRnclpF9eTWUACgAA';

    var readableRequest = await eos.toAction(trx);
    print('Action Contract       : ' + readableRequest['account']);
    print('Action Name           : ' + readableRequest['action']);
    print('Action Data           : ' + readableRequest['data']);
    expect(readableRequest['account'], 'eosio');
    expect(readableRequest['action'], 'voteproducer');
    expect(readableRequest['data'], '{voter: ............1, proxy: greymassvote, producers: []}');
  });

  test('Decode trx: transfer, no memo', () async {
    var trx = 'esr:gmPgY2BY1mTC_MoglIGBIVzX5uxZRkYGCGCC0ooGmvN67fgn2jEwGKz9xbbCE6aAJcTHPxjEAAoAAA';

    var readableRequest = await eos.toAction(trx);
    print('Action Contract       : ' + readableRequest['account']);
    print('Action Name           : ' + readableRequest['action']);
    print('Action Data           : ' + readableRequest['data']);
    expect(readableRequest['account'], 'eosio.token');
    expect(readableRequest['action'], 'transfer');
    expect(readableRequest['data'], '{from: buckyjohnson, to: dao.hypha, quantity: 0.0001 TLOS, memo: }');
  });

  test('Decode trx: transfer, with memo', () async {
    var trx = 'esr:gmPgY2BY1mTC_MoglIGBIVzX5uxZRkYGCGCC0qoGmvN67fgn2jn4Or1btXLGdJgClhAf_2AQXZJaXAIUBAA';

    var readableRequest = await eos.toAction(trx);
    print('Action Contract       : ' + readableRequest['account']);
    print('Action Name           : ' + readableRequest['action']);
    print('Action Data           : ' + readableRequest['data']);
    expect(readableRequest['account'], 'eosio.token');
    expect(readableRequest['action'], 'transfer');
    expect(readableRequest['data'], '{from: buckyjohnson, to: mygenericdao, quantity: 0.0001 TLOS, memo: test}');
  });

  test('Decode transactions', () async {
    var trx = 'esr:gmNgZGBY1mTC_MoglIGBIVzX5uxZRqAQGDBBaVUgXsCs_DmJQdM2fKn35ySYAhZX_2AwXZJaXAIUBAA';

    var readableRequest = await eos.toAction(trx);
    print('Action Contract       : ' + readableRequest['account']);
    print('Action Name           : ' + readableRequest['action']);
    print('Action Data           : ' + readableRequest['data']);
    expect(readableRequest['account'], 'eosio.token');
    expect(readableRequest['action'], 'transfer');
    expect(readableRequest['data'], '{from: gftma.x, to: gftorderbook, quantity: 0.0001 EOS, memo: test}');
  });

  test('Decode transactions', () async {
    // var trx = 'esr:gmNgYmBY1mTC_MoglIGBIVzX5uxZRkYGCGCC0qogomGPxAQGBoO1v9hWeMIUsIT4-AeD6JLU4hKgIAA';
    var trx = 'esr:gmNgYmBY1mTC_MoglIGBIVzX5uxZRkYGCGCC0qogomGPxAQGBoO1v9hWeMIUsIT4-AeD6JLU4hKgIAA';

    var readableRequest = await eos.toAction(trx);
    print('Action Contract       : ' + readableRequest['account']);
    print('Action Name           : ' + readableRequest['action']);
    print('Action Data           : ' + readableRequest['data']);
    expect(readableRequest['account'], 'eosio.token');
    expect(readableRequest['action'], 'transfer');
    expect(readableRequest['data'], '{from: m.gft, to: dao.hypha, quantity: 0.0001 TLOS, memo: test}');
  });
}
