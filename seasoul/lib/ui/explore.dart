import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seasoul/services/product_service.dart';
import 'package:seasoul/services/activity_service.dart';
import 'package:seasoul/services/category_service.dart';
import 'package:seasoul/ui/activity_details.dart';
import 'package:seasoul/ui/product_details.dart';
import 'package:seasoul/utils/image_utils.dart';

class ExplorePage extends StatefulWidget {
  final String? initialCategory;

  const ExplorePage({super.key, this.initialCategory});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  int _activeCategoryIndex = 0;
  String _searchQuery = '';
  List<dynamic> _allItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  bool _isInitialFilterApplied = false;

  // ✅ Categories from backend only
  List<Map<String, dynamic>> _categories = [];

  static const Color deepNavy = Color(0xFF1A2B49);
  static const Color oceanBlue = Color(0xFF0099CC);
  static const Color turquoiseLagoon = Color(0xFF00C2A8);
  static const Color outline = Color(0xFF6E7880);
  static const Color sandWhite = Color(0xFFF8FBFF);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAllItems();
  }

  // ✅ NEW: Handle when initialCategory changes from parent
  @override
  void didUpdateWidget(ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if initialCategory changed and is not empty
    if (widget.initialCategory != oldWidget.initialCategory &&
        widget.initialCategory != null &&
        widget.initialCategory!.isNotEmpty) {
      print('🔍 didUpdateWidget: New category received: ${widget.initialCategory}');

      // Wait for categories to load, then apply filter
      if (!_isLoadingCategories && _categories.isNotEmpty) {
        _applyCategoryFilter(widget.initialCategory!);
      } else {
        // If categories still loading, retry after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _applyCategoryFilter(widget.initialCategory!);
          }
        });
      }
    }
  }

  // ✅ Load categories from backend
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await CategoryService.getCategories();
      setState(() {
        _categories = [
          {'id': 'all', 'name': 'All'},
          ...categories.map((cat) => {
            'id': cat.id,
            'name': cat.name,
            'color': cat.color,
            'icon': cat.icon,
          }),
        ];
        _isLoadingCategories = false;
      });
      print('✅ Loaded ${_categories.length} categories from backend');

      // ✅ Apply initial category if provided (after categories loaded)
      if (widget.initialCategory != null && 
          widget.initialCategory!.isNotEmpty && 
          !_isInitialFilterApplied) {
        _applyCategoryFilter(widget.initialCategory!);
        _isInitialFilterApplied = true;
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() {
        _categories = [
          {'id': 'all', 'name': 'All'},
        ];
        _isLoadingCategories = false;
      });
    }
  }

  // ✅ Apply category filter
  void _applyCategoryFilter(String categoryName) {
    if (categoryName == 'All' || _categories.isEmpty) {
      setState(() {
        _activeCategoryIndex = 0;
      });
      _applyFilters();
      return;
    }

    final index = _categories.indexWhere(
      (cat) => cat['name'].toLowerCase() == categoryName.toLowerCase()
    );

    if (index != -1) {
      setState(() {
        _activeCategoryIndex = index;
      });
      _applyFilters();
      print('✅ Applied filter for category: $categoryName');
    } else {
      print('⚠️ Category not found: $categoryName');
    }
  }

  // ✅ Load both products and activities and combine them
  Future<void> _loadAllItems() async {
    setState(() => _isLoading = true);
    try {
      final productsResponse = await ProductService.getProducts();
      final activitiesResponse = await ActivityService.getActivities();

      List<dynamic> products = [];
      List<dynamic> activities = [];

      if (productsResponse['success'] == true) {
        products = productsResponse['products'] ?? [];
      }
      if (activitiesResponse['success'] == true) {
        activities = activitiesResponse['activities'] ?? [];
      }

      // ✅ Combine and add type field for identification
      final combined = <dynamic>[
        ...products.map((p) => {...p, '_type': 'product'}),
        ...activities.map((a) => {...a, '_type': 'activity'}),
      ];

      setState(() {
        _allItems = combined;
        _isLoading = false;
      });

      // Apply initial filter
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading items: $e');
    }
  }

  // ✅ Apply category and search filters
  void _applyFilters() {
    if (_categories.isEmpty) {
      setState(() {
        _filteredItems = _allItems;
      });
      return;
    }

    // Make sure _activeCategoryIndex is within bounds
    if (_activeCategoryIndex >= _categories.length) {
      setState(() {
        _activeCategoryIndex = 0;
      });
      return;
    }

    final selectedCategory = _categories[_activeCategoryIndex];
    final categoryName = selectedCategory['name'];

    setState(() {
      _filteredItems = _allItems.where((item) {
        // Category filter
        if (categoryName != 'All') {
          final itemCategory = item['category'] ?? '';
          if (itemCategory.toLowerCase() != categoryName.toLowerCase()) {
            return false;
          }
        }
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final name = (item['name'] ?? '').toLowerCase();
          final location = (item['location'] ?? '').toLowerCase();
          final query = _searchQuery.toLowerCase();
          if (!name.contains(query) && !location.contains(query)) {
            return false;
          }
        }
        return true;
      }).toList();
    });

    print('📊 Filtered items: ${_filteredItems.length} out of ${_allItems.length} for category: $categoryName');
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _handleCategoryTap(int index) {
    setState(() {
      _activeCategoryIndex = index;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCategories || _isLoading) {
      return Container(
        color: sandWhite,
        child: const Center(
          child: CircularProgressIndicator(color: oceanBlue),
        ),
      );
    }

    final emptyMessage = _searchQuery.isNotEmpty 
        ? 'No items found matching your search'
        : 'No items available in this category';

    return Container(
      color: sandWhite,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore Destinations',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: deepNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Discover the pristine jewels of the Arabian Sea',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  // Show active filter indicator
                  if (_activeCategoryIndex > 0 && _categories.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: oceanBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_alt, color: oceanBlue, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Filtered by: ${_categories[_activeCategoryIndex]['name']}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: oceanBlue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              _handleCategoryTap(0);
                            },
                            child: Icon(Icons.close, color: oceanBlue, size: 16),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Category Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildCategoryChips(),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: _filteredItems.isEmpty
                  ? _buildEmptyState(emptyMessage)
                  : _buildItemGrid(_filteredItems),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: deepNavy.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: _handleSearch,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: outline),
          hintText: 'Search by name or location...',
          hintStyle: const TextStyle(
            color: outline,
            fontFamily: 'Inter',
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: outline, size: 18),
                  onPressed: () {
                    _handleSearch('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _activeCategoryIndex == index;
          final category = _categories[index];
          final categoryName = category['name'] ?? '';

          // Parse color if available
          Color categoryColor = turquoiseLagoon;
          try {
            if (category['color'] != null) {
              final hexColor = category['color'].toString().replaceFirst('#', '0xFF');
              categoryColor = Color(int.parse(hexColor));
            }
          } catch (_) {}

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _handleCategoryTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? categoryColor
                      : categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: isSelected
                      ? null
                      : Border.all(color: categoryColor.withOpacity(0.2)),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : categoryColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _loadAllItems();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List<dynamic> items) {
    if (items.isEmpty) {
      return _buildEmptyState('No items found');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          childAspectRatio: 0.58,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final images = item['images'] ?? [];
          final imageUrl = images.isNotEmpty
              ? images[0]
              : 'https://via.placeholder.com/300x200';
          final itemId = item['_id'];
          final itemName = item['name'] ?? 'Item';
          final itemTagline = item['location'] ?? 'Location';
          final itemPrice = item['price'] ?? 0;
          final itemType = item['_type'] ?? 'product';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (itemType == 'product') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsPage(productId: itemId),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ActivityDetailsPage(activityId: itemId),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(
                              ImageUtils.getCleanImageUrl(imageUrl),
                            ),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              print('❌ Explore image error: $exception');
                            },
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '₹$itemPrice',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: oceanBlue,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: itemType == 'product'
                              ? oceanBlue.withOpacity(0.9)
                              : Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          itemType == 'product' ? 'PACKAGE' : 'ACTIVITY',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (item['isFeatured'] == true)
                      Positioned(
                        top: 50,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB84D).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: deepNavy,
                      ),
                    ),
                    Text(
                      itemTagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: outline,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'STARTING',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: outline.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '₹$itemPrice',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: oceanBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          if (itemType == 'product') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailsPage(productId: itemId),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ActivityDetailsPage(activityId: itemId),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: oceanBlue.withOpacity(0.05),
                          side: BorderSide(color: oceanBlue.withOpacity(0.1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: oceanBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}