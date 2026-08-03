import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seasoul/services/product_service.dart';
import 'package:seasoul/services/activity_service.dart';
import 'package:seasoul/services/wishlist_service.dart';
import 'package:seasoul/services/review_service.dart';
import 'package:seasoul/services/location_service.dart';
import 'package:seasoul/models/review_model.dart';
import 'package:seasoul/ui/activity_details.dart';
import 'package:seasoul/ui/payment.dart';
import 'package:seasoul/ui/review_page.dart';
import 'package:seasoul/widgets/review_card.dart';
import 'package:seasoul/widgets/star_rating.dart';
import 'package:seasoul/utils/image_utils.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;
  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isBookmarked = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _product;
  List<dynamic> _activities = [];

  DateTime? _startDate;
  DateTime? _endDate;
  int _numberOfDays = 1;

  double _distanceInKm = 0.0;
  String _distanceText = 'Loading...';
  String _fromLocation = 'Your Location';
  bool _isDistanceLoading = true;

  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isLoadingReviews = true;

  static const Color deepNavy = Color(0xFF1A2B49);
  static const Color oceanBlue = Color(0xFF0099CC);
  static const Color sunsetOrange = Color(0xFFFFB84D);
  static const Color outline = Color(0xFF6E7880);
  static const Color sandWhite = Color(0xFFF8FBFF);

  final Map<String, Map<String, double>> islandCoordinates = {
    'Agatti': {'lat': 10.8327, 'lng': 72.2067},
    'Kavaratti': {'lat': 10.5667, 'lng': 72.6333},
    'Minicoy': {'lat': 8.2856, 'lng': 73.0459},
    'Kalpeni': {'lat': 10.0692, 'lng': 73.6400},
    'Androth': {'lat': 10.8150, 'lng': 73.6800},
    'Bangaram': {'lat': 10.9100, 'lng': 72.2900},
    'Kadmat': {'lat': 11.2200, 'lng': 72.7800},
    'Kiltan': {'lat': 11.4800, 'lng': 72.9600},
    'Chetlat': {'lat': 11.7000, 'lng': 72.7000},
    'Bitra': {'lat': 11.5500, 'lng': 72.1500},
    'Amini': {'lat': 11.1300, 'lng': 72.7200},
  };

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadActivities();
    _checkWishlistStatus();
    _loadReviews();
  }

  Future<void> _checkWishlistStatus() async {
    final inWishlist = await WishlistService.isInWishlist(widget.productId);
    if (mounted) setState(() => _isBookmarked = inWishlist);
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final response = await ProductService.getProductById(widget.productId);
      if (response['success'] == true && mounted) {
        setState(() {
          _product = response['product'];
          _isLoading = false;
        });
        _calculateDistance();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print('❌ Error loading product: $e');
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final response = await ReviewService.getItemReviews(
        itemId: widget.productId,
        itemType: 'product',
        limit: 10,
      );
      if (response['success'] == true) {
        setState(() {
          _averageRating = (response['averageRating'] ?? 0).toDouble();
          _totalReviews = response['totalReviews'] ?? 0;
          _isLoadingReviews = false;
        });
      } else {
        setState(() {
          _averageRating = 0.0;
          _totalReviews = 0;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      setState(() {
        _averageRating = 0.0;
        _totalReviews = 0;
        _isLoadingReviews = false;
      });
      print('❌ Error loading reviews: $e');
    }
  }

  Future<void> _loadActivities() async {
    try {
      final response = await ActivityService.getActivities(limit: 3);
      if (response['success'] == true && mounted) {
        setState(() {
          _activities = response['activities'] ?? [];
        });
      }
    } catch (e) {
      print('❌ Error loading activities: $e');
    }
  }

  Future<void> _calculateDistance() async {
    if (_product == null) return;
    final location = _product!['location'] ?? '';
    String islandKey = '';
    for (var key in islandCoordinates.keys) {
      if (location.toLowerCase().contains(key.toLowerCase())) {
        islandKey = key;
        break;
      }
    }
    if (islandKey.isEmpty) islandKey = 'Agatti';
    final destLat = islandCoordinates[islandKey]!['lat']!;
    final destLon = islandCoordinates[islandKey]!['lng']!;
    setState(() => _isDistanceLoading = true);
    try {
      final result = await LocationService.getDistanceToDestination(
        destLat: destLat,
        destLon: destLon,
        destName: islandKey,
      );
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _distanceInKm = result['distance'] ?? 0;
            _distanceText = result['formattedDistance'] ?? '--';
            _fromLocation = result['fromLocation'] ?? 'Your Location';
          } else {
            _distanceText = '--';
          }
          _isDistanceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _distanceText = '--';
        _isDistanceLoading = false;
      });
      print('❌ Error calculating distance: $e');
    }
  }

  Future<void> _saveToWishlist() async {
    setState(() => _isSaving = true);
    try {
      if (_isBookmarked) {
        await WishlistService.removeFromWishlist(widget.productId);
        if (mounted) {
          setState(() {
            _isBookmarked = false;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Removed from wishlist'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
          );
        }
      } else {
        final product = _product!;
        await WishlistService.addToWishlist({
          'id': product['_id'],
          'name': product['name'],
          'location': product['location'],
          'price': product['price'],
          'images': product['images'],
          'type': 'product',
        });
        if (mounted) {
          setState(() {
            _isBookmarked = true;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Added to wishlist!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      print('❌ Error saving to wishlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _shareProduct() async {
    final product = _product!;
    final shareText = '''
🌊 SeaSoul - ${product['name'] ?? 'Amazing Package'}

📍 Location: ${product['location'] ?? 'Lakshadweep'}
📏 Distance: $_distanceText from $_fromLocation
⭐ Rating: ${_averageRating > 0 ? _averageRating.toStringAsFixed(1) : '0.0'} ★ (${_totalReviews} reviews)
💰 Price: ₹${product['price'] ?? 0} / person

${product['description'] ?? ''}

✨ Book now and experience the beauty of Lakshadweep!
📱 Download SeaSoul App: https://seasoul.com/download
''';
    try {
      await Share.share(shareText);
    } catch (e) {
      print('❌ Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectBookingDates() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 1))),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: oceanBlue,
              onPrimary: Colors.white,
              onSurface: deepNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _numberOfDays = picked.duration.inDays;
        if (_numberOfDays == 0) _numberOfDays = 1;
      });
    }
  }

  void _editReview(ReviewModel review) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewPage(
          bookingId: review.bookingId,
          productId: review.productId,
          activityId: review.activityId,
          itemName: review.itemName,
          itemType: review.itemType,
          existingReview: {
            '_id': review.id,
            'rating': review.rating,
            'title': review.title,
            'comment': review.comment,
          },
        ),
      ),
    );
    if (result == true) {
      _loadReviews();
      _loadProduct();
    }
  }

  void _deleteReview(ReviewModel review) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ReviewService.deleteReview(review.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Review deleted'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
                );
                _loadReviews();
                _loadProduct();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget buildNetworkImage(String imageUrl, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    final cleanUrl = ImageUtils.getCleanImageUrl(imageUrl);
    if (!ImageUtils.isValidImage(cleanUrl)) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
      );
    }
    return Image.network(
      cleanUrl,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: oceanBlue,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey, size: 30),
                SizedBox(height: 4),
                Text('Image not available', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: sandWhite,
        body: const Center(child: CircularProgressIndicator(color: oceanBlue)),
      );
    }
    if (_product == null) {
      return Scaffold(
        backgroundColor: sandWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: outline),
              const SizedBox(height: 16),
              const Text('Product not found', style: TextStyle(fontSize: 18, color: deepNavy)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: oceanBlue),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final images = product['images'] ?? [];
    final mainImage = images.isNotEmpty ? images[0] : 'https://via.placeholder.com/400x300';

    return Scaffold(
      backgroundColor: sandWhite,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(context, mainImage, product),
                _buildStatsMetricsSection(product),
                _buildDescriptionSection(product),
                _buildGallerySection(images),
                _buildReviewsSection(),
                _buildActivitiesSection(),
                const SizedBox(height: 140),
              ],
            ),
          ),
          _buildScreenHeaderOverlay(context),
          _buildStickyBookingFooter(product),
        ],
      ),
    );
  }

  Widget _buildScreenHeaderOverlay(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 20, right: 20, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(icon: Icons.arrow_back, onTap: () => Navigator.maybePop(context)),
                Row(
                  children: [
                    _buildGlassButton(
                      icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      iconColor: _isBookmarked ? sunsetOrange : deepNavy,
                      onTap: _saveToWishlist,
                      isLoading: _isSaving,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(icon: Icons.share_outlined, onTap: _shareProduct),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, Color iconColor = deepNavy, bool isLoading = false}) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: oceanBlue))
            : Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, String imageUrl, Map<String, dynamic> product) {
    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.58,
          width: double.infinity,
          child: buildNetworkImage(imageUrl, height: MediaQuery.of(context).size.height * 0.58, width: double.infinity),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.2), Colors.transparent, Colors.transparent, sandWhite],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: product['isFeatured'] == true ? sunsetOrange : oceanBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product['isFeatured'] == true ? 'FEATURED' : 'TRENDING DESTINATION',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(height: 10),
              Text(product['name'] ?? 'Product', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))])),
              Text(product['location'] ?? 'Location', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsMetricsSection(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: deepNavy.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  if (_isLoadingReviews)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: oceanBlue))
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StarRating(rating: _averageRating, size: 18),
                        const SizedBox(width: 6),
                        Text(_averageRating > 0 ? _averageRating.toStringAsFixed(1) : '0.0', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: deepNavy)),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(_totalReviews > 0 ? '$_totalReviews REVIEWS' : 'NO REVIEWS YET', style: TextStyle(fontSize: 10, color: outline.withOpacity(0.8), fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ],
              ),
            ),
            Container(height: 30, width: 1, color: outline.withOpacity(0.2)),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, color: oceanBlue, size: 18),
                      const SizedBox(width: 4),
                      if (_isDistanceLoading)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: oceanBlue))
                      else
                        Text(_distanceText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deepNavy)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('FROM ${_fromLocation.toUpperCase()}', style: TextStyle(fontSize: 10, color: outline.withOpacity(0.8), fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(Map<String, dynamic> product) {
    final price = (product['price'] ?? 0).toDouble();
    final totalPrice = _startDate != null && _endDate != null ? price * _numberOfDays : price;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product['name'] ?? 'Experience Serenity', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: deepNavy)),
          const SizedBox(height: 10),
          Text(product['description'] ?? 'No description available', style: const TextStyle(fontFamily: 'Inter', fontSize: 15, color: outline, height: 1.6)),
          const SizedBox(height: 24),

          // ---- ENHANCED DATE SELECTION CARD ----
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: oceanBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _startDate != null ? oceanBlue : Colors.grey.shade200, width: 1.5),
            ),
            child: InkWell(
              onTap: _selectBookingDates,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: _startDate != null ? oceanBlue : Colors.grey[400], size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _startDate != null
                                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                    : 'Select your travel dates',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _startDate != null ? deepNavy : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _startDate != null
                                    ? '$_numberOfDays ${_numberOfDays == 1 ? 'day' : 'days'} • ₹${totalPrice.toInt()} total'
                                    : 'Tap to choose check‑in and check‑out',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _startDate != null ? oceanBlue : Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: _startDate != null ? oceanBlue : Colors.grey[400], size: 16),
                      ],
                    ),
                    if (_startDate != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.currency_rupee, color: sunsetOrange, size: 20),
                            const SizedBox(width: 8),
                            Text('Total: ₹${totalPrice.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: deepNavy)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: oceanBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$_numberOfDays Days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: oceanBlue)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ---- PRICE PER DAY CARD ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sunsetOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sunsetOrange.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: sunsetOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PRICE PER DAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: outline, letterSpacing: 0.5)),
                      Text('₹${price.toInt()} / person', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deepNavy)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(List<dynamic> images) {
    if (images.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gallery', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: deepNavy)),
              TextButton(
                onPressed: () => _showGalleryDialog(images),
                child: const Text('View All', style: TextStyle(color: oceanBlue, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: images.length > 4 ? 4 : images.length,
            itemBuilder: (context, index) {
              final imageUrl = images[index];
              return GestureDetector(
                onTap: () => _showGalleryDialog(images, initialIndex: index),
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: buildNetworkImage(imageUrl, height: 150, width: 220),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showGalleryDialog(List<dynamic> images, {int initialIndex = 0}) {
    final pageController = PageController(initialPage: initialIndex);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gallery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: deepNavy)),
                    IconButton(icon: const Icon(Icons.close, color: deepNavy), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = images[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: buildNetworkImage(imageUrl, height: double.infinity, width: double.infinity, fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
              ),
              if (images.length > 1)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: index == 0 ? oceanBlue : Colors.grey[300], shape: BoxShape.circle),
                    )),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- REVIEWS SECTION ----
  Widget _buildReviewsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ReviewService.getItemReviews(itemId: widget.productId, itemType: 'product', limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: Text('Error loading reviews: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
          );
        }
        final data = snapshot.data;
        if (data == null || data['success'] != true) return const SizedBox.shrink();
        final reviewsList = data['reviews'] as List? ?? [];
        final reviews = reviewsList
            .where((r) => r is Map<String, dynamic>)
            .map((r) => ReviewModel.fromJson(r as Map<String, dynamic>))
            .toList();
        final averageRating = data['averageRating'] ?? 0;
        final totalReviews = data['totalReviews'] ?? 0;
        if (_averageRating != averageRating || _totalReviews != totalReviews) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _averageRating = averageRating.toDouble();
              _totalReviews = totalReviews;
            });
          });
        }
        if (reviews.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.rate_review, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('No reviews yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 4),
                Text('Be the first to review this package!', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: deepNavy)),
                  const Spacer(),
                  StarRating(rating: averageRating, size: 18),
                  const SizedBox(width: 8),
                  Text('($totalReviews)', style: const TextStyle(fontSize: 14, color: outline)),
                ],
              ),
              const SizedBox(height: 16),
              ...reviews.map((review) => ReviewCard(
                review: review,
                onHelpfulTap: () async {
                  try {
                    await ReviewService.toggleHelpful(review.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Marked as helpful'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
                    );
                    _loadReviews();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                },
                onEditTap: () => _editReview(review),
                onDeleteTap: () => _deleteReview(review),
              )),
            ],
          ),
        );
      },
    );
  }

  // ---- ACTIVITIES SECTION ----
  Widget _buildActivitiesSection() {
    if (_activities.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Things to Do', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: deepNavy)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length > 3 ? 3 : _activities.length,
            itemBuilder: (context, index) {
              final activity = _activities[index];
              final images = activity['images'] ?? [];
              final imageUrl = images.isNotEmpty ? images[0] : 'https://via.placeholder.com/300x200';
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityDetailsPage(activityId: activity['_id'])));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.6)),
                    boxShadow: [BoxShadow(color: deepNavy.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: buildNetworkImage(imageUrl, height: 72, width: 72),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activity['name'] ?? 'Activity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: deepNavy)),
                            Text(activity['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: outline)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 12, color: outline),
                                const SizedBox(width: 4),
                                Text(activity['duration'] ?? '2 hours', style: const TextStyle(fontSize: 12, color: outline)),
                                const SizedBox(width: 12),
                                const Icon(Icons.currency_rupee, size: 12, color: outline),
                                const SizedBox(width: 4),
                                Text('${activity['price'] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: oceanBlue)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: outline, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBookingFooter(Map<String, dynamic> product) {
    final price = (product['price'] ?? 0).toDouble();
    final images = product['images'] ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : '';
    final name = product['name'] ?? 'Package';
    final hasSelectedDates = _startDate != null && _endDate != null;
    final totalPrice = hasSelectedDates ? price * _numberOfDays : price;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.3))),
              boxShadow: [BoxShadow(color: deepNavy.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasSelectedDates ? 'TOTAL PRICE' : 'STARTING FROM',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: outline.withOpacity(0.8), letterSpacing: 0.5),
                    ),
                    RichText(
                      text: TextSpan(
                        text: '₹${hasSelectedDates ? totalPrice.toInt() : price.toInt()}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: deepNavy),
                        children: [
                          TextSpan(
                            text: hasSelectedDates ? ' /$_numberOfDays Days' : ' /Day',
                            style: const TextStyle(fontSize: 13, color: outline, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (!hasSelectedDates) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select booking dates first by tapping the calendar above.'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => payment(
                          productId: product['_id'],
                          itemName: name,
                          itemType: 'product',
                          amount: totalPrice,
                          itemImage: imageUrl,
                          duration: _numberOfDays,
                          selectedDate: _startDate,
                        ),
                      ),
                    ).then((_) => _loadReviews());
                  },
                  icon: const Icon(Icons.bolt, color: Colors.white, size: 18),
                  label: const Text('Book Experience', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006386),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}