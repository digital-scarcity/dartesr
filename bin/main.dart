import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dartesr/eos_service.dart';
import 'package:eosdart/eosdart.dart';
import 'package:safe_config/safe_config.dart';

class MainConfiguration extends Configuration {
  MainConfiguration(String fileName) : super.fromFile(File(fileName));

  String endpoint;
  String account;
  String privateKey;
  String esrServiceHost;
  int esrServicePort;
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
    print('ESR Service Host       :   ${config.esrServiceHost}');
    print('ESR Service Port       :   ${config.esrServicePort}');
    print('ESR                    :   ' + args['esr']);
  }

  var trxEos =
      await EosService(config.endpoint, config.account, config.privateKey);

  switch (arguments[0]) {
    case 'decode':
      if (args['use-service']) {
        var request = await HttpClient()
            .post(config.esrServiceHost, config.esrServicePort, 'decode')
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
        print('Decoded data           :   ' + esr.jsonData);
        print(
            'Signing with           :   ' + esr.account + '@' + esr.permission);

        print('Transaction ID        :   ' +
            (await esr.push())['transaction_id']);
      }
      return;

    case 'addnetwork':
      print('adding a new network');
      return;

    default:
      print(
          'usage: main.dart [ addnetwork | decode [--use-service] {--esr} ] [--verbose]');
      return;
  }
}
