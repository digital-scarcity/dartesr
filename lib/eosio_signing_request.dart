import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:convert/convert.dart';
import 'package:eosdart/eosdart.dart';
import 'package:eosdart/src/eosdart_base.dart';
import 'package:eosdart/src/serialize.dart' as ser;

import './decode_string_request.dart';
import './request_abi.dart';

class EosioSigningRequest {
  EOSClient client;
  Action action;
  String account;
  String permission;
  String ricardian;
  String agreement;

  EosioSigningRequest(this.client, this.account, this.permission);

  Map<String, dynamic> fillDataPlaceholders(
      Map<String, dynamic> request, String accountName) {
    Map<String, dynamic> result = {};

    request.forEach((key, value) {
      if (value == '............1') {
        result[key] = accountName;
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  Future<dynamic> push() async {
    return await client.pushTransaction(Transaction()..actions = [action]);
  }

  static Future<EosioSigningRequest> factory(
      EOSClient client, String esrUri, String account,
      {permission = 'active'}) async {
    var esr = await EosioSigningRequest(client, account, permission);

    esrUri = esrUri.substring(4);
    var decodedEsr = decodeStringRequest(esrUri);
    var esrBytes = Inflate(decodedEsr.sublist(1)).getBytes();
    var esrTypes = ser.getTypesFromAbi(
        ser.createInitialTypes(), Abi.fromJson(json.decode(requestAbi)));
    var esrType = esrTypes['signing_request'];

    dynamic esrMap = esrType.deserialize(esrType, ser.SerialBuffer(esrBytes));

    var actionMap;
    if (esrMap['req'][1] is List) {
      actionMap = esrMap['req'][1][0];
    } else {
      actionMap = esrMap['req'][1];
    }

    var abi = await client.getRawAbi(actionMap['account']);
    var types = ser.getTypesFromAbi(ser.createInitialTypes(), abi.abi);

    var actions = Map<String, Type>();
    for (var act in abi.abi.actions) {
      actions[act.name] = ser.getType(types, act.type);
      if (act.name == actionMap['name']) {
        esr.ricardian = act.ricardian_contract;
      }
    }
    var contract = Contract(types, actions);
    var actionObj = contract.actions[actionMap['name']];
    var decodedData = actionObj.deserialize(
        actionObj, ser.SerialBuffer(hex.decode(actionMap['data'])));

    decodedData.forEach((key, value) {
      if (value == '............1') {
        decodedData[key] = account;
      } else {
        decodedData[key] = value;
      }
    });

    esr.action = Action()
      ..account = actionMap['account']
      ..name = actionMap['name']
      ..authorization = [Authorization()];

    if (actionMap['authorization'][0]['actor'] == '............1') {
      esr.action.authorization[0].actor = account;
    }

    if (actionMap['authorization'][0]['permission'] == '............2') {
      esr.action.authorization[0].permission = permission;
    }

    esr.action.data = decodedData;
    return esr;
  }
}
