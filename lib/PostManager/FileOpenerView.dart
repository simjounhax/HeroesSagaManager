import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:heroes_saga_manager/PostManager/PostManagerView.dart';
import 'package:path/path.dart';

class FileOpenerView extends StatefulWidget {
  const FileOpenerView({Key? key}) : super(key: key);

  @override
  _FileOpenerViewState createState() => _FileOpenerViewState();
}

class _FileOpenerViewState extends State<FileOpenerView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          return SizedBox.expand(
            child: MaterialButton(
                hoverColor: Colors.lightBlue.shade100,
                child: Text("파일 열기"),
                onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (BuildContext dlgContext) {
                        return AlertDialog(
                          title: Text(
                            "파일 여는 중...",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          content: Text("잠시만 기다리세요"),
                        );
                      });
                  try {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      allowMultiple: false,
                    );
                    if (result != null) {
                      var ext = extension(result.files.single.path!);
                      if (".xlsx" != ext) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("엑셀 파일이 아님. xlsx 파일만 열 수 있음"),
                          duration: Duration(milliseconds: 1000),
                        ));
                        return;
                      }
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return PostManagerView(
                          filePath: result.files.single.path!,
                        );
                      }));
                    } else {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("올바르지 않은 파일임"),
                        duration: Duration(milliseconds: 300),
                      ));
                    }
                  } catch (e) {
                    print(e);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("파일 열기 취소함"),
                      duration: Duration(milliseconds: 300),
                    ));
                  }
                }),
          );
        },
      ),
    );
  }
}
