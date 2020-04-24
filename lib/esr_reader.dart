import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:convert/convert.dart';
import 'package:eosdart/eosdart.dart';
import 'package:eosdart/src/eosdart_base.dart';
import 'package:eosdart/src/serialize.dart' as ser;

import './decode_string_request.dart';
import './request_abi.dart';

class EsrReader {

  EOSClient client;
  String user;
  var esrType;

  EsrReader (EOSClient client, String user) {
    this.client = client;
    this.user = user;
    var esrTypes = ser.getTypesFromAbi(ser.createInitialTypes(), Abi.fromJson(json.decode(requestAbi)));
    esrType = esrTypes['signing_request'];
  }

  Future<Action> toAction(String esrString) async {
    
    esrString = esrString.substring(4);
    var decodedEsr = decodeStringRequest(esrString);
    var esrBytes = Inflate(decodedEsr.sublist(1)).getBytes();
    dynamic esr = esrType.deserialize(esrType, ser.SerialBuffer(esrBytes));

    var action;
    if (esr['req'][1] is List) {
      action = esr['req'][1][0];
    } else {
      action = esr['req'][1];
    }

    var abi = await client.getRawAbi(action['account']);
    var types = ser.getTypesFromAbi(ser.createInitialTypes(), abi.abi);
    var actions = Map<String, Type>();
    for (var act in abi.abi.actions) {
      actions[act.name] = ser.getType(types, act.type);
    }
    var contract = Contract(types, actions);
    var actionObj = contract.actions[action['name']];
    var decodedData = actionObj.deserialize(actionObj, ser.SerialBuffer(hex.decode(action['data'])));

    return Action()
      ..account = action['account']
      ..name = action['name']
      ..authorization = [
        Authorization()
          ..actor = user
          ..permission = 'active'
      ]
      ..data = decodedData;
  }

  Future<Transaction> toTransaction (String esrString) async {
    var transaction = Transaction()
      ..actions = [
        await toAction (esrString)
      ];
    return transaction;
  }
}