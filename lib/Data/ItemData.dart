class ItemData extends Object {
  String itemId;
  int quantity;

  ItemData({required this.itemId, this.quantity = 1});

  Map<String, dynamic> toJson() {
    return {"ItemId": itemId, "Quantity": quantity};
  }
}
