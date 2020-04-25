import 'package:dartesr/eos_service.dart';
import 'package:eosdart/eosdart.dart';
import 'package:safe_config/safe_config.dart';
import 'dart:io';

class MainConfiguration extends Configuration {
  MainConfiguration(String fileName) : super.fromFile(File(fileName));

  String endpoint;
  String account;
  String privateKey;
}

void main(List<String> arguments) async {
  var config;

  config = MainConfiguration('bin/config.yaml');
  print('Endpoint               :   ${config.endpoint}');
  print('Test Account           :   ${config.account}');
  print('Test Private Key       :   ${config.privateKey}');

  var trx = arguments[0];
  print('ESR                    :   ' + trx);
  var trxEos =
      await EosService(config.endpoint, config.account, config.privateKey);

  var esr = await trxEos.toRequest(trx);
  print('Ricardian contract     :   ' + esr.ricardian);

  print('Execution action on    :   ' + esr.action.account);
  print('Action                 :   ' + esr.action.name);
  print('Signing with           :   ' + esr.account + '@' + esr.permission);

  print('');

  print('Transaction ID        :   ' + (await esr.push())['transaction_id']);
}
