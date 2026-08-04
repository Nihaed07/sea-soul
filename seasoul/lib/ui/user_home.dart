import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'package:seasoul/ui/activity_details.dart';
import 'package:seasoul/ui/bottomnav.dart';
import 'package:seasoul/ui/chatbot.dart';
import 'package:seasoul/ui/explore.dart';
import 'package:seasoul/ui/notification_page.dart';
import 'package:seasoul/ui/product_details.dart';
import 'package:seasoul/ui/profile.dart';
import 'package:seasoul/ui/wishlist.dart';
import 'package:seasoul/ui/bookings_page.dart';

import 'package:seasoul/services/product_service.dart';
import 'package:seasoul/services/activity_service.dart';
import 'package:seasoul/services/wishlist_service.dart';
import 'package:seasoul/services/review_service.dart';
import 'package:seasoul/services/category_service.dart';
import 'package:seasoul/models/review_model.dart';
import 'package:seasoul/models/category_model.dart';
import 'package:seasoul/widgets/review_card.dart';
import 'package:seasoul/widgets/star_rating.dart';
import 'package:seasoul/providers/notification_provider.dart';
import 'package:seasoul/utils/image_utils.dart';
import 'package:seasoul/utils/icon_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentTab = 0;
  String _selectedCategoryForExplore = ''; // ✅ Store selected category
  String _selectedSort = 'popular';
  String _searchQuery = '';
  List<dynamic> _products = [];
  List<dynamic> _activities = [];
  bool _isLoading = true;
  bool _isLoadingFeatured = true;
  bool _isLoadingTrending = true;
  bool _isLoadingActivities = true;
  List<dynamic> _featuredProducts = [];
  List<dynamic> _trendingProducts = [];
  List<dynamic> _featuredActivities = [];
  List<dynamic> _allProducts = [];

  // ✅ Categories from backend
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;

  // Store ratings for products and activities
  Map<String, double> _productRatings = {};
  Map<String, int> _productReviewCounts = {};
  Map<String, double> _activityRatings = {};
  Map<String, int> _activityReviewCounts = {};
  bool _isLoadingRatings = true;

  // Recent Reviews
  List<ReviewModel> _recentReviews = [];
  bool _isLoadingReviews = true;
  Timer? _reviewRefreshTimer;

  // Auto-slide controllers
  late PageController _packagePageController;
  late PageController _activityPageController;
  int _currentPackageIndex = 0;
  int _currentActivityIndex = 0;
  Timer? _packageTimer;
  Timer? _activityTimer;

  static const Color deepNavy = Color(0xFF1A2B49);
  static const Color oceanBlue = Color(0xFF0099CC);
  static const Color sunsetOrange = Color(0xFFFFB84D);
  static const Color outline = Color(0xFF6E7880);
  static const Color sandWhite = Color(0xFFF8FBFF);
  static const Color turquoise = Color(0xFF00C2A8);
  static const Color coral = Color(0xFFFF6B35);

  final List<String> _sortOptions = [
    'popular',
    'rating',
    'price-low',
    'price-high',
    'newest',
  ];

  final Map<String, String> _sortLabels = {
    'popular': 'Most Popular',
    'rating': 'Top Rated',
    'price-low': 'Price: Low to High',
    'price-high': 'Price: High to Low',
    'newest': 'Newest First',
  };

  final Map<String, IconData> _sortIcons = {
    'popular': Icons.trending_up,
    'rating': Icons.star,
    'price-low': Icons.arrow_upward,
    'price-high': Icons.arrow_downward,
    'newest': Icons.fiber_new,
  };

  @override
  void initState() {
    super.initState();
    _packagePageController = PageController();
    _activityPageController = PageController();
    _loadCategories();
    _loadAllData();
    _loadRecentReviews();

    _reviewRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadRecentReviews();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      provider.refresh();

      Future.delayed(const Duration(seconds: 5), () {
        provider.updateUnreadCount();
      });
    });
  }

  @override
  void dispose() {
    _packagePageController.dispose();
    _activityPageController.dispose();
    _packageTimer?.cancel();
    _activityTimer?.cancel();
    _reviewRefreshTimer?.cancel();
    super.dispose();
  }

  // ✅ Load categories from backend
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await CategoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
      print('✅ Loaded ${_categories.length} categories from backend');
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() {
        _categories = [];
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadRecentReviews() async {
    try {
      final response = await ReviewService.getRecentReviews(limit: 3);
      if (response['success'] == true) {
        final reviewsList = response['reviews'] as List? ?? [];
        final reviews = reviewsList
            .where((r) => r is Map<String, dynamic>)
            .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _recentReviews = reviews;
            _isLoadingReviews = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading recent reviews: $e');
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadProducts(),
      _loadFeaturedProducts(),
      _loadTrendingProducts(),
      _loadActivities(),
      _loadFeaturedActivities(),
      _loadAllRatings(),
    ]);

    _startPackageAutoSlide();
    _startActivityAutoSlide();
  }

  Future<void> _loadAllRatings() async {
    setState(() => _isLoadingRatings = true);

    try {
      for (var product in _allProducts) {
        final productId = product['_id'];
        if (productId != null) {
          final response = await ReviewService.getItemReviews(
            itemId: productId,
            itemType: 'product',
            limit: 1,
          );
          if (response['success'] == true) {
            _productRatings[productId] = (response['averageRating'] ?? 0)
                .toDouble();
            _productReviewCounts[productId] = response['totalReviews'] ?? 0;
          }
        }
      }

      for (var activity in _activities) {
        final activityId = activity['_id'];
        if (activityId != null) {
          final response = await ReviewService.getItemReviews(
            itemId: activityId,
            itemType: 'activity',
            limit: 1,
          );
          if (response['success'] == true) {
            _activityRatings[activityId] = (response['averageRating'] ?? 0)
                .toDouble();
            _activityReviewCounts[activityId] = response['totalReviews'] ?? 0;
          }
        }
      }
    } catch (e) {
      print('❌ Error loading ratings: $e');
    }

    setState(() => _isLoadingRatings = false);
  }

  void _startPackageAutoSlide() {
    _packageTimer?.cancel();
    if (_trendingProducts.length > 1) {
      _packageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_trendingProducts.isNotEmpty && mounted) {
          int nextIndex = (_currentPackageIndex + 1) % _trendingProducts.length;
          _packagePageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          setState(() {
            _currentPackageIndex = nextIndex;
          });
        }
      });
    }
  }

  void _startActivityAutoSlide() {
    _activityTimer?.cancel();
    if (_activities.length > 1) {
      _activityTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_activities.isNotEmpty && mounted) {
          int nextIndex = (_currentActivityIndex + 1) % _activities.length;
          _activityPageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          setState(() {
            _currentActivityIndex = nextIndex;
          });
        }
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await ProductService.getProducts();
      if (response['success'] == true) {
        setState(() {
          _allProducts = response['products'] ?? [];
          _applySortAndFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading products: $e');
    }
  }

  void _applySortAndFilter() {
    List<dynamic> filtered = _allProducts;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        final name = (product['name'] ?? '').toLowerCase();
        final location = (product['location'] ?? '').toLowerCase();
        final description = (product['description'] ?? '').toLowerCase();
        return name.contains(query) ||
            location.contains(query) ||
            description.contains(query);
      }).toList();
    }

    switch (_selectedSort) {
      case 'price-low':
        filtered.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
        break;
      case 'price-high':
        filtered.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
        break;
      case 'rating':
        filtered.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        break;
      case 'popular':
        filtered.sort(
          (a, b) => (b['reviews'] ?? 0).compareTo(a['reviews'] ?? 0),
        );
        break;
      case 'newest':
      default:
        filtered.sort(
          (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''),
        );
        break;
    }

    setState(() {
      _products = filtered;
    });
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() => _isLoadingFeatured = true);
    try {
      final response = await ProductService.getFeaturedProducts();
      if (response['success'] == true) {
        setState(() {
          _featuredProducts = response['products'] ?? [];
          _isLoadingFeatured = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingFeatured = false);
      print('❌ Error loading featured products: $e');
    }
  }

  Future<void> _loadTrendingProducts() async {
    setState(() => _isLoadingTrending = true);
    try {
      final response = await ProductService.getTrendingProducts();
      if (response['success'] == true) {
        setState(() {
          _trendingProducts = response['products'] ?? [];
          _isLoadingTrending = false;
        });
        _startPackageAutoSlide();
      }
    } catch (e) {
      setState(() => _isLoadingTrending = false);
      print('❌ Error loading trending products: $e');
    }
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoadingActivities = true);
    try {
      final response = await ActivityService.getActivities();
      if (response['success'] == true) {
        setState(() {
          _activities = response['activities'] ?? [];
          _isLoadingActivities = false;
        });
        _startActivityAutoSlide();
      }
    } catch (e) {
      setState(() => _isLoadingActivities = false);
      print('❌ Error loading activities: $e');
    }
  }

  Future<void> _loadFeaturedActivities() async {
    try {
      final response = await ActivityService.getFeaturedActivities();
      if (response['success'] == true) {
        setState(() {
          _featuredActivities = response['activities'] ?? [];
        });
      }
    } catch (e) {
      print('❌ Error loading featured activities: $e');
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applySortAndFilter();
    });
  }

  void _handleSort(String sortOption) {
    setState(() {
      _selectedSort = sortOption;
      _applySortAndFilter();
    });
  }

  // ✅ FIXED: Navigate to category in Explore page with arguments
  void _navigateToCategory(String categoryName) {
    setState(() {
      _selectedCategoryForExplore = categoryName;
      _currentTab = 1; // Switch to Explore tab
    });
    print('🔍 Navigating to category: $categoryName');
  }

  Future<void> openWhatsApp() async {
    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/+919656100143?text=Hello%20SeaSoul',
    );
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget buildNetworkImage(
    String imageUrl, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    final cleanUrl = ImageUtils.getCleanImageUrl(imageUrl);

    if (!ImageUtils.isValidImage(cleanUrl)) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
      );
    }

    return Image.network(
      cleanUrl,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder:
          (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) return child;
            return Container(
              height: height,
              width: width,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  color: oceanBlue,
                ),
              ),
            );
          },
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            print('❌ Image error: $error');
            return Container(
              height: height,
              width: width,
              color: Colors.grey[200],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 30,
              ),
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ✅ FIXED: Create pages with category argument + unique key for ExplorePage
    // The key forces Flutter to rebuild ExplorePage when category changes
    final List<Widget> pages = [
      _buildHomeBody(),
      // ✅ KEY FIX: Use ValueKey so ExplorePage rebuilds when category changes
      ExplorePage(
        key: ValueKey<String>('explore_$_selectedCategoryForExplore'),
        initialCategory: _selectedCategoryForExplore,
      ),
      _buildBookingsPlaceholder(),
      const WishlistPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: _currentTab == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 20,
              toolbarHeight: 70,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white.withOpacity(0.95), sandWhite],
                  ),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: oceanBlue.withOpacity(0.2),
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/image.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SeaSoul',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: deepNavy,
                        ),
                      ),
                      Text(
                        'LUXURIOUS ISLAND GETAWAYS',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: outline,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: deepNavy,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        if (provider.unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                provider.unreadCount > 9
                                    ? '9+'
                                    : '${provider.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            )
          : null,
      body: IndexedStack(index: _currentTab, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openWhatsApp();
        },
        backgroundColor: const Color(0xFF25D366).withOpacity(0.9),
        elevation: 6,
        shape: const CircleBorder(),
        child: const FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Colors.white,
          size: 26,
        ),
      ),
      bottomNavigationBar: Bottomnav(
        currentIndex: _currentTab,
        onTabSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildHeaderSection(),
          const SizedBox(height: 32),
          _buildCategoriesSection(),
          const SizedBox(height: 32),
          _buildPackagesSection(),
          const SizedBox(height: 32),
          _buildIslandHighlightsSection(),
          const SizedBox(height: 32),
          _buildBentoGridSection(),
          const SizedBox(height: 32),
          _buildRecentReviewsSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: deepNavy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: _handleSearch,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: outline),
          hintText: 'Search packages...',
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

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/header.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/image.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'SeaSoul Holidays',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'LUXURIOUS ISLAND GETAWAYS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: oceanBlue,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions, color: oceanBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Discover the pristine islands of Lakshadweep with SeaSoul - your gateway to luxury, adventure, and unforgettable experiences.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('12+', 'Islands'),
                _buildStatItem('150+', 'Packages'),
                _buildStatItem('10K+', 'Travelers'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: oceanBlue,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ DYNAMIC CATEGORIES SECTION - Only from database
  Widget _buildCategoriesSection() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator(color: oceanBlue)),
      );
    }

    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];

          // Parse color from hex string
          Color color = oceanBlue;
          try {
            final hexColor = category.color.replaceFirst('#', '0xFF');
            color = Color(int.parse(hexColor));
          } catch (_) {
            color = oceanBlue;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () {
                // ✅ Navigate to Explore page with this category filter
                _navigateToCategory(category.name);
              },
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconHelper.buildIcon(
                      category.icon,
                      size: 28,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: deepNavy,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPackagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular Packages',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: deepNavy,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategoryForExplore = '';
                  _currentTab = 1;
                });
              },
              child: const Text(
                'View All →',
                style: TextStyle(
                  color: oceanBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingTrending)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_trendingProducts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No packages available'),
          )
        else
          SizedBox(
            height: 310,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _packagePageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPackageIndex = index;
                        _packageTimer?.cancel();
                        _startPackageAutoSlide();
                      });
                    },
                    itemCount: _trendingProducts.length,
                    itemBuilder: (context, index) {
                      final pkg = _trendingProducts[index];
                      final imageUrl = ImageUtils.getFirstImage(pkg['images']);

                      final pkgId = pkg['_id'];
                      final rating = _productRatings[pkgId] ?? 0;
                      final reviewCount = _productReviewCounts[pkgId] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsPage(productId: pkg['_id']),
                            ),
                          ).then((_) {
                            _loadAllData();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(
                                ImageUtils.getCleanImageUrl(imageUrl),
                              ),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                print('❌ Package image error: $exception');
                              },
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
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
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    pkg['category'] ?? 'Package',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: deepNavy,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        StarRating(rating: rating, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          rating > 0
                                              ? rating.toStringAsFixed(1)
                                              : '0.0',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '($reviewCount)',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pkg['name'] ?? 'Package',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      pkg['location'] ?? 'Location',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            text: '₹${pkg['price'] ?? 0}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: oceanBlue,
                                            ),
                                            children: const [
                                              TextSpan(
                                                text: ' /person',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [oceanBlue, turquoise],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Text(
                                            'View',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_trendingProducts.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _trendingProducts.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPackageIndex == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPackageIndex == index
                                ? oceanBlue
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildIslandHighlightsSection() {
    final islands = [
      {
        'name': 'Agatti Island',
        'desc': 'The gateway to Lakshadweep with pristine beaches',
        'image':
            'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=600',
        'color': oceanBlue,
        'emoji': '🏝️',
      },
      {
        'name': 'Kavaratti Island',
        'desc': 'Famous for its turquoise lagoon and coral reefs',
        'image':
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
        'color': turquoise,
        'emoji': '🌊',
      },
      {
        'name': 'Minicoy Island',
        'desc': 'Known for its unique culture and lighthouse',
        'image':
            'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=600',
        'color': sunsetOrange,
        'emoji': '🗼',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Island Highlights',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: deepNavy,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedCategoryForExplore = '';
                  _currentTab = 1;
                });
              },
              child: const Text(
                'View All →',
                style: TextStyle(
                  color: oceanBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: islands.length,
            itemBuilder: (context, index) {
              final island = islands[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(island['image'] as String),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${island['emoji']} ${island['name']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            island['desc'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (island['color'] as Color).withOpacity(
                                0.8,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Explore →',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBentoGridSection() {
    List<dynamic> latestProducts = List.from(_allProducts);
    latestProducts.sort(
      (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''),
    );
    latestProducts = latestProducts.take(3).toList();

    if (latestProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discover the Archipelago',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: deepNavy,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            final product = latestProducts[0];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductDetailsPage(productId: product['_id']),
              ),
            ).then((_) {
              _loadAllData();
            });
          },
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image:
                  latestProducts[0]['images'] != null &&
                      latestProducts[0]['images'].isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(
                        ImageUtils.getCleanImageUrl(
                          latestProducts[0]['images'][0],
                        ),
                      ),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        print('❌ Bento image error: $exception');
                      },
                    )
                  : const DecorationImage(
                      image: NetworkImage(
                        'https://via.placeholder.com/400x200',
                      ),
                      fit: BoxFit.cover,
                    ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StarRating(
                            rating:
                                _productRatings[latestProducts[0]['_id']] ?? 0,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (_productRatings[latestProducts[0]['_id']] ?? 0) > 0
                                ? (_productRatings[latestProducts[0]['_id']] ??
                                          0)
                                      .toStringAsFixed(1)
                                : '0.0',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${_productReviewCounts[latestProducts[0]['_id']] ?? 0})',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latestProducts[0]['name'] ?? 'Product',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        latestProducts[0]['location'] ?? 'Location',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
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
                      color: sunsetOrange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${latestProducts[0]['price'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (latestProducts.length > 1)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final product = latestProducts[1];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsPage(productId: product['_id']),
                      ),
                    ).then((_) {
                      _loadAllData();
                    });
                  },
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image:
                          latestProducts[1]['images'] != null &&
                              latestProducts[1]['images'].isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                ImageUtils.getCleanImageUrl(
                                  latestProducts[1]['images'][0],
                                ),
                              ),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                print('❌ Bento image error: $exception');
                              },
                            )
                          : const DecorationImage(
                              image: NetworkImage(
                                'https://via.placeholder.com/300x200',
                              ),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  StarRating(
                                    rating:
                                        _productRatings[latestProducts[1]['_id']] ??
                                        0,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (_productRatings[latestProducts[1]['_id']] ??
                                                0) >
                                            0
                                        ? (_productRatings[latestProducts[1]['_id']] ??
                                                  0)
                                              .toStringAsFixed(1)
                                        : '0.0',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                latestProducts[1]['name'] ?? 'Product',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                latestProducts[1]['location'] ?? 'Location',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (latestProducts.length > 2) const SizedBox(width: 14),
            if (latestProducts.length > 2)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final product = latestProducts[2];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsPage(productId: product['_id']),
                      ),
                    ).then((_) {
                      _loadAllData();
                    });
                  },
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image:
                          latestProducts[2]['images'] != null &&
                              latestProducts[2]['images'].isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                ImageUtils.getCleanImageUrl(
                                  latestProducts[2]['images'][0],
                                ),
                              ),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                print('❌ Bento image error: $exception');
                              },
                            )
                          : const DecorationImage(
                              image: NetworkImage(
                                'https://via.placeholder.com/300x200',
                              ),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.65),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  StarRating(
                                    rating:
                                        _productRatings[latestProducts[2]['_id']] ??
                                        0,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (_productRatings[latestProducts[2]['_id']] ??
                                                0) >
                                            0
                                        ? (_productRatings[latestProducts[2]['_id']] ??
                                                  0)
                                              .toStringAsFixed(1)
                                        : '0.0',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                latestProducts[2]['name'] ?? 'Product',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                latestProducts[2]['location'] ?? 'Location',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentReviewsSection() {
    if (_isLoadingReviews) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(color: Color(0xFF0099CC)),
          ),
        ),
      );
    }

    if (_recentReviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Reviews',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2B49),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoadingReviews = true;
                });
                _loadRecentReviews().then((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔄 Reviews refreshed'),
                        backgroundColor: Color(0xFF0099CC),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                });
              },
              child: const Text(
                'Refresh →',
                style: TextStyle(
                  color: Color(0xFF0099CC),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._recentReviews.map(
          (review) => ReviewCard(
            review: review,
            onHelpfulTap: () async {
              try {
                await ReviewService.toggleHelpful(review.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Marked as helpful'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                _loadRecentReviews();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderPage({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Container(
      color: sandWhite,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: oceanBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: oceanBlue, size: 44),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: deepNavy,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: outline,
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: oceanBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsPlaceholder() {
    return _buildPlaceholderPage(
      icon: Icons.confirmation_number_outlined,
      title: 'My Bookings',
      subtitle: 'Your upcoming premium island escapes will appear here.',
      buttonText: 'Explore Destinations',
      onButtonPressed: () {
        setState(() {
          _selectedCategoryForExplore = '';
          _currentTab = 1;
        });
      },
    );
  }

  static Future<void> navigateToHome(BuildContext context) async {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const UserHome()),
      (route) => false,
    );
  }
}
