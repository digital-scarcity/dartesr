import 'package:dartesr/esr_reader.dart';
import 'package:eosdart/eosdart.dart';
import 'package:eosdart/src/client.dart';

class EosService {
  String privateKey;
  String endpoint;
  String accountName;
  EOSClient client;
  EsrReader esrReader;

  EosService(String endpoint, String accountName, String privateKey) {
    this.endpoint = endpoint;
    this.accountName = accountName;
    this.privateKey = privateKey;    
    client = EOSClient(this.endpoint, 'v1', privateKeys: [privateKey]);
    esrReader = EsrReader(client, accountName);
  }

  Future<dynamic> send(String esr) async {
    var t = await esrReader.toTransaction(esr);
    return client.pushTransaction(t, broadcast: true);
  }

  Future<Action> toAction(String esrString) async {
    return await esrReader.toAction(esrString);
  }
}
