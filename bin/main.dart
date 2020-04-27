import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:dartesr/eos_service.dart';
import 'package:eosdart/eosdart.dart';
import 'package:http/http.dart' as http;
import 'package:safe_config/safe_config.dart';
import 'package:eosdart/src/serialize.dart' as ser;
import 'package:args/args.dart';

class MainConfiguration extends Configuration {
  MainConfiguration(String fileName) : super.fromFile(File(fileName));

  String endpoint;
  String account;
  String privateKey;
}

Future<dynamic> readResponse(HttpClientResponse response) {
  var completer = Completer();
  var contents = StringBuffer();
  response.transform(utf8.decoder).listen((data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

void main(List<String> arguments) async {
  var config;

  var parser = ArgParser();
  parser.addFlag('use-service', defaultsTo: false);
  parser.addOption('esr', abbr: 'e');
  parser.addFlag('verbose', defaultsTo: false, callback: (verbose) {
    if (verbose) print('Verbose mode = true');
  });

  var args = parser.parse(arguments);

  config = MainConfiguration('bin/config.yaml');
  if (args['verbose']) {
    print('Endpoint               :   ${config.endpoint}');
    print('Test Account           :   ${config.account}');
    print('Test Private Key       :   ${config.privateKey}');
    print('ESR                    :   ' + args['esr']);
  }

  var trxEos =
      await EosService(config.endpoint, config.account, config.privateKey);

  if (args['use-service']) {
    var request = await HttpClient().post('localhost', 3000, 'decode')
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'authorization': {'actor': config.account, 'permission': 'active'},
        'esrUri': args['esr']
      }));
    var response = await request.close();
    var strResponse = await readResponse(response);
    Map<String, dynamic> payload = jsonDecode(strResponse);

    print('\n**** Ricardian Contract ****\n');
    print(payload['ricardianHtml']);

    var trx = await Transaction.fromJson(payload['transaction']);
    print('\n**** Submitting Transaction to : ' + config.endpoint);
    print('Transaction ID        :   ' +
        (await trxEos.client.pushTransaction(trx))['transaction_id']);
  } else {
    var esr = await trxEos.toRequest(args['esr']);
    print('Ricardian contract     :   ' + esr.ricardian);

    print('Execution action on    :   ' + esr.action.account);
    print('Action                 :   ' + esr.action.name);
    print('Signing with           :   ' + esr.account + '@' + esr.permission);
  }

  print('');
}
