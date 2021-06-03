import 'package:heroes_saga_manager/Data/Data.dart';
import 'package:heroes_saga_manager/Data/Receipt.dart';
import 'package:http/http.dart';
import 'dart:convert';

String extractCurrentFucntionName(StackTrace stack) {
  RegExp regExp = new RegExp(r'#[0-9]+\s+(.+)\s\(.*\)');
  List<String> frames = stack.toString().split("\n");
  Iterable<RegExpMatch> matches = regExp.allMatches(frames[0]);
  RegExpMatch match = matches.elementAt(0);
  String functionName = match.group(1).toString().split(".")[0];

  return functionName;
}

final String secretKey = "9OGQM7IRQXPQEKON4YJS5IMSBPAGC318AGCZ8T65J6U7MXMO8Y";
final String firebase_endpoint = "https://io-15386948.firebaseio.com/";
final String playfab_endpoint = "https://470d0.playfabapi.com";

final JsonEncoder jsonEncoder = JsonEncoder.withIndent("  ");

Future<Map> getCatalogItems() async {
  var currentName = extractCurrentFucntionName(StackTrace.current);
  currentName = currentName[0].toUpperCase() + currentName.substring(1);

  return json.decode(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Server/$currentName"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: json.encode({"CatalogVersion": "Equipment"})))
      .bodyBytes));
}

Future<Map> updateUserData(String playFabId, Map data) async {
  var currentName = extractCurrentFucntionName(StackTrace.current);
  currentName = currentName[0].toUpperCase() + currentName.substring(1);

  return json.decode(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Server/$currentName"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: json.encode({"PlayFabId": playFabId, "Data": data})))
      .bodyBytes));
}

Future<Map> getETCItems() async {
  return json.decode(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Server/GetTitleData"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: json.encode({
            "Keys": ["ETCItems"]
          })))
      .bodyBytes));
}

Future<Map> getUserETCItems(String playFabId, String server) async {
  return json.decode(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Server/GetUserData"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: json.encode({
            "PlayFabId": playFabId,
            "Keys": ["${server}ETC"]
          })))
      .bodyBytes));
}

Future<Map> getPlayersInSegment() async {
  var currentName = extractCurrentFucntionName(StackTrace.current);
  currentName = currentName[0].toUpperCase() + currentName.substring(1);

  return json.decode(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Admin/$currentName"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: json.encode({"SegmentId": "D663CFCD517F0F03"})))
      .bodyBytes));
}

Future<Map> getAllUsersCharacters(String _playfabId) async {
  var currentName = extractCurrentFucntionName(StackTrace.current);
  currentName = currentName[0].toUpperCase() + currentName.substring(1);

  return json.decode(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Server/$currentName"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: json.encode({"PlayFabId": "$_playfabId"})))
      .bodyBytes));
}

Future<Map> issueItemToCharacter(String _playfabId, Map _data) async {
  var currentName = extractCurrentFucntionName(StackTrace.current);
  currentName = currentName[0].toUpperCase() + currentName.substring(1);

  return json.decode(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Server/ExecuteCloudScript"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: json.encode({
            "PlayFabId": "$_playfabId",
            "FunctionName": "$currentName",
            "GeneratePlayStreamEvent": true,
            "FunctionParameter": _data
          })))
      .bodyBytes));
}

Future<Map> drawItemFromContainer(String _playfabId, Map _data) async {
  var currentName = extractCurrentFucntionName(StackTrace.current);
  currentName = currentName[0].toUpperCase() + currentName.substring(1);

  return json.decode(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Server/ExecuteCloudScript"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: json.encode({
            "PlayFabId": "$_playfabId",
            "FunctionName": "$currentName",
            "GeneratePlayStreamEvent": true,
            "FunctionParameter": _data
          })))
      .bodyBytes));
}

Future<String> getCharacterServer(
    {required String playFabId, required String characterId}) async {
  if (playFabId.isEmpty || characterId.isEmpty) return "";

  var result = await json.decode(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Server/GetUserData"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: json.encode({
            "PlayFabId": "$playFabId",
            "Keys": ["MetaData"]
          })))
      .bodyBytes));

  if ("OK" != result["status"] || 200 != result["code"]) {
    throw "${result["errorMessage"] / result["errorDetails"]}";
  }

  List data =
      json.decode(result["data"]["Data"]["MetaData"]["Value"])["MetaData"];

  final Metadata foundMetadata = Metadata.withMap(
      data.where((metadata) => characterId == metadata["CharacterID"]).first);
  return foundMetadata.server!;
}

Future<List<Receipt>?> getReceipt({String? playerId, String? receiptId}) async {
  List<Receipt>? dataToReturn = [];

  do {
    if (playerId?.isNotEmpty ?? false) {
      String actualData = utf8.decode(
          (await get(Uri.parse("$firebase_endpoint/Receipt/$playerId.json")))
              .bodyBytes);
      if (actualData.isEmpty || "null" == actualData) break;

      Map data = json.decode(actualData) as Map;
      dataToReturn = data.values
          .map<Receipt>((item) => Receipt(
              playFabId: playerId!,
              orderId: item["OrderId"].toString(),
              itemId: item["ItemId"].toString(),
              serverName: item["ServerName"].toString(),
              price: item["Price"].toString(),
              timestamp: item["Timestamp"].toString()))
          .toList();
    } else if (receiptId?.isNotEmpty ?? false) {
      String actualData = utf8.decode(
          (await get(Uri.parse("$firebase_endpoint/Receipt.json"))).bodyBytes);
      if (actualData.isEmpty || "null" == actualData) break;

      Map data = json.decode(actualData) as Map;
      data.forEach((playerId, innerData) {
        for (var item in (innerData as Map).values) {
          if ((item["OrderId"] ?? "").toString() == receiptId) {
            dataToReturn?.add(Receipt(
                playFabId: playerId,
                orderId: item["OrderId"].toString(),
                itemId: item["ItemId"].toString(),
                serverName: item["ServerName"].toString(),
                price: item["Price"].toString(),
                timestamp: item["Timestamp"].toString()));
          }
        }
      });
    }
  } while (false);

  return dataToReturn;
}

Future writePurchaseEmail(String _playfabId, String serverName,
    String timestamp, List<PlayfabItem> itemData) async {
  return jsonEncoder.convert(utf8.decode((await post(
          Uri.parse("$playfab_endpoint/Server/ExecuteCloudScript"),
          headers: {
            "X-SecretKey": secretKey,
            "Content-Type": "application/json; charset=utf-8"
          },
          body: jsonEncoder.convert({
            "PlayFabId": "$_playfabId",
            "FunctionName": "WritePurchaseMail",
            "GeneratePlayStreamEvent": true,
            "FunctionParameter": {
              "ServerName": serverName,
              "ItemData": itemData,
              "Timestamp": timestamp
            }
          })))
      .bodyBytes));
}
