import 'package:eosdart/eosdart.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:archive/archive.dart';

import 'package:eosdart/src/client.dart';
import 'package:eosdart/src/eosdart_base.dart';
import 'package:eosdart/src/serialize.dart' as ser;
import 'package:eosdart/src/models/abi.dart';

import './decode_string_request.dart';
import './request_abi.dart';

class EosService {
  String privateKey;
  String endpoint;
  String accountName;
  EOSClient client;

  EosService(String endpoint, String accountName, String privateKey) {
    this.endpoint = endpoint;
    this.accountName = accountName;
    this.privateKey = privateKey;
    client = EOSClient(this.endpoint, 'v1', privateKeys: [privateKey]);
  }

  Future<dynamic> sendTransaction(dynamic action) async {
    var transaction = Transaction()
      ..actions = [
        Action()
          ..account = action['account']
          ..name = action['action']
          ..authorization = [
            Authorization()
              ..actor = accountName
              ..permission = 'active'
          ]
          ..data = action['data']
      ];

    return client.pushTransaction(transaction, broadcast: true);
  }

  Future<Map<String, String>> toAction(String scannedString) async {
    var readableReq = await getReadableRequest(scannedString);
    // print('Action Contract       : ' + readableReq['account']);
    // print('Action Name           : ' + readableReq['action']);
    // print('Action Data           : ' + readableReq['data']);
    return readableReq;
  }

  Future<Map<String, String>> getReadableRequest(String trx) async {
    var signingRequest = parseRequest(trx);
    var requestActions = signingRequest['req'][1];
    var action;

    if (requestActions is List) {
      action = requestActions[0];
    } else {
      action = requestActions;
    }

    var account = action['account'];
    var name = action['name'];
    var data = action['data'];

    var dataDecoded = await getReadableAction(account, name, data);

    return {'account': account, 'action': name, 'data': dataDecoded.toString()};
  }

  dynamic parseRequest(String trx) {
    var path = trx.substring(4);
    var requestWithHeader = decodeStringRequest(path);
    // var requestWithHeader = decodeStringRequest(trx);
    var compressedRequest = requestWithHeader.sublist(1);
    Uint8List requestBytes = Inflate(compressedRequest).getBytes();
    dynamic requestBuffer = ser.SerialBuffer(requestBytes);

    var types = ser.getTypesFromAbi(
        ser.createInitialTypes(), Abi.fromJson(json.decode(requestAbi)));

    var requestType = types['signing_request'];
    dynamic signingRequest =
        requestType.deserialize(requestType, requestBuffer);
    return signingRequest;
  }

  dynamic getReadableAction(String account, String name, String data) async {
    var contract = await getContract(account);
    var action = contract.actions[name];
    var buffer = ser.SerialBuffer(hex.decode(data));
    var result = action.deserialize(action, buffer);
    return result;
  }

  Future<Contract> getContract(String accountName) async {
    var abi = await client.getRawAbi(accountName);
    var types = ser.getTypesFromAbi(ser.createInitialTypes(), abi.abi);
    var actions = Map<String, Type>();
    for (var act in abi.abi.actions) {
      actions[act.name] = ser.getType(types, act.type);
    }
    var result = Contract(types, actions);
    return result;
  }
}
