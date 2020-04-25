import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:convert/convert.dart';
import 'package:eosdart/eosdart.dart';
import 'package:eosdart/src/eosdart_base.dart';
import 'package:eosdart/src/serialize.dart' as ser;
import 'package:mustache/mustache.dart';

import './decode_string_request.dart';
import './request_abi.dart';

class EosioSigningRequest {
  EOSClient client;
  Action action;
  String account;
  String permission;
  String ricardian;
  String agreement;
  // var esrType;

  EosioSigningRequest(this.client, this.account, this.permission);

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

    var action;
    if (esrMap['req'][1] is List) {
      action = esrMap['req'][1][0];
    } else {
      action = esrMap['req'][1];
    }

    var abi = await client.getRawAbi(action['account']);
    var types = ser.getTypesFromAbi(ser.createInitialTypes(), abi.abi);

    var actions = Map<String, Type>();
    for (var act in abi.abi.actions) {
      actions[act.name] = ser.getType(types, act.type);
      if (act.name == action['name']) {
        esr.ricardian = act.ricardian_contract;
      }
    }
    var contract = Contract(types, actions);
    var actionObj = contract.actions[action['name']];
    var decodedData = actionObj.deserialize(
        actionObj, ser.SerialBuffer(hex.decode(action['data'])));

    //var template = Template(esr.ricardian, lenient: true);
    // esr.agreement = template.renderString(decodedData);

    esr.action = Action()
      ..account = action['account']
      ..name = action['name']
      ..authorization = [
        Authorization()
          ..actor = account
          ..permission = 'active'
      ]
      ..data = decodedData;

    return esr;
  }

  // Future<List> toTransaction(String esrString) async {
  //   var transaction =
  //   return transaction;
  // }
}
