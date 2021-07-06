import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroes_saga_manager/ItemManager/ItemQuantityVerifier.dart';
import 'package:heroes_saga_manager/PostManager/FileOpenerView.dart';
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
      debugShowCheckedModeBanner: false,
      home: PageWrapper(),
    );
  }
}

class PageWrapper extends StatefulWidget {
  @override
  _PageWrapperState createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper> {
  Widget                _itemManager            = ItemManager();
  Widget                _refundManager          = RefundManager();
  Widget                _fileOpener             = FileOpenerView();
  Widget                _weaponQuantityVerifier = CharacterSelectPage();
  late Widget           _currentWidget;
  late BuildContext     _scaffContext;

  @override
  void initState() {
    _currentWidget = _itemManager;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: "메뉴 열기",
        child: Icon(Icons.menu, color: Colors.white,),
        onPressed: () {
          Scaffold.of(_scaffContext).openDrawer();
        },
      ),
      body: Builder(
        builder: (BuildContext context) {
          _scaffContext = context;
          return _currentWidget;
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
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentWidget = _itemManager;
                  });
                },
                child: Text("아이템 관리 페이지"),
              ),
            ),
            Expanded(
              child: MaterialButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentWidget = _refundManager;
                  });
                },
                child: Text("환불 관리 페이지"),
              ),
            ),
            Expanded(
              child: MaterialButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentWidget = _fileOpener;
                  });
                },
                child: Text("우편 보내기 페이지"),
              ),
            ),
            Expanded(
              child: MaterialButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentWidget = _weaponQuantityVerifier;
                  });
                },
                child: Text("무기 갯수 검증"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
