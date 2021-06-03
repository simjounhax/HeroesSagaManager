import 'package:heroes_saga_manager/Util.dart';

class Receipt extends Object {
  String orderId;
  String itemId;
  String price;
  String serverName;
  String timestamp;
  String playFabId;

  Receipt({required this.orderId, required this.itemId, required this.serverName, required this.price, required this.timestamp, required this.playFabId});

  Map<String, dynamic> toJson() {
    return {
      "playFabId": playFabId,
      "orderId": orderId,
      "itemId": itemId,
      "serverName": serverName,
      "price": price,
      "timestamp": timestamp,
    };
  }

  @override
  String toString() {
    return jsonEncoder.convert(this);
  }
}
