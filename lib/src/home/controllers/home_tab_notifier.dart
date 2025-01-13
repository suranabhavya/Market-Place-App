import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/enums.dart';

class HomeTabNotifier with ChangeNotifier {
  QueryType queryType = QueryType.all;
  String _index = 'All';

  String get index => _index;

  void setIndex(String index) {
    _index = index;

    switch(index) {
      case 'All':
        setQueryType(QueryType.all);
        break;
      case 'Popular':
        setQueryType(QueryType.popular);
        break;
      case 'Nearby':
        setQueryType(QueryType.nearby);
        break;
      default:
        setQueryType(QueryType.all);
    }

    notifyListeners();
  }

  void setQueryType(QueryType q) {
    queryType = q;
  }
}