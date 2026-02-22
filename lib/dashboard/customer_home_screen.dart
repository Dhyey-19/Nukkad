import 'package:flutter/material.dart';
import 'package:nukkad/dashboard/customer_search_screen.dart';
import 'package:nukkad/dashboard/business_landing_page.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/services/offer_service.dart';
import 'package:nukkad/services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nukkad/dashboard/customer_explore_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final BusinessService _businessService = BusinessService();
  final OfferService _offerService = OfferService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> nearbyBusinesses = [];
  List<Map<String, dynamic>> _topRatedBusinesses = [];
  List<Map<String, dynamic>> offers = [];
  List<String> categories = [];
  bool isLoading = true;
  Position? _currentPosition;
  bool _locationDenied = false;
  String _selectedDistance = 'All locations';

  final List<String> _distanceOptions = [
    'All locations',
    'Within 1km',
    'Within 2km',
    'Within 5km',
    'Within 10km',
    'Within 20km',
    'Within 50km',
  ];

  double _getRadiusKm() {
    switch (_selectedDistance) {
      case 'Within 1km':
        return 1.0;
      case 'Within 2km':
        return 2.0;
      case 'Within 5km':
        return 5.0;
      case 'Within 10km':
        return 10.0;
      case 'Within 20km':
        return 20.0;
      case 'Within 50km':
        return 50.0;
      default:
        return 10.0;
    }
  }

  bool _shouldFilterByDistance() {
    if (_locationDenied || _currentPosition == null) return false;
    return _selectedDistance != 'All locations';
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadData();
  }

  Future<void> _initLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _locationDenied = true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationDenied = true);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _locationDenied = false;
      });
      _loadData();
    } catch (_) {
      setState(() => _locationDenied = true);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load nearby businesses
      final businesses = await _businessService.getNearbyBusinesses(
        limit: 10,
        latitude: _shouldFilterByDistance()
            ? _currentPosition?.latitude
            : null,
        longitude: _shouldFilterByDistance()
            ? _currentPosition?.longitude
            : null,
        radiusKm: _getRadiusKm(),
      );
      // Top rated near you (reuse same service ordered by rating)
      final topRated = await _businessService.getNearbyBusinesses(
        limit: 10,
        topRatedFirst: true,
        latitude: _shouldFilterByDistance()
            ? _currentPosition?.latitude
            : null,
        longitude: _shouldFilterByDistance()
            ? _currentPosition?.longitude
            : null,
        radiusKm: _getRadiusKm(),
      );
      // Load active offers
      final activeOffers = await _offerService.getActiveOffers(limit: 5);

      // Load categories
      final cats = await _authService.fetchBusinessCategories();

      setState(() {
        nearbyBusinesses = businesses;
        _topRatedBusinesses = topRated;
        offers = activeOffers;
        categories = cats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(context),
              if (_locationDenied) ...[
                const SizedBox(height: 10),
                _locationBanner(),
              ],
              const SizedBox(height: 24),

              _sectionTitle("Nearby Businesses"),
              const SizedBox(height: 8),
              _distanceFilter(),
              const SizedBox(height: 12),
              _nearbyBusinesses(),

              const SizedBox(height: 24),
              _sectionTitle("Popular Categories"),
              const SizedBox(height: 12),
              _categories(),

              const SizedBox(height: 24),
              _sectionTitle("Trending Near You"),
              const SizedBox(height: 12),
              _trendingShops(),

              const SizedBox(height: 24),
              _sectionTitle("Top Rated Near You"),
              const SizedBox(height: 12),
              _topRatedSection(),

              const SizedBox(height: 24),
              _sectionTitle("Offers From Nearby Shops"),
              const SizedBox(height: 12),
              _offers(),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= SEARCH BAR =================
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerSearchScreen()),
        );
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.black87),
            const SizedBox(width: 12),

            const Expanded(
              child: Text(
                "Search shops, services...",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Location is off. Showing businesses without distance.",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _distanceFilter() {
    return Row(
      children: [
        const Icon(Icons.place, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedDistance,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: _distanceOptions.map((label) {
              return DropdownMenuItem(
                value: label,
                child: Text(label),
              );
            }).toList(),
            onChanged: _locationDenied
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedDistance = value;
                    });
                    _loadData();
                  },
          ),
        ),
      ],
    );
  }

  /// ================= SECTION TITLE =================
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  /// ================= NEARBY BUSINESSES =================
  Widget _nearbyBusinesses() {
    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (nearbyBusinesses.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text("No nearby businesses found")),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nearbyBusinesses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final business = nearbyBusinesses[index];
          final distance = business['distance_km'] != null
              ? "${business['distance_km'].toStringAsFixed(1)} km"
              : "Nearby";
          return _businessCard(business, distance);
        },
      ),
    );
  }

  Widget _businessCard(Map<String, dynamic> business, String distance) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BusinessLandingPage(businessId: business['business_id']),
          ),
        );
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront,
                size: 24,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              business['business_name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              distance,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= CATEGORIES =================
  Widget _categories() {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 90,
        child: Center(child: Text("No categories available")),
      );
    }

    final categoryIcons = {
      'Grocery': Icons.local_grocery_store,
      'Medical': Icons.medical_services,
      'Salon': Icons.cut,
      'Repair': Icons.build,
      'Food': Icons.restaurant,
      'Restaurant': Icons.restaurant,
      'Electronics': Icons.devices,
      'Clothing': Icons.checkroom,
    };

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final category = categories[index];
          final icon = categoryIcons[category] ?? Icons.storefront;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerExploreScreen(initialCategory: category),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 60,
                  child: Text(
                    category,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ================= TRENDING =================
  Widget _trendingShops() {
    if (nearbyBusinesses.isEmpty) {
      return const SizedBox(
        height: 45,
        child: Center(child: Text("No trending yet")),
      );
    }

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nearbyBusinesses.length > 10 ? 10 : nearbyBusinesses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final business = nearbyBusinesses[index];
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BusinessLandingPage(businessId: business['business_id']),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  business['business_name'] ?? 'Business',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ================= TOP RATED =================
  Widget _topRatedSection() {
    if (isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_topRatedBusinesses.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text("No top-rated businesses yet")),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _topRatedBusinesses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final biz = _topRatedBusinesses[index];
          final rating = biz['rating_average'] ?? 0;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BusinessLandingPage(businessId: biz['business_id']),
                ),
              );
            },
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    biz['business_name'] ?? 'Business',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    biz['business_category'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${biz['total_reviews'] ?? 0})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// ================= OFFERS =================
  Widget _offers() {
    if (offers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No offers available"),
      );
    }

    return Column(
      children: offers.map((offer) {
        final business = offer['nkd_businesses'];
        final businessName = business != null
            ? business['business_name']
            : 'Business';
        return GestureDetector(
          onTap: () {
            if (business != null && business['business_id'] != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BusinessLandingPage(businessId: business['business_id']),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer['offer_title'] ?? 'Special Offer',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (businessName != null)
                        Text(
                          'From $businessName',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
