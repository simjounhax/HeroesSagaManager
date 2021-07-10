import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Data/Data.dart';
import '../Util.dart';

enum Mode { Item, Container, ETCItem }

class ItemManager extends StatefulWidget {
  final List _views = [
    ItemManagerView(
      mode: Mode.Item,
      key: PageStorageKey("ItemManager"),
    ),
    ItemManagerView(
      mode: Mode.Container,
      key: PageStorageKey("ContainerManager"),
    ),
    ItemManagerView(
      mode: Mode.ETCItem,
      key: PageStorageKey("ETCItemManager"),
    )
  ];
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  _ItemManagerState createState() => _ItemManagerState();
}

class _ItemManagerState extends State<ItemManager> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: widget._bucket,
        child: widget._views[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "아이템 발급"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "컨테이너 발급"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "기타 아이템 발급"),
        ],
        onTap: (int newTapSelected) {
          setState(() {
            _currentIndex = newTapSelected;
          });
        },
        currentIndex: _currentIndex,
      ),
    );
  }
}

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
  String selectedPlayerString = "";
  String selectedCharString = "";
  String searchStringForId = "";
  String searchStringForName = "";
  int selectedPlayerIndex = -1;
  int selectedCharIndex = -1;
  late String server;

  bool bEnableForIdSearcher = true;
  bool bEnableForNameSearcher = true;

  List playerList = [];
  List characterList = [];
  List<PlayfabItem> itemDataList = [];
  List filteredPlayerList = [];

  late Future<List> _userFetchFuture;
  late Future<List> _itemFetchFuture;

  @override
  void initState() {
    super.initState();

    selectedPlayerIndex = PageStorage.of(context)!
            .readState(context, identifier: widget.selectedPlayerIndexKey) ??
        -1;
    selectedCharIndex = PageStorage.of(context)!
            .readState(context, identifier: widget.selectedCharIndexKey) ??
        -1;
    server = PageStorage.of(context)!
            .readState(context, identifier: widget.serverKey) ??
        "";
    playerList = PageStorage.of(context)!
            .readState(context, identifier: widget.playerListKey) ??
        [];
    characterList = PageStorage.of(context)!
            .readState(context, identifier: widget.characterListKey) ??
        [];
    itemDataList = PageStorage.of(context)!
            .readState(context, identifier: widget.itemDataListKey) ??
        [];

    // 유저 가져오는 Future 초기화
    _userFetchFuture = Future(() async {
      if (playerList.length > 0) {
        return playerList;
      }

      Map items = await getPlayersInSegment();
      if (200 != items["code"] || "OK" != items["status"]) {
        showErrorDialog(context,
            errorMessage: "${items["errorMessage"]}/${items["errorDetails"]}");
      }
      if (false == items.containsKey("data")) {
        showErrorDialog(context, errorMessage: "has no result data");
      }

      Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;
      PageStorage.of(context)!.writeState(context, innerData["PlayerProfiles"],
          identifier: widget.playerListKey);
      return innerData["PlayerProfiles"] as List;
    });

    switch (widget.mode) {
      case Mode.ETCItem:
        _itemFetchFuture = futureETCItemInitialize();
        break;
      case Mode.Item:
      case Mode.Container:
      default:
        _itemFetchFuture = futureCatalogItemInitialize(
            isContainer: Mode.Container == widget.mode);
        break;
    }
    // 일반 아이템 가져오는 Future 초기화
  }

  Future<List> futureETCItemInitialize() {
    return Future(() async {
      if (itemDataList.length > 0) {
        return itemDataList;
      }

      var data = (await getETCItems())["data"]["Data"];
      if (false == (data as Map).containsKey("ETCItems")) {
        showErrorDialog(context, errorMessage: "올바르지 않은 데이터 경로임");
      }

      var items = json.decode(data["ETCItems"]);

      itemDataList = items
          .map<PlayfabItem>((itemName) => PlayfabItem(itemId: itemName))
          .toList();
      PageStorage.of(context)!.writeState(context, itemDataList,
          identifier: widget.itemDataListKey);

      return [];
    });
  }

  Future<List> futureCatalogItemInitialize({bool isContainer = false}) {
    return Future(() async {
      if (itemDataList.length > 0) {
        return itemDataList;
      }

      Map items = await getCatalogItems();
      if (false == items.containsKey("code") ||
          200 != items["code"] ||
          false == items.containsKey("status") ||
          "OK" != items["status"]) {
        showErrorDialog(context,
            errorMessage: "${items["errorMessage"]}/${items["errorDetails"]}");
      }
      if (false == items.containsKey("data")) {
        showErrorDialog(context, errorMessage: "has no result data");
      }

      var tempItemList = <PlayfabItem>[];
      Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;
      (innerData["Catalog"] as List)
          .where((item) => isContainer
              ? (item as Map).containsKey("Container")
              : false == (item as Map).containsKey("Container"))
          .forEach((element) {
        tempItemList.add(PlayfabItem(
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
      PageStorage.of(context)!.writeState(context, itemDataList,
          identifier: widget.itemDataListKey);
      return tempItemList;
    });
  }

  FutureBuilder getItemFutureBuilder() {
    return FutureBuilder(
        future: _itemFetchFuture,
        builder: (context, snapshot) {
          if (0 == itemDataList.length &&
              snapshot.connectionState.index < ConnectionState.done.index) {
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
                    TextEditingController controller = TextEditingController(
                        text: itemDataList[index].issueCount);
                    controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length));
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
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
          if (0 == itemDataList.length &&
              snapshot.connectionState.index < ConnectionState.done.index) {
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
                    TextEditingController controller = TextEditingController(
                        text: itemDataList[index].issueCount);
                    controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length));
                    return DataRow(
                        selected: itemDataList[index].isSelected,
                        onSelectChanged: (bool? isSelected) {
                          if (isSelected! &&
                              false ==
                                  itemDataList.every(
                                      (item) => false == item.isSelected)) {
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
                                "${jsonEncoder.convert((itemDataList[index].container as Map)["ItemContents"])}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )),
                          DataCell(Center(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
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
        body: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Center(
                      child: Text(
                    "사용자 목록",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  )),
                  Container(
                    child: TextField(
                      enabled: bEnableForIdSearcher,
                      decoration: InputDecoration(hintText: "아이디 검색"),
                      textAlign: TextAlign.center,
                      onChanged: (String filterString) {
                        setState(() {
                          bEnableForNameSearcher = filterString.isEmpty;
                          this.searchStringForId = filterString;
                        });
                      },
                    ),
                  ),
                  Container(
                    child: TextField(
                      enabled: bEnableForNameSearcher,
                      decoration: InputDecoration(hintText: "이름 검색"),
                      textAlign: TextAlign.center,
                      onChanged: (String filterString) {
                        setState(() {
                          bEnableForIdSearcher = filterString.isEmpty;
                          this.searchStringForName = filterString;
                        });
                      },
                    ),
                  ),
                  FutureBuilder(
                    future: _userFetchFuture,
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (playerList.length == 0 &&
                          snapshot.connectionState.index <
                              ConnectionState.done.index) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // 플레이어 데이터 넣고
                      playerList = snapshot.data as List;

                      if (playerList.isNotEmpty) {
                        if (bEnableForIdSearcher) {
                          if (searchStringForId.isEmpty) {
                            filteredPlayerList = playerList;
                          } else {
                            filteredPlayerList = playerList
                                .where((data) => (data["PlayerId"] as String)
                                    .startsWith(searchStringForId))
                                .toList();
                          }
                        }
                        if (bEnableForNameSearcher) {
                          if (searchStringForName.isEmpty) {
                            filteredPlayerList = playerList;
                          } else {
                            filteredPlayerList = playerList
                                .where((data) => (data["DisplayName"] ?? "")
                                    .startsWith(searchStringForName))
                                .toList();
                          }
                        }
                      }

                      return Expanded(
                        child: ListView.builder(
                            controller: ScrollController(),
                            itemCount: filteredPlayerList.length,
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Icon(Icons.check,
                                            color: filteredPlayerList[index]
                                                        ["PlayerId"] ==
                                                    selectedPlayerString
                                                ? Colors.black
                                                : Colors.transparent),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          "${filteredPlayerList[index]["DisplayName"].toString()} / ${filteredPlayerList[index]["PlayerId"].toString()}",
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
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  )),
                  Expanded(
                      child: ListView.builder(
                          controller: ScrollController(),
                          itemCount: characterList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return MaterialButton(
                              onPressed: () async {
                                // if (Mode.Container == widget.mode) {
                                showWaitingDialog(context,
                                    message: "캐릭터 선택 중...");
                                server = (await getCharacterServer(
                                    playFabId: playerList[selectedPlayerIndex]
                                        ["PlayerId"],
                                    characterId: characterList[index]
                                        ["CharacterId"]));
                                PageStorage.of(context)!.writeState(
                                    context, server,
                                    identifier: widget.serverKey);
                                Navigator.of(context).pop();
                                // }
                                setState(() {
                                  selectedCharIndex = index;
                                  PageStorage.of(context)!.writeState(
                                      context, selectedCharIndex,
                                      identifier: widget.selectedCharIndexKey);
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Icon(Icons.check,
                                          color: selectedCharIndex == index
                                              ? Colors.black
                                              : Colors.transparent),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
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
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
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
                          Iterable<PlayfabItem> selectedItems = itemDataList
                              .where((element) => element.isSelected);
                          var _itemDataList = <Map<String, dynamic>>[];

                          if (selectedItems.isEmpty) {
                            return showDialog(
                                context: context,
                                builder: (BuildContext _dialogContext) {
                                  return Container(
                                    width:
                                        MediaQuery.of(context).size.width / 5,
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
                                    width:
                                        MediaQuery.of(context).size.width / 5,
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
                                    width:
                                        MediaQuery.of(context).size.width / 5,
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
                              PlayfabItem selectedContainer =
                                  selectedItems.first;
                              Map<String, dynamic> inputData = {
                                "ContainerItemId": selectedContainer.itemId,
                                "CharacterId": characterList[selectedCharIndex]
                                    ["CharacterId"],
                                "ServerName": server,
                                "Quantity": selectedContainer.issueCount
                              };

                              result = await drawItemFromContainer(
                                  playerList[selectedPlayerIndex]["PlayerId"],
                                  inputData);
                              break;
                            case Mode.ETCItem:
                              if (server.isEmpty) {
                                showErrorDialog(context,
                                    errorMessage:
                                        "서버가 올바르지 않습니다. 캐릭터를 선택했는지 확인해주세요.");
                              }
                              var data = (await getUserETCItems(
                                  playerList[selectedPlayerIndex]["PlayerId"],
                                  server))["data"]["Data"];
                              var etcData = {};
                              var etcTableName = "${server}ETC";
                              if ((data as Map).containsKey(etcTableName)) {
                                etcData =
                                    json.decode(data[etcTableName]["Value"]);
                              }

                              selectedItems.forEach((element) {
                                etcData["${element.itemId}"] =
                                    (etcData["${element.itemId}"] ?? 0) +
                                        int.parse(element.issueCount);
                              });

                              print(await updateUserData(
                                  playerList[selectedPlayerIndex]["PlayerId"],
                                  {etcTableName: json.encode(etcData)}));

                              result = {
                                "data": {
                                  "FunctionResult": {
                                    "Items": selectedItems
                                        .map((e) => e.toString())
                                        .toList()
                                  }
                                }
                              };
                              break;
                            case Mode.Item:
                            default:
                              selectedItems.forEach((element) {
                                _itemDataList.add({
                                  "ItemId": element.itemId,
                                  "Quantity": int.parse(element.issueCount)
                                });
                              });
                              Map<String, dynamic> inputData = {
                                "CharacterId": characterList[selectedCharIndex]
                                    ["CharacterId"],
                                "ItemData": _itemDataList
                              };

                              result = await issueItemToCharacter(
                                  playerList[selectedPlayerIndex]["PlayerId"],
                                  inputData);
                              break;
                          }

                          Navigator.of(context).pop();

                          bool error = (result["data"]["FunctionResult"] as Map)
                              .containsKey("ErrorMessage");
                          String errorMessage = result["data"]["FunctionResult"]
                                  ["ErrorMessage"] ??
                              "";

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
                                        result!["data"]["FunctionResult"]
                                                is String
                                            ? result["data"]["FunctionResult"]
                                            : json.encode(result["data"]
                                                ["FunctionResult"]),
                                        textAlign: TextAlign.center,
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      MaterialButton(
                                        child: Text("닫기"),
                                        color: error
                                            ? Colors.red.shade400
                                            : Colors.green.shade400,
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
        ));
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
      if (filteredPlayerList.isEmpty) break;

      String? selectedPlayerId = filteredPlayerList[index]["PlayerId"]?.toString();
      if (selectedPlayerId!.isEmpty) break;

      showWaitingDialog(context, message: "캐릭터 조회 중...");

      Map items = await getAllUsersCharacters(selectedPlayerId);
      Navigator.of(context).pop();
      if (false == items.containsKey("code") ||
          200 != items["code"] ||
          false == items.containsKey("status") ||
          "OK" != items["status"]) {
        showErrorDialog(context,
            errorMessage: "${items["errorMessage"]}/${items["errorDetails"]}");
      }
      if (false == items.containsKey("data")) {
        showErrorDialog(context, errorMessage: "has no result data");
      }

      setState(() {
        selectedPlayerString = selectedPlayerId;
        selectedPlayerIndex = index;
        PageStorage.of(context)!.writeState(context, selectedPlayerIndex,
            identifier: widget.selectedPlayerIndexKey);
        selectedCharIndex = -1;
        PageStorage.of(context)!.writeState(context, selectedCharIndex,
            identifier: widget.selectedCharIndexKey);
        Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;
        characterList = innerData["Characters"] as List;
        PageStorage.of(context)!.writeState(context, characterList,
            identifier: widget.characterListKey);
      });
    } while (false);
  }
}
