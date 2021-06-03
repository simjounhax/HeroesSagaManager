import 'package:flutter/material.dart';
import 'package:heroes_saga_manager/RefundManager/IntegratedInputPage.dart';

class RefundManager extends StatefulWidget {
  RefundManager();

  final List<Widget> _currentWidget = [
    IntegratedInputPage(
      key: PageStorageKey("Receipt page"),
      mode: Mode.Receipt,
    ),
    IntegratedInputPage(
      key: PageStorageKey("PlayerId page"),
      mode: Mode.PlayerId,
    )
  ];
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<RefundManager> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
          bucket: widget._bucket, child: widget._currentWidget[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "영수증 입력"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "플레이어 아이디 입력"),
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
