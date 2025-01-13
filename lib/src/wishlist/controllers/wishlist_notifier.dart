import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:http/http.dart' as http;

class WishlistNotifier with ChangeNotifier {
  String? error;

  void setError(String e) {
    error = e;
    notifyListeners();
  }

  void addRemoveWishlist(String id, Function refetch) async {
    final accessToken = Storage().getString('accessToken');
  
    try {
      Uri url = Uri.parse('${Environment.appBaseUrl}/api/wishlist/toggle/?id=$id');

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Token $accessToken",
          "Content-Type": "application/json",
        },
      );

      if(response.statusCode == 201) {
        // Set the ID to a list in our local storage
        setToList(id);
        // Refetch data
        refetch();
      } else if(response.statusCode == 204) {
        // Remove from local storage
        setToList(id);
        // Refetch data
        refetch();
      }
    } catch (e) {
      error = e.toString();
    }
  }

  List _wishlist = [];

  List get wishlist => _wishlist;

  void setWishlist(List w) {
    _wishlist.clear();
    _wishlist = w;
    notifyListeners();
  }

  void setToList(String v) {
    String? accessToken = Storage().getString('accessToken');
    String? wishlist = Storage().getString('${accessToken}wishlist');
    if(wishlist == null) {
      List wishlist = [];
      wishlist.add(v);
      setWishlist(wishlist);
      Storage().setString('${accessToken}wishlist', jsonEncode(wishlist));
    } else {
      List w = jsonDecode(wishlist);
      if(w.contains(v)) {
        w.removeWhere((e) => e == v);
        setWishlist(w);

        Storage().setString('${accessToken}wishlist', jsonEncode(w));
      } else if(!w.contains(v)) {
        w.add(v);
        setWishlist(w);
        Storage().setString('${accessToken}wishlist', jsonEncode(w));
      }
    }
  }
}