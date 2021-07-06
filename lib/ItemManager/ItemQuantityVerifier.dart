import 'package:flutter/material.dart';
import 'package:heroes_saga_manager/Data/Data.dart';
import 'package:heroes_saga_manager/Util.dart';

class CharacterSelectPage extends StatefulWidget {
  CharacterSelectPage({Key? key}) : super(key: key);

  final selectedPlayerIndexKey = ValueKey("selectedPlayerIndexKey");
  final selectedCharIndexKey = ValueKey("selectedCharIndexKey");
  final serverKey = ValueKey("serverKey");
  final playerListKey = ValueKey("playerListKey");
  final characterListKey = ValueKey("characterListKey");

  @override
  _CharacterSelectPageState createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  String selectedPlayerString = "";
  String selectedCharString = "";
  int selectedPlayerIndex = -1;
  int selectedCharIndex = -1;

  List<dynamic> playerList = [];
  List<dynamic> characterList = [];
  List<PlayfabItem> itemDataList = [];

  List filteredPlayerList = [];

  late Future<dynamic> _getUserFuture;

  late String server;
  String searchStringForId = "";
  String searchStringForName = "";
  bool bEnableForIdSearcher = true;
  bool bEnableForNameSearcher = true;

  int numberOfItemToShow = 0;

  @override
  void initState() {
    super.initState();

    _getUserFuture = getPlayerList();
  }

  Future getPlayerList() {
    return Future(() async {
      if (playerList.length > 0) {
        return playerList;
      }

      Map items = await getPlayersInSegment();
      if (200 != items["code"] || "OK" != items["status"]) {
        showErrorDialog(
            context, "${items["errorMessage"]}/${items["errorDetails"]}");
      }
      if (false == items.containsKey("data")) {
        showErrorDialog(context, "has no result data");
      }

      Map<String, dynamic> innerData = items["data"] as Map<String, dynamic>;

      return innerData["PlayerProfiles"] as List;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Builder(builder: (context) {
      return Row(
        children: [
          // 플레이어 목록
          Expanded(
            child: FutureBuilder(
                future: _getUserFuture,
                builder: (context, snapshot) {
                  Widget widgetToShow = Container();
                  // 에러 있으면
                  if (snapshot.hasError) {
                    showErrorDialog(context, snapshot.error.toString());
                  }
                  // 아직 로딩 중이면
                  else if (ConnectionState.done.index >
                      snapshot.connectionState.index) {
                    widgetToShow = Center(child: CircularProgressIndicator());
                  }
                  // 로딩 다 끝났으면
                  else {
                    // 플레이어 데이터 넣고
                    playerList = snapshot.data as List<dynamic>;

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

                    widgetToShow = Column(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
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
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
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
                        ),
                        Expanded(
                          flex: 9,
                          child: ListView.builder(
                              itemCount: filteredPlayerList.length,
                              itemBuilder: (BuildContext context, int index) {
                                return MaterialButton(
                                  onPressed: () {
                                    onSelectPlayer(
                                        filteredPlayerList[index]["PlayerId"],
                                        index);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                        ),
                      ],
                    );
                  }

                  return widgetToShow;
                }),
          ),
          // 캐릭터 목록
          Expanded(
            child: Container(
              child: ListView.builder(
                  itemCount: characterList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return MaterialButton(
                      onPressed: () async {
                        showWaitingDialog(context, message: "캐릭터 선택 중...");
                        server = (await getCharacterServer(
                            playFabId: filteredPlayerList[selectedPlayerIndex]
                                ["PlayerId"],
                            characterId: characterList[index]["CharacterId"]));
                        PageStorage.of(context)!.writeState(context, server,
                            identifier: widget.serverKey);
                        Navigator.of(context).pop();
                        setState(() {
                          selectedCharIndex = index;
                          PageStorage.of(context)!.writeState(
                              context, selectedCharIndex,
                              identifier: widget.selectedCharIndexKey);
                        });

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    WeaponQuantityVerifier(playerId: selectedPlayerString, characterId: characterList[index]["CharacterId"], serverName: server,)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.check,
                                  color: selectedCharIndex == index
                                      ? Colors.black
                                      : Colors.transparent),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                "${characterList[index]["CharacterName"].toString()} / ${characterList[index]["CharacterId"].toString()}",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          )
        ],
      );
    }));
  }

  Future<void> onSelectPlayer(String selectedPlayerId, int index) async {
    do {
      if (selectedPlayerId.isEmpty) break;

      showWaitingDialog(context, message: "캐릭터 조회 중...");

      Map items = await getAllUsersCharacters(selectedPlayerId);
      Navigator.of(context).pop();
      if (false == items.containsKey("code") ||
          200 != items["code"] ||
          false == items.containsKey("status") ||
          "OK" != items["status"]) {
        showErrorDialog(
            context, "${items["errorMessage"]}/${items["errorDetails"]}");
      }
      if (false == items.containsKey("data")) {
        showErrorDialog(context, "has no result data");
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

class WeaponQuantityVerifier extends StatefulWidget {
  WeaponQuantityVerifier({Key? key, this.playerId, this.characterId, this.serverName}) : super(key: key);

  final playerId;
  final characterId;
  final serverName;

  @override
  _WeaponQuantityVerifierState createState() => _WeaponQuantityVerifierState();
}

class _WeaponQuantityVerifierState extends State<WeaponQuantityVerifier> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme.copyWith(color: Colors.white),
        foregroundColor: Colors.white,
        shadowColor: Colors.white,
      ),
      body: Builder(
        builder: (context) {
          return Center(
            child: FutureBuilder(
              future: Future(() async {
                var result = await getUserData(widget.playerId, keys: ["${widget.serverName}WeaponList"]);
                var weaponList = result["data"]["Data"]["${widget.serverName}WeaponList"]["Value"];

                if (null == weaponList)
                  return null;
                
              }),
              builder: (context, snapshot){
                return Container();
              },
            ),
          );
        },
      ),
    );
  }
}
