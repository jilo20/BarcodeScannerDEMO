class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});
}

class InventoryItem {
  final Product product;
  int quantity;

  InventoryItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}
