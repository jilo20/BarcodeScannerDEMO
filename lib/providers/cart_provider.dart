import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  
  // Mock product database
  final Map<String, Product> _mockDatabase = {
    'MILK-123456789': Product(id: 'MILK-123456789', name: 'Milk Carton', price: 3.50),
    'BREAD-987654321': Product(id: 'BREAD-987654321', name: 'Wheat Bread', price: 2.20),
    'EGGS-112233445': Product(id: 'EGGS-112233445', name: 'Dozen Eggs', price: 4.80),
  };

  List<CartItem> get items => _items;

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.total);

  void scanBarcode(String code) {
    // Check if product exists in our "database"
    final product = _mockDatabase[code];
    
    if (product != null) {
      // Check if already in cart
      final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
      
      if (existingIndex >= 0) {
        _items[existingIndex].quantity++;
      } else {
        _items.add(CartItem(product: product));
      }
      notifyListeners();
    } else {
      // For any "other" product not in database (as requested)
      // We can add it as a "Generic Product" with the barcode as name or handle it as unknown
      final genericProduct = Product(id: code, name: 'Product ($code)', price: 1.00);
      final existingIndex = _items.indexWhere((item) => item.product.id == genericProduct.id);
      
      if (existingIndex >= 0) {
        _items[existingIndex].quantity++;
      } else {
        _items.add(CartItem(product: genericProduct));
      }
      notifyListeners();
    }
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
