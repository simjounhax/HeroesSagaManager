import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';

void main() {
  runApp(HeroesSagaManagerApp());
}

String extractCurrentFucntionName(StackTrace stack) {
  RegExp regExp = new RegExp(r'#[0-9]+\s+(.+)\s\(.*\)');
  List<String> frames = stack.toString().split("\n");
  Iterable<RegExpMatch> matches = regExp.allMatches(frames[0]);
  RegExpMatch match = matches.elementAt(0);
  String functionName = match.group(1).toString().split(".")[1];

  return functionName;
}

class ItemData extends Object {
  String? itemId;
  String? itemClass;
  String? catalogVersion;
  String? displayName;
  String? description;
  dynamic? virtualCurrencyPrices;
  dynamic? realCurrencyPrices;
  dynamic? tags;
  dynamic? consumable;
  bool? canBecomeCharacter;
  bool? isStackable;
  bool? isTradable;
  bool? isLimitedEdition;
  bool? isSelected;
  int? initialLimitedEditionCount;
  String? issueCount;

  ItemData({
    String? itemId,
    String? itemClass,
    String? catalogVersion,
    String? displayName,
    String? description,
    dynamic? virtualCurrencyPrices,
    dynamic? realCurrencyPrices,
    dynamic? tags,
    dynamic? consumable,
    bool? canBecomeCharacter,
    bool? isStackable,
    bool? isTradable,
    bool? isLimitedEdition,
    bool? isSelected,
    int? initialLimitedEditionCount,
    String? issueCount,
  })  : this.itemId = itemId,
        this.itemClass = itemClass,
        this.catalogVersion = catalogVersion,
        this.displayName = displayName,
        this.description = description,
        this.virtualCurrencyPrices = virtualCurrencyPrices,
        this.realCurrencyPrices = realCurrencyPrices,
        this.tags = tags,
        this.consumable = consumable,
        this.canBecomeCharacter = canBecomeCharacter,
        this.isStackable = isStackable,
        this.isTradable = isTradable,
        this.isLimitedEdition = isLimitedEdition,
        this.initialLimitedEditionCount = initialLimitedEditionCount,
        this.issueCount = issueCount,
        this.isSelected = isSelected;
}

class HeroesSagaManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HeroesSagaManager(),
    );
  }
}

class HeroesSagaManager extends StatefulWidget {
  final String secretKey = "9OGQM7IRQXPQEKON4YJS5IMSBPAGC318AGCZ8T65J6U7MXMO8Y";
  final Uri endpoint = Uri.parse("https://470d0.playfabapi.com");

  Future<Map> getCatalogItems() async {
    var currentName = extractCurrentFucntionName(StackTrace.current);
    currentName = currentName[0].toUpperCase() + currentName.substring(1);

    return json.decode(utf8
        .decode((await post(Uri.parse("${endpoint.toString()}/Server/$currentName"), headers: {"X-SecretKey": secretKey, "Content-Type": "application/json; charset=utf-8"}, body: json.encode({"CatalogVersion": "Equipment"}))).bodyBytes));
  }

  Future<Map> getPlayersInSegment() async {
    var currentName = extractCurrentFucntionName(StackTrace.current);
    currentName = currentName[0].toUpperCase() + currentName.substring(1);

    return json.decode(utf8
        .decode((await post(Uri.parse("${endpoint.toString()}/Admin/$currentName"), headers: {"X-SecretKey": secretKey, "Content-Type": "application/json; charset=utf-8"}, body: json.encode({"SegmentId": "D663CFCD517F0F03"}))).bodyBytes));
  }

  Future<Map> getAllUsersCharacters(String _playfabId) async {
    var currentName = extractCurrentFucntionName(StackTrace.current);
    currentName = currentName[0].toUpperCase() + currentName.substring(1);

    return json.decode(
        utf8.decode((await post(Uri.parse("${endpoint.toString()}/Server/$currentName"), headers: {"X-SecretKey": secretKey, "Content-Type": "application/json; charset=utf-8"}, body: json.encode({"PlayFabId": "$_playfabId"}))).bodyBytes));
  }

  Future<Map> issueItemToCharacter(String _playfabId, Map _data) async {
    var currentName = extractCurrentFucntionName(StackTrace.current);
    currentName = currentName[0].toUpperCase() + currentName.substring(1);

    return json.decode(utf8.decode((await post(Uri.parse("${endpoint.toString()}/Server/ExecuteCloudScript"),
            headers: {"X-SecretKey": secretKey, "Content-Type": "application/json; charset=utf-8"},
            body: json.encode({"PlayFabId": "$_playfabId", "FunctionName": "$currentName", "GeneratePlayStreamEvent": true, "FunctionParameter": _data})))
        .bodyBytes));
  }

  @override
  _HeroesSagaManagerState createState() => _HeroesSagaManagerState();
}

