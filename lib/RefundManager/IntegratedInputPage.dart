import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroes_saga_manager/Data/Data.dart';
import 'package:heroes_saga_manager/Data/Receipt.dart';
import 'package:heroes_saga_manager/Util.dart';

enum Mode { Receipt, PlayerId }

class IntegratedInputPage extends StatefulWidget {
  final Mode mode;
  IntegratedInputPage({Key? key, this.mode = Mode.Receipt}) : super(key: key);

  @override
  _IntegratedInputPageState createState() => _IntegratedInputPageState();
}

class _IntegratedInputPageState extends State<IntegratedInputPage> {
  late TextEditingController _controller;
  List<Receipt> _receipts = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: PageStorage?.of(context)?.readState(context,
                identifier: Mode.Receipt == widget.mode
                    ? ValueKey("receipt data")
                    : ValueKey("playerId data")) ??
            "");
    _receipts = PageStorage?.of(context)?.readState(context,
            identifier: Mode.Receipt == widget.mode
                ? ValueKey("receipt data by orderId")
                : ValueKey("receipt data by playerId")) ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    double narrowWidth =
        (Platform.isAndroid || Platform.isIOS || Platform.isFuchsia)
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.width / 4.5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 10.0),
      child: Form(
        child: Center(
          child: Column(
            children: [
              Container(
                width: narrowWidth,
                child: TextFormField(
                  autofocus: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: Mode.Receipt == widget.mode
                      ? InputDecoration(hintText: "영수증 아이디를 적어주세요(엔터 입력)")
                      : InputDecoration(hintText: "플레이어 아이디를 적어주세요(엔터 입력)"),
                  controller: _controller,
                  inputFormatters: Mode.Receipt == widget.mode
                      ? [
                          FilteringTextInputFormatter.allow(
                              RegExp('[-\.A-Z|0-9]')),
                          LengthLimitingTextInputFormatter(24)
                        ]
                      : [
                          FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                          LengthLimitingTextInputFormatter(16)
                        ],
                  onChanged: (String text) {
                    PageStorage?.of(context)?.writeState(context, text,
                        identifier: Mode.Receipt == widget.mode
                            ? ValueKey("receipt data")
                            : ValueKey("playerId data"));
                  },
                  validator: (String? val) {
                    if (val?.isEmpty ?? true) {
                      return "빈 값은 허용되지 않습니다";
                    }
                    return null;
                  },
                  onFieldSubmitted: (String text) async {
                    if (_controller.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("빈 값은 허용되지 않습니다"),
                          duration: Duration(
                            seconds: 1,
                          )));
                      return;
                    }

                    showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (dlgContext) {
                          return AlertDialog(
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircularProgressIndicator(),
                                Text("가져오는 중입니다...")
                              ],
                            ),
                          );
                        });

                    List<Receipt>? receipt = await (Mode.Receipt == widget.mode
                        ? getReceipt(receiptId: _controller.text)
                        : getReceipt(playerId: _controller.text));
                    Navigator.of(context).pop();

                    if (receipt?.isEmpty ?? true) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(Mode.Receipt == widget.mode
                              ? "해당 영수증이 없습니다"
                              : "해당 플레이어의 영수증이 없습니다"),
                          duration: Duration(
                            seconds: 1,
                          )));
                      return;
                    }

                    PageStorage?.of(context)?.writeState(context, receipt,
                        identifier: Mode.Receipt == widget.mode
                            ? ValueKey("receipt data by orderId")
                            : ValueKey("receipt data by playerId"));

                    setState(() {
                      _receipts = receipt!;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  width: narrowWidth,
                  child: ListView.builder(
                    itemBuilder: (ctx, i) {
                      return Container(
                        width: narrowWidth,
                        child: ElevatedButton(
                            onLongPress: () {
                              Clipboard.setData(new ClipboardData(
                                  text: _receipts[i].toString()));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                duration: Duration(seconds: 1),
                                content: Text("복사되었습니다"),
                              ));
                            },
                            onPressed: () {
                              showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (BuildContext dlgContext) {
                                    return AlertDialog(
                                      content: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "다음 아이템을 발급하시겠습니까?",
                                          ),
                                          Text(
                                            "${_receipts[i].itemId}",
                                            style: TextStyle(fontSize: 35),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        MaterialButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (procDlgContext) {
                                                  return AlertDialog(
                                                    content: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        CircularProgressIndicator(),
                                                        Text("발급 중입니다..."),
                                                      ],
                                                    ),
                                                  );
                                                });

                                            dynamic writeResult =
                                                await writePurchaseEmail(
                                                    _receipts[i].playFabId,
                                                    _receipts[i].serverName,
                                                    _receipts[i].timestamp, [
                                              PlayfabItem(
                                                  itemId: _receipts[i].itemId)
                                            ]);
                                            print(writeResult);
                                            Navigator.of(context).pop();

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              duration: Duration(seconds: 1),
                                              content: Text("아이템 발급이 완료되었습니다"),
                                            ));
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "네",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue),
                                            ),
                                          ),
                                        ),
                                        MaterialButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              duration: Duration(seconds: 1),
                                              content: Text("아이템 발급이 취소되었습니다"),
                                            ));
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "아니오",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  });
                            },
                            child: Container(
                                child: Text(_receipts[i].toString()))),
                      );
                    },
                    itemCount: _receipts.length,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
