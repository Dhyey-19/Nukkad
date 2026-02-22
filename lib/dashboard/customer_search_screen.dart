import 'package:flutter/material.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/services/auth_service.dart';
import 'package:nukkad/dashboard/business_landing_page.dart';
import 'package:geolocator/geolocator.dart';

class CustomerSearchScreen extends StatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BusinessService _businessService = BusinessService();
  final AuthService _authService = AuthService();

  String _selectedCategory = 'All';
  String _selectedLocation = 'All locations';
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _categories = ['All'];
  bool isLoading = false;
  Position? _currentPosition;
  bool _locationDenied = false;

  final List<String> _locations = [
    'All locations',
    'Within 1km',
    'Within 2km',
    'Within 5km',
    'Within 10km',
    'Within 20km',
    'Within 50km',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
    _initLocation();
    _performSearch();
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
      _performSearch();
    } catch (_) {
      setState(() => _locationDenied = true);
    }
  }

  double _getRadiusKm() {
    switch (_selectedLocation) {
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
    return _selectedLocation != 'All locations';
  }

  Future<void> _loadCategories() async {
    final categories = await _authService.fetchBusinessCategories();
    setState(() {
      _categories = ['All', ...categories];
    });
  }

  void _onSearchChanged() {
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true;
    });

    try {
      final query = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();

      final radius = _getRadiusKm();

      List<Map<String, dynamic>> results;
      if (_currentPosition != null && _shouldFilterByDistance()) {
        results = await _businessService.getNearbyBusinesses(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusKm: radius,
          category: _selectedCategory == 'All' ? null : _selectedCategory,
          limit: 50,
        );

        if (query != null) {
          final queryLower = query.toLowerCase();
          results = results.where((business) {
            final name = (business['business_name'] ?? '').toLowerCase();
            final desc = (business['description'] ?? '').toLowerCase();
            final cat = (business['business_category'] ?? '').toLowerCase();
            return name.contains(queryLower) ||
                desc.contains(queryLower) ||
                cat.contains(queryLower);
          }).toList();
        }
      } else {
        results = await _businessService.searchBusinesses(
          query: query,
          category: _selectedCategory == 'All' ? null : _selectedCategory,
        );
      }

      setState(() {
        _searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Search',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: const [],
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search shops, services...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch();
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ),
            if (_locationDenied)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Location is off. Showing all businesses.",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Filters
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  // Category Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                        _performSearch();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Location Filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _locations.map((location) {
                        return DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                        });
                        _performSearch();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                  ? const Center(child: Text('No results found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final business = _searchResults[index];
                        final distance = business['distance_km'] != null
                            ? "${business['distance_km'].toStringAsFixed(1)} km"
                            : "Nearby";
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessLandingPage(
                                  businessId: business['business_id'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.storefront,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        business['business_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${business['business_category'] ?? 'Category'} • $distance',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
