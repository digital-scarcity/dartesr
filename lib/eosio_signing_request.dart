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

class CallbackPayload {
    /** The first signature. */
    String sig;
    /** Transaction ID as HEX-encoded string. */
    String tx;
    /** Block number hint (only present if transaction was broadcast). */
    String bn;
    /** Signer authority, aka account name. */
    String sa;
    /** Signer permission, e.g. "active". */
    String sp;
    /** Reference block num used when resolving request. */
    String rbn;
    /** Reference block id used when resolving request. */
    String rid;
    /** The originating signing request packed as a uri string. */
    String req;
    /** Expiration time used when resolving request. */
    String ex;

    /** All signatures 0-indexed as `sig0`, `sig1`, etc. */
    List<String> signatures;// [sig0: string]: string | undefined
}

class ResolvedCallback {
      /** The URL to hit. */
    String url;
    /**
     * Whether to run the request in the background. For a https url this
     * means POST in the background instead of a GET redirect.
     */
    bool background;
    /**
     * The callback payload as a object that should be encoded to JSON
     * and POSTed to background callbacks.
     */
    CallbackPayload payload;

}

class EosioSigningRequest {
  EOSClient client;
  dynamic allData; // JSON
  Action action;
  String account;
  String permission;
  String ricardian;
  String agreement;
  String callback;

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

    esr.allData = fullData;

    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    String prettyprint = encoder.convert(fullData);
    print("ESR-Full Data X: "+prettyprint);
    print("ESR callback: "+fullData['callback']);


    esr.callback = fullData['callback'] ?? '';
    esr.flags = fullData['flags'] ?? null;

    if (fullData['req'][0] == 'identity') {
      esr.action = Action()
        ..account = account
        ..name = 'identity'
        ..authorization = [
          Authorization()
            ..actor = account
            ..permission = fullData['req'][1]['permission'] ?? 'active'
        ]
        ..data = '0101000000000000000200000000000000';

      esr.callback = fullData['callback'];

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

  ResolvedCallback getCallback(List<String> signatures, num blockNum) {

    if (callback == null || callback == '') {
      return null;
    }
    
        // const {callback, flags} = this.request.data
        // if (!callback || callback.length === 0) {
        //     return null
        // }
        // if (!signatures || signatures.length === 0) {
        //     throw new Error('Must have at least one signature to resolve callback')
        // }
        // const payload: CallbackPayload = {
        //     sig: signatures[0],
        //     tx: this.getTransactionId(),
        //     rbn: String(this.transaction.ref_block_num),
        //     rid: String(this.transaction.ref_block_prefix),
        //     ex: this.transaction.expiration,
        //     req: this.request.encode(),
        //     sa: this.signer.actor,
        //     sp: this.signer.permission,
        // }
        // for (const [n, sig] of signatures.slice(1).entries()) {
        //     payload[`sig${n}`] = sig
        // }
        // if (blockNum) {
        //     payload.bn = String(blockNum)
        // }
        // const url = callback.replace(/({{([a-z0-9]+)}})/g, (_1, _2, m) => {
        //     return payload[m] || ''
        // })
        // return {
        //     background: (flags & abi.RequestFlagsBackground) !== 0,
        //     payload,
        //     url,
        // }
    }
}

