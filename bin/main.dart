// import 'package:cli/convert.dart' as convert;
import 'package:dartesr/eos_service.dart';
import 'package:safe_config/safe_config.dart';
import 'dart:io';

void main(List<String> arguments) async {

  var config = ApplicationConfiguration('config.yaml');
  print ('Endpoint              :  ${config.endpoint}');
  print ('Private Key           :  ${config.privateKey}');
  print ('Account Name          :  ${config.accountName}');
  print ('Transaction           :  ${config.transaction}');

  var eos = EosService (config.endpoint, config.accountName, config.privateKey);
  var action = await eos.toAction(config.transaction);
  var response = await eos.sendTransaction(action); 
  print ('Transaction ID        : ' + response['transaction_id']);
}


class ApplicationConfiguration extends Configuration {
 	ApplicationConfiguration(String fileName) : super.fromFile(File(fileName));
	
	String endpoint;
  String privateKey;
  String accountName;
  String transaction;
}