import 'package:flutter/material.dart';
import 'package:nukkad/dashboard/business_landing_page.dart';
import 'package:nukkad/dashboard/customer_search_screen.dart';
import 'package:nukkad/services/auth_service.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:geolocator/geolocator.dart';

class CustomerExploreScreen extends StatefulWidget {
  final String? initialCategory;
  const CustomerExploreScreen({super.key, this.initialCategory});

  @override
  State<CustomerExploreScreen> createState() => _CustomerExploreScreenState();
}

class _CustomerExploreScreenState extends State<CustomerExploreScreen> {
  final AuthService _authService = AuthService();
  final BusinessService _businessService = BusinessService();

  bool isLoading = true;
  List<String> categories = [];
  List<Map<String, dynamic>> businesses = [];
  String? selectedCategory;
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

  final Map<String, IconData> _categoryIcons = const {
    'Grocery': Icons.local_grocery_store,
    'Medical': Icons.medical_services,
    'Salon': Icons.cut,
    'Repair': Icons.build,
    'Food': Icons.restaurant,
    'Restaurant': Icons.restaurant,
    'Electronics': Icons.devices,
    'Clothing': Icons.checkroom,
    'Education': Icons.school,
    'Automotive': Icons.directions_car,
    'Real Estate': Icons.home,
  };

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    _initLocation();
    _loadExplore();
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
      _loadExplore();
    } catch (_) {
      setState(() => _locationDenied = true);
    }
  }

  Future<void> _loadExplore() async {
    setState(() => isLoading = true);
    final cats = await _authService.fetchBusinessCategories();
    final biz = await _businessService.getNearbyBusinesses(
      limit: 50,
      category: selectedCategory,
      latitude: _shouldFilterByDistance()
          ? _currentPosition?.latitude
          : null,
      longitude: _shouldFilterByDistance()
          ? _currentPosition?.longitude
          : null,
      radiusKm: _getRadiusKm(),
    );
    setState(() {
      categories = cats;
      businesses = biz;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _loadExplore,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _searchBar(context),
                      if (_locationDenied) ...[
                        const SizedBox(height: 10),
                        _locationBanner(),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _sectionTitle("Browse Categories"),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: _distanceFilter(),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final label = index == 0 ? 'All' : categories[index - 1];
                      final isSelected =
                          selectedCategory == label ||
                          (selectedCategory == null && label == 'All');
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(label),
                        onSelected: (_) async {
                          setState(() {
                            selectedCategory = label == 'All' ? null : label;
                          });
                          await _loadExplore();
                        },
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: _sectionTitle("Explore Businesses"),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (businesses.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "No businesses found",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: businesses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _businessTile(businesses[index]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerSearchScreen()),
        );
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.black54),
            const SizedBox(width: 10),
            Text(
              "Search businesses, services",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const Spacer(),
            Icon(Icons.tune, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            initialValue: _selectedDistance,
            decoration: const InputDecoration(
              labelText: 'Distance',
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
                : (value) async {
                    if (value == null) return;
                    setState(() {
                      _selectedDistance = value;
                    });
                    await _loadExplore();
                  },
          ),
        ),
      ],
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

  Widget _businessTile(Map<String, dynamic> business) {
    final icon =
        _categoryIcons[business['business_category']] ?? Icons.storefront;
    final distance = business['distance_km'] != null
        ? "${business['distance_km'].toStringAsFixed(1)} km"
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business['business_name'] ?? 'Business',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business['business_category'] ?? '',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  if (distance != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      distance,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}
