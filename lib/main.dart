import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ItemManagerView.dart';

void main() {
  runApp(HeroesSagaManagerApp());
}

class HeroesSagaManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  final List                _views = [
      ItemManagerView(mode: Mode.Item,      key: PageStorageKey("ItemManager"),     ),
      ItemManagerView(mode: Mode.Container, key: PageStorageKey("ContainerManager"),),
      ItemManagerView(mode: Mode.ETCItem,   key: PageStorageKey("ETCItemManager"),  )
    ];
  final PageStorageBucket   _bucket = PageStorageBucket();

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
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
