import 'package:flutter/material.dart';

class CategoryProvider extends ChangeNotifier {
  String _selectedCategory = 'All';
  bool _hasFilter = false;
  
  String get selectedCategory => _selectedCategory;
  bool get hasFilter => _hasFilter;
  
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _hasFilter = true;
    notifyListeners();
  }
  
  void resetCategory() {
    _selectedCategory = 'All';
    _hasFilter = false;
    notifyListeners();
  }
}