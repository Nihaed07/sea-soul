import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seasoul/ui/payment.dart';

class explore_details extends StatefulWidget {
  const explore_details({super.key});

  @override
  State<explore_details> createState() => _explore_detailsState();
}

class _explore_detailsState extends State<explore_details> {
  bool _isBookmarked = false;
  int _durationDays = 1;
  DateTime _selectedDate = DateTime.now();

  static const Color deepNavy = Color(0xFF1A2B49);
  static const Color oceanBlue = Color(0xFF0099CC);
  static const Color sunsetOrange = Color(0xFFFFB84D);
  static const Color turquoiseLagoon = Color(0xFF00C2A8);
  static const Color outline = Color(0xFF6E7880);
  static const Color sandWhite = Color(0xFFF8FBFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandWhite,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(context),
                _buildStatsMetricsSection(),
                _buildDescriptionSection(),
                _buildGallerySection(),
                _buildActivitiesSection(),
                _buildBookingOptions(),
                const SizedBox(height: 140),
              ],
            ),
          ),

          _buildScreenHeaderOverlay(context),

          _buildStickyBookingFooter(),
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
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.maybePop(context),
                ),
                _buildGlassButton(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  iconColor: _isBookmarked ? sunsetOrange : deepNavy,
                  onTap: () {
                    setState(() {
                      _isBookmarked = !_isBookmarked;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = deepNavy,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.58,
          width: double.infinity,
          child: Image.network(
            'https://lh3.googleusercontent.com/aida/AP1WRLt2y33Z66ANWQN3wdIY-gA7A2ihkPj6ZbSyX-eEMH7sEEmD7VGuPzs6rKmtwl9rdmiDGUDgQ474uzRWA5QgSQ1dpYNKKN6X8r5tvAVnbCtKVRzwmPRAooWmn_ixEb9ptjiwAEBb_DK6B0kBXzZ8j0JfOdfKVhnvR6fkYGPIPnfHLo_cEaQWtQduQ8Xqov6w48MT2T_pK4LU6QnHfZ3LSVoG4CprET7GQpCYmDoQ7l3ddiGbNnCAX1HBhUg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                  Colors.transparent,
                  sandWhite,
                ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sunsetOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'TRENDING DESTINATION',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Agatti Island',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const Text(
                'The Gateway to Lakshadweep',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsMetricsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: deepNavy.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: sunsetOrange, size: 18),
                      SizedBox(width: 4),
                      Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: deepNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '1.2K REVIEWS',
                    style: TextStyle(
                      fontSize: 10,
                      color: outline.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 30, width: 1, color: outline.withOpacity(0.2)),
            Expanded(
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore_outlined, color: oceanBlue, size: 18),
                      SizedBox(width: 4),
                      Text(
                        '459 km',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: deepNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'FROM KOCHI',
                    style: TextStyle(
                      fontSize: 10,
                      color: outline.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Experience Serenity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: deepNavy,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Agatti is home to one of the most beautiful lagoons in Lakshadweep. It is the only island with an airport, making it the primary entry point for your tropical adventure. Imagine waking up to the sound of turquoise waves gently lapping against powdery white shores.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: outline,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              _buildBentoHighlightTile(
                Icons.water,
                'Crystal Lagoons',
                const Color(0xFF006386),
              ),
              const SizedBox(width: 12),
              _buildBentoHighlightTile(
                Icons.flight,
                'Airport Access',
                sunsetOrange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBentoHighlightTile(
                Icons.scuba_diving,
                'Scuba Diving',
                turquoiseLagoon,
              ),
              const SizedBox(width: 12),
              _buildBentoHighlightTile(
                Icons.wb_sunny_outlined,
                'White Sands',
                deepNavy,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoHighlightTile(
    IconData icon,
    String label,
    Color themeColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: themeColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallerySection() {
    final images = [
      'https://lh3.googleusercontent.com/aida/AP1WRLt20vciU-DA9lBsvsuQgx7qVZW0LGWa72plRjrGgh_N4IAAM2CvbBtgt8AYy_RzbdPddr9c_oHUxWLGXf1oslXQTxoUK53egIuHGzfzfoJLHUvUZOO3Zr0mBRsLd9m9SNR9gdSoYfygBuijNpsqmW6nIDsETR58aL6dliAclWr_PWOpNRlQ9HVM673MXjiluOCf_ijixaAoIbxB4dq4h1vgyUoDwD0TwVuWoxYjgglYwV0gCinYzE0hMlI',
      'https://lh3.googleusercontent.com/aida/AP1WRLubK1JSEmgW6yI9BvR54JfsiWAGrLYvxobJyDurYrLBzIA39XSmaWiuT5FoEAf4CbA1yidL4XOQkfwhcMBOfLVCxFfZEvuAlTa-EJ1aTUvcDFz4ciRkwZij1Oh1p3SO3mTo3gf8U008c2wN9-Ab9uhYAESPQC4yMCzRB_G_H10Mmwds2GL6WroYU3H3ec8fKpYWD_3ndLzFxY5ZCx_OdQd6Ion5BmgbTVik9o40_ULZXSndKfXLb3KgBw',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Island Gallery',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: deepNavy,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: oceanBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: images.length + 1,
            itemBuilder: (context, index) {
              if (index < images.length) {
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(images[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }
              return Container(
                width: 160,
                decoration: BoxDecoration(
                  color: oceanBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: oceanBlue.withOpacity(0.15),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '+15 More Photos',
                    style: TextStyle(
                      color: deepNavy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesSection() {
    final activities = [
      {
        'title': 'Scuba Diving',
        'desc': 'Explore vibrant coral reefs',
        'price': '₹4,500',
        'img':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAULHWXBhocdKOR5d13w2PGJ0YY3sITinvpLvAUPK0kcz_uhv7CO7ucpOT5X246tYXF0inoMQh1JNqbZtiGA6mj3JZGh_8ZzJgVm-gmcUZY5a0NcV8HHOkTwgh7RqEzi7L0X153RQJFYqjBGYukBnJaZz3WmltXErW_e9v5pqv8EI1WunjhEGzzvqgSmmM-1pyhJdOm4Ki9K7IE3i3QrRFHGZwDX-vDUUeLYxOHLbzQK2Mn1qcXje115Gc3uuLu1-OFDwmgBJEPXLc',
      },
      {
        'title': 'Snorkeling',
        'desc': 'Witness the shallow reef magic',
        'price': '₹1,500',
        'img':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAPRzcQ-yf-OHY1YQ66DRPfRnr00UjodzqA6xBaNkQX2tbKCj-FGALeOyu1jY8hyO3YMogBpJQ44cAOD-2eq7AIPtBvJtZsqADMF8Z2ddJuPJP3aeUuu9e958ofzXWVfjJ4NGjWPlB82-oaywimrkrXi23AbFyh07Tvbs0TG172bENcJmuiR87xhj67VpK0Uhr3TKbOgM14m_evfadBikJIJGpBdP1CAtLzLS6_zt6TMfSwGDXMuW8eBZBKNOlO0IRwT6XBQUXS5UU',
      },
      {
        'title': 'Island Hopping',
        'desc': 'Visit nearby uninhabited islets',
        'price': '₹3,200',
        'img':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBPTjpQ9oImtDnikS3td-DR9h2T7FSdIzhyi9tt-SuqBXUZnXutL01szZAw-T9MF0C9IsrqTHAL4HwLIO8drergzWklDJHcAzA96CzXJ-hzdcMCyU3skSCOyXRLoVqqGh94Vi5gDQvv9g4s3z3IvSkv3fHuGNlk4p8Cnb0tH6v0rU4nFN0bh7A-6fUMMiq0o6MNGLgK6ULnRLD_Rw8MCFtSANlPzwhqKvrZhZGC5y2W8y5Spqny2d5Vi0iMN58M4SutbwrOUJx49oY',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Things to Do',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: deepNavy,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final act = activities[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: deepNavy.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(act['img']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act['title']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: deepNavy,
                            ),
                          ),
                          Text(
                            act['desc']!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: outline,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Starting ${act['price']!}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: oceanBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: outline, size: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingOptions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: deepNavy,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: deepNavy.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Check-in Date', style: TextStyle(color: outline, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: oceanBlue),
                            const SizedBox(width: 8),
                            Text(
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: deepNavy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: deepNavy.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Duration', style: TextStyle(color: outline, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_durationDays > 1) {
                                setState(() => _durationDays--);
                              }
                            },
                            child: const Icon(Icons.remove_circle_outline, color: oceanBlue),
                          ),
                          Text(
                            '$_durationDays Days',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: deepNavy),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() => _durationDays++);
                            },
                            child: const Icon(Icons.add_circle_outline, color: oceanBlue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBookingFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              boxShadow: [
                BoxShadow(
                  color: deepNavy.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'STARTING FROM',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: outline.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: '₹${(12500 * _durationDays).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: deepNavy,
                        ),
                        children: [
                          TextSpan(
                            text: ' / $_durationDays Days',
                            style: const TextStyle(
                              fontSize: 13,
                              color: outline,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => payment(
                          amount: (12500 * _durationDays).toDouble(),
                          itemName: 'Agatti Island',
                          itemType: 'product',
                          duration: _durationDays,
                          selectedDate: _selectedDate,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bolt, color: Colors.white, size: 18),
                  label: const Text(
                    'Book Experience',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006386),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
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
