// ignore_for_file: omit_local_variable_types, todo

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:convert/convert.dart';
import 'package:eosdart/eosdart.dart';
import 'package:eosdart/src/eosdart_base.dart';
import 'package:eosdart/src/serialize.dart' as ser;

import './decode_string_request.dart';
import './request_abi.dart';
import 'request_abi.dart';

String actorPlaceholder = '............1';
String permissionPlaceholder = '............2';

class EosioSigningRequest {
  EOSClient client;
  Action action;
  String account;
  String permission;
  String ricardian;
  String agreement;

  EosioSigningRequest(this.client, this.account, this.permission);

  Future<dynamic> push() async {
    return await client.pushTransaction(Transaction()..actions = [action]);
  }

  static Future<EosioSigningRequest> factory(
      EOSClient client, String esrUri, String account,
      {permission = 'active', Abi contractAbi}) async {
    var esr = await EosioSigningRequest(client, account, permission);

    esrUri = esrUri.substring(4);

    final Uint8List decodedUri = decodeStringRequest(esrUri);

    final int header = decodedUri[0];
    List<int> bytes = decodedUri.sublist(1);

    if ((header & 1 << 7 != 0)) {
      bytes = Inflate(bytes).getBytes();
    }

    final Map<String, Type> types = ser.getTypesFromAbi(
      ser.createInitialTypes(),
      Abi.fromJson(json.decode(requestAbi)),
    );

    final Type request = types['signing_request'];

    final dynamic fullData =
        request.deserialize(request, ser.SerialBuffer(bytes));

    if (fullData['req'][0] == 'identity') {
      esr.action = Action()
        ..account = ''
        ..name = 'identity'
        ..authorization = [
          Authorization()
            ..actor = account
            ..permission = fullData['req'][1]['permission'] ?? 'active'
        ]
        ..data = '0101000000000000000200000000000000';

      return esr;
    }

    dynamic data;

    switch (fullData['req'][0]) {
      case 'action':
        data = fullData['req'][1];
        break;
      case 'action[]':
        data = fullData['req'][1][0];
        break;
      case 'transaction':
        data = fullData['req'][1].actions[0];
        break;
    }

    final action = Action()
      ..account = data['account']
      ..name = data['name']
      ..authorization = [
        Authorization()
          ..actor = data['authorization'][0]['actor'] == actorPlaceholder
              ? account
              : data['authorization'][0]['actor']
          ..permission =
              data['authorization'][0]['permission'] == permissionPlaceholder
                  ? permission
                  : data['authorization'][0]['permission']
      ]
      ..data = data['data'];

    if (contractAbi == null) {
      var abiResponse = await client.getRawAbi(action.account);
      contractAbi = abiResponse.abi;
    }

    Map<String, Type> contractTypes =
        ser.getTypesFromAbi(ser.createInitialTypes(), contractAbi);

    Map<String, Type> contractActions = {};
    for (var act in contractAbi.actions) {
      contractActions[act.name] = ser.getType(contractTypes, act.type);
    }

    esr.ricardian = contractAbi.actions
        .where((e) => e.name == action.name)
        .first
        .ricardian_contract;

    final contract = Contract(contractTypes, contractActions);

    Type actionType = contract.actions[action.name];

    dynamic actionData = actionType.deserialize(
        actionType, ser.SerialBuffer(hex.decode(action.data)));

    actionData = actionData.map((key, value) => MapEntry<String, String>(
          key,
          value == actorPlaceholder ? account : value,
        ));

    esr.action = Action()
      ..account = action.account
      ..name = action.name
      ..authorization = action.authorization
      ..data = actionData;

    return esr;
  }
}
