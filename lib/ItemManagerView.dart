import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Data.dart';
import 'Util.dart';

enum Mode { Item, Container, ETCItem }

class ItemManagerView extends StatefulWidget {
  final Mode mode;
  final selectedPlayerIndexKey = ValueKey("selectedPlayerIndexKey");
  final selectedCharIndexKey = ValueKey("selectedCharIndexKey");
  final serverKey = ValueKey("serverKey");
  final playerListKey = ValueKey("playerListKey");
  final characterListKey = ValueKey("characterListKey");
  final itemDataListKey;

  ItemManagerView({this.mode = Mode.Item, required Key key})
      : itemDataListKey = "itemDataListKey${mode.index}",
        super(key: key);

  @override
  _ItemManagerViewState createState() => _ItemManagerViewState();
}

class _ItemManagerViewState extends State<ItemManagerView> {
  int selectedPlayerIndex = -1;
  int selectedCharIndex = -1;
  late String server;

  List<dynamic> playerList = [];
  List<dynamic> characterList = [];
  List<ItemData> itemDataList = [];

  late Future<List<dynamic>> _userFetchFuture;
  late Future<List<dynamic>> _itemFetchFuture;

  @override
  void initState() {
    super.initState();

    selectedPlayerIndex = PageStorage.of(context)!.readState(context, identifier: widget.selectedPlayerIndexKey) ?? -1;
    selectedCharIndex = PageStorage.of(context)!.readState(context, identifier: widget.selectedCharIndexKey) ?? -1;
    server = PageStorage.of(context)!.readState(context, identifier: widget.serverKey) ?? "";
    playerList = PageStorage.of(context)!.readState(context, identifier: widget.playerListKey) ?? [];
    characterList = PageStorage.of(context)!.readState(context, identifier: widget.characterListKey) ?? [];
    itemDataList = PageStorage.of(context)!.readState(context, identifier: widget.itemDataListKey) ?? [];

    // 유저 가져오는 Future 초기화
    _userFetchFuture = Future(() async {
      if (playerList.length > 0) {
        return playerList;
      }

      Map items = await getPlayersInSegment();
      if (200 != items["code"] || "OK" != items["status"]) {
        showErrorDialog(context, errorMessage: "${items["errorMessage"]}/${items["errorDetails"]}");
      }
      if (false == items.containsKey("data")) {
        showErrorDialog(context, errorMessage: "has no result data");
      }

      Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;

      playerList = innerData["PlayerProfiles"] as List;
      PageStorage.of(context)!.writeState(context, playerList, identifier: widget.playerListKey);
      return playerList;
    });

    switch (widget.mode) {
      case Mode.ETCItem:
        _itemFetchFuture = futureETCItemInitialize();
        break;
      case Mode.Item:
      case Mode.Container:
      default:
        _itemFetchFuture = futureCatalogItemInitialize(isContainer: Mode.Container == widget.mode);
        break;
    }
    // 일반 아이템 가져오는 Future 초기화
  }

  Future<List<dynamic>> futureETCItemInitialize() {
    return Future(() async {
      if (itemDataList.length > 0) {
        return itemDataList;
      }

      var data = (await getETCItems())["data"]["Data"];
      if (false == (data as Map).containsKey("ETCItems")) {
        showErrorDialog(context, errorMessage: "올바르지 않은 데이터 경로임");
      }

      var items = json.decode(data["ETCItems"]);

      itemDataList = items.map<ItemData>((itemName) => ItemData(itemId: itemName)).toList();
      PageStorage.of(context)!.writeState(context, itemDataList, identifier: widget.itemDataListKey);

      return [];
    });
  }

