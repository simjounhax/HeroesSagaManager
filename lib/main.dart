import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroes_saga_manager/RefundManager/RefundManagerView.dart';
import 'ItemManager/ItemManagerView.dart';

void main() {
  runApp(HeroesSagaManagerApp());
}

class HeroesSagaManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: PageWrapper(),
    );
  }
}

class PageWrapper extends StatefulWidget {
  @override
  _PageWrapperState createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper> {
  Widget currentWidget = ItemManager();
  late BuildContext _scaffContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
      floatingActionButton: FloatingActionButton(
        tooltip: "메뉴 열기",
        child: Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(_scaffContext).openDrawer();
        },
      ),
      body: Builder(
        builder: (BuildContext context) {
          _scaffContext = context;
          return currentWidget;
        },
      ),
      drawer: Drawer(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: MaterialButton(
                onPressed: () { setState((){currentWidget = ItemManager();}); },
                child: Text("아이템 관리 페이지"),
              ),
            ),
            Expanded(
              child: MaterialButton(
                onPressed: () { setState((){currentWidget = RefundManager();}); },
                child: Text("환불 관리 페이지"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}