class _HeroesSagaManagerState extends State<HeroesSagaManager> {
  bool isFetched = false;
  int selectedPlayerIndex = -1;
  int selectedCharIndex = -1;

  List<dynamic> _playerList = [];
  List<dynamic> _characterList = [];
  List<ItemData> _itemDataList = [];

  late Future<List<dynamic>> _userFetchFuture;
  late Future<List<dynamic>> _itemFetchFuture;

  @override
  void initState() {
    super.initState();
    _userFetchFuture = Future(() async {
      if (_playerList.length > 0) {
        return _playerList;
      }

      Map items = await widget.getPlayersInSegment();
      if (false == items.containsKey("code") || 200 != items["code"] || false == items.containsKey("status") || "OK" != items["status"]) {
        throw ArgumentError("action failed");
      }
      if (false == items.containsKey("data")) {
        throw ArgumentError("has no result data");
      }

      Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;

      _playerList = innerData["PlayerProfiles"] as List;
      return _playerList;
    });

    _itemFetchFuture = Future(() async {
      if (_itemDataList.length > 0) {
        return _itemDataList;
      }
      Map items = await widget.getCatalogItems();
      if (false == items.containsKey("code") || 200 != items["code"] || false == items.containsKey("status") || "OK" != items["status"]) {
        throw ArgumentError("action failed");
      }
      if (false == items.containsKey("data")) {
        throw ArgumentError("has no result data");
      }

      var tempItemList = <ItemData>[];
      Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;
      (innerData["Catalog"] as List).forEach((element) {
        tempItemList.add(ItemData(
          itemId: element["ItemId"],
          itemClass: element["ItemClass"],
          catalogVersion: element["CatalogVersion"],
          displayName: element["DisplayName"],
          description: element["Description"],
          virtualCurrencyPrices: element["VirtualCurrencyPrices"],
          realCurrencyPrices: element["RealCurrencyPrices"],
          tags: element["Tags"],
          consumable: element["Consumable"],
          canBecomeCharacter: element["CanBecomeCharacter"],
          isStackable: element["IsStackable"],
          isTradable: element["IsTradable"],
          isLimitedEdition: element["IsLimitedEdition"],
          initialLimitedEditionCount: element["InitialLimitedEditionCount"],
          issueCount: "1",
          isSelected: false,
        ));
      });

      _itemDataList = tempItemList;
      return tempItemList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        body: Container(
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: MediaQuery.of(context).size.height / MediaQuery.of(context).size.width + 0.25,
            children: [
              Column(
                children: [
                  Center(
                      child: Text(
                    "사용자 목록",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  )),
                  FutureBuilder(
                    future: _userFetchFuture,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (_playerList.length == 0 && snapshot.connectionState.index < ConnectionState.done.index) {
                        return Container(child: CircularProgressIndicator());
                      }

                      return Expanded(
                        child: ListView.builder(
                            itemCount: _playerList.length,
                            itemBuilder: (BuildContext context, int index) {
                              return MaterialButton(
                                onPressed: () {
                                  onSelectPlayer(index);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Icon(Icons.check, color: selectedPlayerIndex == index ? Colors.black : Colors.transparent),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          "${_playerList[index]["DisplayName"].toString()} / ${_playerList[index]["PlayerId"].toString()}",
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                      );
                    },
                  )
                ],
              ),
              Column(
                children: [
                  Center(
                      child: Text(
                    "캐릭터 목록",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  )),
                  Expanded(
                      child: ListView.builder(
                          itemCount: _characterList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return MaterialButton(
                              onPressed: () {
                                setState(() {
                                  selectedCharIndex = index;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Icon(Icons.check, color: selectedCharIndex == index ? Colors.black : Colors.transparent),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        "${_characterList[index]["CharacterName"].toString()} / ${_characterList[index]["CharacterId"].toString()}",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }))
                ],
              ),
              Column(
                children: [
                  Center(
                      child: Text(
                    "발급할 아이템 목록",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  )),
                  FutureBuilder(
                      future: _itemFetchFuture,
                      builder: (context, snapshot) {
                        if (0 == _itemDataList.length && snapshot.connectionState.index < ConnectionState.done.index) {
                          return Container(child: CircularProgressIndicator());
                        }
                        return Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: [
                                  DataColumn(
                                      label: Expanded(
                                    child: Text(
                                      "아이템\n아이디",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )),
                                  DataColumn(
                                      label: Expanded(
                                    child: Text(
                                      "아이템\n이름",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )),
                                  DataColumn(
                                      label: Expanded(
                                    child: Text(
                                      "아이템\n설명",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )),
                                  DataColumn(
                                      label: Expanded(
                                    child: Text(
                                      "누적 가능 여부",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )),
                                  DataColumn(
                                      label: Expanded(
                                    child: Text(
                                      "발급할 개수",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )),
                                ],
                                rows: List<DataRow>.generate(_itemDataList.length, (index) {
                                  return DataRow(
                                      selected: _itemDataList[index].isSelected!,
                                      onSelectChanged: (bool? isSelected) {
                                        setState(() {
                                          _itemDataList[index].isSelected = isSelected!;
                                        });
                                      },
                                      cells: <DataCell>[
                                        DataCell(Center(
                                          child: Text(
                                            "${_itemDataList[index].itemId.toString()}",
                                            textAlign: TextAlign.center,
                                          ),
                                        )),
                                        DataCell(Center(
                                          child: Text(
                                            "${_itemDataList[index].displayName.toString()}",
                                            textAlign: TextAlign.center,
                                          ),
                                        )),
                                        DataCell(Center(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Text(
                                              "${_itemDataList[index].description.toString()}",
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )),
                                        DataCell(Center(
                                          child: Text(
                                            "${_itemDataList[index].isStackable! ? "O" : "X"}",
                                            textAlign: TextAlign.center,
                                          ),
                                        )),
                                        DataCell(Center(
                                          child: TextField(
                                            keyboardType: TextInputType.number,
                                            controller: TextEditingController(text: _itemDataList[index].issueCount),
                                            onChanged: (String inputString) {
                                              setState(() {
                                                _itemDataList[index].issueCount = inputString;
                                              });
                                            },
                                          ),
                                        )),
                                      ]);
                                }),
                              ),
                            ),
                          ),
                        );
                      }),
                  Container(
                    child: Center(
                      child: MaterialButton(
                        onPressed: () async {
                          Iterable<ItemData> selectedItems = _itemDataList.where((element) => element.isSelected!);
                          var itemDataList = <Map<String, dynamic>>[];

                          if (selectedItems.isEmpty) {
                            return showDialog(
                                context: context,
                                builder: (BuildContext _dialogContext) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width / 5,
                                    child: SimpleDialog(
                                      title: Text("선택된 아이템 없음"),
                                      children: [
                                        MaterialButton(
                                          child: Text("닫기"),
                                          color: Colors.red,
                                          onPressed: () {
                                            Navigator.pop(_dialogContext);
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                });
                          }

                          if (0 > selectedPlayerIndex) {
                            return showDialog(
                                context: context,
                                builder: (BuildContext _dialogContext) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width / 5,
                                    child: SimpleDialog(
                                      title: Text("선택된 플레이어 없음"),
                                      children: [
                                        MaterialButton(
                                          child: Text("닫기"),
                                          color: Colors.red,
                                          onPressed: () {
                                            Navigator.pop(_dialogContext);
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                });
                          }
                          if (0 > selectedCharIndex) {
                            return showDialog(
                                context: context,
                                builder: (BuildContext _dialogContext) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width / 5,
                                    child: SimpleDialog(
                                      title: Text("선택된 캐릭터 없음"),
                                      children: [
                                        MaterialButton(
                                          child: Text("닫기"),
                                          color: Colors.red,
                                          onPressed: () {
                                            Navigator.pop(_dialogContext);
                                          },
                                        )
                                      ],
                                    ),
                                  );
                                });
                          }

                          selectedItems.forEach((element) {
                            itemDataList.add({"ItemId": element.itemId, "Quantity": int.parse(element.issueCount!)});
                          });
                          Map<String, dynamic> inputData = {"CharacterId": _characterList[selectedCharIndex]["CharacterId"], "ItemData": itemDataList};

                          Map result = await widget.issueItemToCharacter(_playerList[selectedPlayerIndex]["PlayerId"], inputData);

                          showDialog(
                              context: context,
                              builder: (BuildContext _dialogContext) {
                                return Container(
                                  width: MediaQuery.of(context).size.width / 5,
                                  child: SimpleDialog(
                                    title: Text("성공적으로 발급되었음"),
                                    children: [
                                      Text(
                                        result["data"]["FunctionResult"].toString(),
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      MaterialButton(
                                        child: Text("닫기"),
                                        color: Colors.green.shade400,
                                        onPressed: () {
                                          Navigator.pop(_dialogContext);
                                        },
                                      )
                                    ],
                                  ),
                                );
                              });
                        },
                        color: Colors.lightBlue,
                        child: Text("아이템\n발급"),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ));
  }

  Future<void> onSelectPlayer(int index) async {
    do {
      if (_playerList.isEmpty) break;

      String? selectedPlayerId = _playerList[index]["PlayerId"]?.toString();
      if (selectedPlayerId!.isEmpty) break;

      Map items = await widget.getAllUsersCharacters(selectedPlayerId);
      if (false == items.containsKey("code") || 200 != items["code"] || false == items.containsKey("status") || "OK" != items["status"]) {
        throw ArgumentError("action failed");
      }
      if (false == items.containsKey("data")) {
        throw ArgumentError("has no result data");
      }

      setState(() {
        selectedPlayerIndex = index;
        selectedCharIndex = -1;
        Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;
        _characterList = innerData["Characters"] as List;
      });
    } while (false);
  }
}
