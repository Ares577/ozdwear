import 'package:flutter_test/flutter_test.dart';
import 'package:ozd_wear_app/models/product.dart';

void main() {
  test('product model parses numeric fields safely', () {
    final product = Product.fromJson({'id_product': '7', 'name': 'Test', 'price': '120.50'});
    expect(product.id, 7);
    expect(product.price, 120.50);
  });
}
