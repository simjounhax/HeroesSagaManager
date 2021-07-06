import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:heroes_saga_manager/Util.dart';

class PostData {
  String playFabId;
  String serverName;
  String rewardData;

  PostData(
    this.playFabId,
    this.serverName,
    this.rewardData,
  );
}

class PostManagerView extends StatefulWidget {
  const PostManagerView({Key? key, this.filePath}) : super(key: key);
  final filePath;

  @override
  _PostManagerViewState createState() => _PostManagerViewState();
}

class _PostManagerViewState extends State<PostManagerView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<PostData>>(future: Future(() async {
        File f = File(widget.filePath);
        if (false == await f.exists()) {
          throw ArgumentError("존재하지 않는 파일입니다");
        }

        final excelFile = Excel.decodeBytes(await f.readAsBytes());
        if (excelFile.tables.values.isEmpty) {
          showErrorDialog(context, "시트가 존재하지 않습니다");
        }
        Sheet firstSheet = excelFile.tables.values.first;
        if (firstSheet.maxRows < 2) {
          showErrorDialog(context, "데이터가 올바르지 않습니다");
        }

        List<PostData> postData = [];

        for (int i = 1; i < firstSheet.maxRows; i++) {
          List<Data?> eachDataRow = firstSheet.row(i);
          Data? userData = eachDataRow[0];
          Data? serverData = eachDataRow[1];
          Data? rewardData = eachDataRow[2];

          if (null == userData || null == serverData || null == rewardData) {
            showErrorDialog(context, "데이터가 올바르지 않음");
            break;
          }

          String playFabId = userData.value as String;
          String serverName = serverData.value as String;
          String rewardStringData = rewardData.value as String;

          postData.add(PostData(playFabId, serverName, rewardStringData));
        }

        return postData;
      }), builder: (context, AsyncSnapshot<List<PostData>> snapshot) {
        if (snapshot.connectionState.index < ConnectionState.done.index) {
          return Center(child: CircularProgressIndicator());
        } else if (0 == snapshot.data!.length) {
          return Center(
            child: SizedBox.expand(
              child: MaterialButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "데이터가 없습니다",
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
          );
        } else {
          return Center(
            child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, itemIndex) {
                  return Text(
                    "${snapshot.data![itemIndex].playFabId}, ${snapshot.data![itemIndex].serverName}, ${snapshot.data![itemIndex].rewardData}",
                    textAlign: TextAlign.center,
                  );
                }),
          );
        }
      }),
    );
  }
}
