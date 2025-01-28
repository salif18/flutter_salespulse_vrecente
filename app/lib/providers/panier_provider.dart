import 'dart:convert';

// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:salespulse/models/cart_item_model.dart';
import 'package:salespulse/models/stocks_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PanierProvider extends ChangeNotifier {
  List<CartItemModel> _cart = [];
  int _total = 0;
  int _totalArticle = 0;
  bool _isLoading = true;

  PanierProvider() {
    loadCartFromLocalStorage();
  }

  List<CartItemModel> get myCart => _cart;
  int get total => calculateTotal();
  int get totalArticle => calculateNombreArticel();
  bool get isLoading => _isLoading;

  // Add item to cart
  void addToCart(StocksModel article, int newQty) {
    final itemIsExist = _cart.firstWhereOrNull(
      (item) => item.productId == article.productId.toString(),
    );

    if (itemIsExist != null) {
      itemIsExist.qty += newQty;
    } else {
      _cart.add(CartItemModel(
          productId: article.productId.toString(),
          nom: article.nom,
          image: article.image,
          categories: article.categories,
          qty: newQty,
          prixVente: article.prixVente * newQty,
          prixAchat: article.prixAchat,
          stocks: article.stocks,
      ));
    }

    newQty = 0;

    saveCartToLocalStorage();
    notifyListeners();
  }

  // Remove item from cart
  void removeToCart(CartItemModel item) {
    _cart.removeWhere((cartItem) => cartItem.productId == item.productId);
    saveCartToLocalStorage();
    notifyListeners();
  }

  // Increment item quantity
  void increment(CartItemModel article) {
    final newCart = _cart.map(
      (cartItem) => article.productId == cartItem.productId
          ? CartItemModel(
              productId: cartItem.productId.toString(),
              nom: cartItem.nom,
              image: cartItem.image,
              categories: cartItem.categories,
              qty: cartItem.qty + 1,
              prixVente: cartItem.prixVente,
              prixAchat: cartItem.prixAchat,
              stocks: cartItem.stocks,
              )
          : cartItem,
    );
    _cart = newCart.toList();
    saveCartToLocalStorage();
    notifyListeners();
  }

  // Decrement item quantity
  void decrement(CartItemModel article) {
    final newCart = _cart.map(
      (cartItem) => cartItem.productId == article.productId && cartItem.qty > 1
          ? CartItemModel(
              productId: cartItem.productId.toString(),
              nom: cartItem.nom,
              image: cartItem.image,
              categories: cartItem.categories,
              qty: cartItem.qty - 1,
              prixVente: cartItem.prixVente,
              prixAchat: cartItem.prixAchat,
              stocks: cartItem.stocks,
             
            )
          : cartItem,
    );
    _cart = newCart.toList();
    saveCartToLocalStorage();
    notifyListeners();
  }

  // Calculate total price
  int calculateTotal() {
    if (_cart.isNotEmpty) {
      _total = _cart
          .map((cartItem) => cartItem.qty * cartItem.prixVente)
          .reduce((a, b) => a + b);
    } else {
      _total = 0;
    }
    return _total;
  }

  // Calculate total price
  int calculateNombreArticel() {
    if (_cart.isNotEmpty) {
      _totalArticle = _cart
          .map((cartItem) => cartItem.qty)
          .reduce((a, b) => a + b);
    } else {
      _totalArticle = 0;
    }
    return _totalArticle;
  }


  // Save cart to local storage
  Future<void> saveCartToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = _cart.map((item) => item.toJson()).toList();
    await prefs.setString("cart", jsonEncode(cartJson));
  }

  // Load cart from local storage
  Future<void> loadCartFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJsonString = prefs.getString("cart");

    if (cartJsonString != null) {
      final cartJson = jsonDecode(cartJsonString) as List;
      _cart = cartJson
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear cart
  void clearCart() {
    _cart.clear();
    saveCartToLocalStorage();
    notifyListeners();
  }
}
