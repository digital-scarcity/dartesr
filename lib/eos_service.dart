import 'package:dartesr/eosio_signing_request.dart';
// import 'package:dartesr/esr_reader.dart';
import 'package:eosdart/eosdart.dart';
import 'package:eosdart/src/client.dart';

class EosService {
  String privateKey;
  String endpoint;
  String account;

  EOSClient client;

  EosService(String endpoint, String account, String privateKey) {
    this.endpoint = endpoint;
    this.account = account;
    this.privateKey = privateKey;
    client = EOSClient(this.endpoint, 'v1', privateKeys: [privateKey]);
  }

  Future<EosioSigningRequest> toRequest(String esrUri) async {
    return await EosioSigningRequest.factory(client, esrUri, account);
  }

  // Future<dynamic> send(String esr) async {
  //   var t = await esrReader.toTransaction(esr);
  //   return client.pushTransaction(t, broadcast: true);
  // }

  // Future<Action> toAction(String esrString) async {
  //   return await esrReader.toAction(esrString);
  // }
}