  Future<List<dynamic>> futureCatalogItemInitialize({bool isContainer = false}) {
    return Future(() async {
      if (itemDataList.length > 0) {
        return itemDataList;
      }

      Map items = await getCatalogItems();
      if (false == items.containsKey("code") || 200 != items["code"] || false == items.containsKey("status") || "OK" != items["status"]) {
        showErrorDialog(context, errorMessage: "${items["errorMessage"]}/${items["errorDetails"]}");
      }
      if (false == items.containsKey("data")) {
        showErrorDialog(context, errorMessage: "has no result data");
      }

      var tempItemList = <ItemData>[];
      Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;
      (innerData["Catalog"] as List).where((item) => isContainer ? (item as Map).containsKey("Container") : false == (item as Map).containsKey("Container")).forEach((element) {
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
          container: element["Container"],
          canBecomeCharacter: element["CanBecomeCharacter"],
          isStackable: element["IsStackable"],
          isTradable: element["IsTradable"],
          isLimitedEdition: element["IsLimitedEdition"],
          initialLimitedEditionCount: element["InitialLimitedEditionCount"],
        ));
      });

      itemDataList = tempItemList;
      PageStorage.of(context)!.writeState(context, itemDataList, identifier: widget.itemDataListKey);
      return tempItemList;
    });
  }

  FutureBuilder getItemFutureBuilder() {
    return FutureBuilder(
        future: _itemFetchFuture,
        builder: (context, snapshot) {
          if (0 == itemDataList.length && snapshot.connectionState.index < ConnectionState.done.index) {
            return Container(child: CircularProgressIndicator());
          }
          return Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(0),
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 28.0,
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
                        "발급할 개수",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )),
                  ],
                  rows: List<DataRow>.generate(itemDataList.length, (index) {
                      TextEditingController controller = TextEditingController(text: itemDataList[index].issueCount);
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                    return DataRow(
                        selected: itemDataList[index].isSelected,
                        onSelectChanged: (bool? isSelected) {
                          setState(() {
                            itemDataList[index].isSelected = isSelected!;
                          });
                        },
                        cells: <DataCell>[
                          DataCell(Center(
                            child: Text(
                              "${itemDataList[index].itemId.toString()}",
                              textAlign: TextAlign.center,
                            ),
                          )),
                          DataCell(Center(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              controller: controller,
                              textAlign: TextAlign.center,
                              onChanged: (String inputString) {
                                setState(() {
                                  itemDataList[index].issueCount = inputString;
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
        });
  }

  FutureBuilder getContainerFutureBuilder() {
    return FutureBuilder(
        future: _itemFetchFuture,
        builder: (context, snapshot) {
          if (0 == itemDataList.length && snapshot.connectionState.index < ConnectionState.done.index) {
            return Container(child: CircularProgressIndicator());
          }
          return Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(0),
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 28.0,
                  dataRowHeight: 500.0,
                  columns: [
                    DataColumn(
                        label: Expanded(
                      child: Text(
                        "컨테이너\n아이디",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )),
                    DataColumn(
                        label: Expanded(
                      child: Text(
                        "컨테이너\n설명",
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
                  rows: List<DataRow>.generate(itemDataList.length, (index) {
                      TextEditingController controller = TextEditingController(text: itemDataList[index].issueCount);
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                    return DataRow(
                        selected: itemDataList[index].isSelected,
                        onSelectChanged: (bool? isSelected) {
                          if (isSelected! && false == itemDataList.every((item) => false == item.isSelected)) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("오직 하나만 선택할 수 있습니다"),
                              duration: Duration(seconds: 1),
                            ));
                          } else {
                            setState(() {
                              itemDataList[index].isSelected = isSelected;
                            });
                          }
                        },
                        cells: <DataCell>[
                          DataCell(Center(
                            child: Text(
                              "${itemDataList[index].itemId.toString()}",
                              textAlign: TextAlign.center,
                            ),
                          )),
                          DataCell(Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Text(
                                "${indentEncoder.convert((itemDataList[index].container as Map)["ItemContents"])}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )),
                          DataCell(Center(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              controller: controller,
                              textAlign: TextAlign.center,
                              onChanged: (String inputString) {
                                setState(() {
                                  itemDataList[index].issueCount = inputString;
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
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        body: Container(
            child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Center(
                      child: Text(
                    "사용자 목록",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  )),
                  FutureBuilder(
                    future: _userFetchFuture,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (playerList.length == 0 && snapshot.connectionState.index < ConnectionState.done.index) {
                        return Container(child: CircularProgressIndicator());
                      }

                      return Expanded(
                        child: ListView.builder(
                            itemCount: playerList.length,
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
                                          "${playerList[index]["DisplayName"].toString()} / ${playerList[index]["PlayerId"].toString()}",
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
            ),
            Expanded(
              child: Column(
                children: [
                  Center(
                      child: Text(
                    "캐릭터 목록",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  )),
                  Expanded(
                      child: ListView.builder(
                          itemCount: characterList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return MaterialButton(
                              onPressed: () async {
                                // if (Mode.Container == widget.mode) {
                                showWaitingDialog(context, message: "캐릭터 선택 중...");
                                server = (await getCharacterServer(playFabId: playerList[selectedPlayerIndex]["PlayerId"], characterId: characterList[index]["CharacterId"]));
                                PageStorage.of(context)!.writeState(context, server, identifier: widget.serverKey);
                                Navigator.of(context).pop();
                                // }
                                setState(() {
                                  selectedCharIndex = index;
                                  PageStorage.of(context)!.writeState(context, selectedCharIndex, identifier: widget.selectedCharIndexKey);
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
                                        "${characterList[index]["CharacterName"].toString()} / ${characterList[index]["CharacterId"].toString()}",
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
            ),
            Expanded(
              child: Column(
                children: [
                  Center(
                      child: Text(
                    "발급할 아이템 목록",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  )),
                  (() {
                    switch (widget.mode) {
                      case Mode.Container:
                        return getContainerFutureBuilder();
                      case Mode.Item:
                      case Mode.ETCItem:
                      default:
                        return getItemFutureBuilder();
                    }
                  })(),
                  Container(
                    child: Center(
                      child: MaterialButton(
                        onPressed: () async {
                          Iterable<ItemData> selectedItems = itemDataList.where((element) => element.isSelected);
                          var _itemDataList = <Map<String, dynamic>>[];

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

                          showWaitingDialog(context);
                          Map? result;

                          switch (widget.mode) {
                            case Mode.Container:
                              ItemData selectedContainer = selectedItems.first;
                              Map<String, dynamic> inputData = {"ContainerItemId": selectedContainer.itemId, "CharacterId": characterList[selectedCharIndex]["CharacterId"], "ServerName": server, "Quantity": selectedContainer.issueCount};

                              result = await drawItemFromContainer(playerList[selectedPlayerIndex]["PlayerId"], inputData);
                              break;
                            case Mode.ETCItem:
                              if (server.isEmpty) {
                                showErrorDialog(context, errorMessage: "서버가 올바르지 않습니다. 캐릭터를 선택했는지 확인해주세요.");
                              }
                              var data = (await getUserETCItems(playerList[selectedPlayerIndex]["PlayerId"], server))["data"]["Data"];
                              var etcData = {};
                              var etcTableName = "${server}ETC";
                              if ((data as Map).containsKey(etcTableName)) {
                                etcData = json.decode(data[etcTableName]["Value"]);
                              }

                              selectedItems.forEach((element) {
                                etcData["${element.itemId}"] = (etcData["${element.itemId}"] ?? 0) + int.parse(element.issueCount);
                              });

                              print(await updateUserData(playerList[selectedPlayerIndex]["PlayerId"], {etcTableName: json.encode(etcData)}));

                              result = {
                                "data": {
                                  "FunctionResult": {"Items": selectedItems.map((e) => e.toString()).toList()}
                                }
                              };
                              break;
                            case Mode.Item:
                            default:
                              selectedItems.forEach((element) {
                                _itemDataList.add({"ItemId": element.itemId, "Quantity": int.parse(element.issueCount)});
                              });
                              Map<String, dynamic> inputData = {"CharacterId": characterList[selectedCharIndex]["CharacterId"], "ItemData": _itemDataList};

                              result = await issueItemToCharacter(playerList[selectedPlayerIndex]["PlayerId"], inputData);
                              break;
                          }

                          Navigator.of(context).pop();

                          bool error = (result["data"]["FunctionResult"] as Map).containsKey("ErrorMessage");
                          String errorMessage = result["data"]["FunctionResult"]["ErrorMessage"] ?? "";

                          showDialog(
                              context: context,
                              builder: (BuildContext _dialogContext) {
                                return Container(
                                  width: MediaQuery.of(context).size.width / 5,
                                  child: SimpleDialog(
                                    title: Text(
                                      error ? errorMessage : "성공적으로 발급되었음",
                                      textAlign: TextAlign.center,
                                    ),
                                    children: [
                                      Text(
                                        result!["data"]["FunctionResult"] is String ? result["data"]["FunctionResult"] : json.encode(result["data"]["FunctionResult"]),
                                        textAlign: TextAlign.center,
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      MaterialButton(
                                        child: Text("닫기"),
                                        color: error ? Colors.red.shade400 : Colors.green.shade400,
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
              ),
            )
          ],
        )));
  }

  void showWaitingDialog(BuildContext _context, {String message = "발급 중입니다..."}) {
    showDialog(
        context: _context,
        builder: (dlgContext) {
          return AlertDialog(
              actions: [
                MaterialButton(
                  color: Colors.lightBlue.shade100,
                  onPressed: () {
                    Navigator.of(dlgContext).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.close,
                          color: Colors.red.shade300,
                        ),
                        Text("취소")
                      ],
                    ),
                  ),
                ),
              ],
              content: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 32),
                      child: CircularProgressIndicator(),
                    ),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ));
        });
  }

  void showErrorDialog(BuildContext _context, {required String errorMessage}) {
    showDialog(
        context: _context,
        builder: (dlgContext) {
          return AlertDialog(
            content: Text(errorMessage),
            actions: [
              MaterialButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                    Text("확인"),
                  ],
                ),
              )
            ],
          );
        });
  }

  Future<void> onSelectPlayer(int index) async {
    do {
      if (playerList.isEmpty) break;

      String? selectedPlayerId = playerList[index]["PlayerId"]?.toString();
      if (selectedPlayerId!.isEmpty) break;

      showWaitingDialog(context, message: "캐릭터 조회 중...");

      Map items = await getAllUsersCharacters(selectedPlayerId);
      Navigator.of(context).pop();
      if (false == items.containsKey("code") || 200 != items["code"] || false == items.containsKey("status") || "OK" != items["status"]) {
        showErrorDialog(context, errorMessage: "${items["errorMessage"]}/${items["errorDetails"]}");
      }
      if (false == items.containsKey("data")) {
        showErrorDialog(context, errorMessage: "has no result data");
      }

      setState(() {
        selectedPlayerIndex = index;
        PageStorage.of(context)!.writeState(context, selectedPlayerIndex, identifier: widget.selectedPlayerIndexKey);
        selectedCharIndex = -1;
        PageStorage.of(context)!.writeState(context, selectedCharIndex, identifier: widget.selectedCharIndexKey);
        Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;
        characterList = innerData["Characters"] as List;
        PageStorage.of(context)!.writeState(context, characterList, identifier: widget.characterListKey);
      });
    } while (false);
  }
}
