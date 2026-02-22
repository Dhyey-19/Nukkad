import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create or update business profile
  Future<Map<String, dynamic>?> createOrUpdateBusiness({
    required int userId,
    required String businessName,
    required String businessCategory,
    String? description,
    String? address,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? website,
    String? businessImage,
    Map<String, String>? openingHours,
  }) async {
    try {
      final userExists = await _supabase
          .from('nkd_users')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      if (userExists == null) {
        print(
          'Business create/update error: user not found for user_id=$userId',
        );
        return null;
      }

      // Check if business already exists
      final existing = await _supabase
          .from('nkd_businesses')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final businessData = {
        'user_id': userId,
        'business_name': businessName,
        'business_category': businessCategory,
        if (description != null) 'description': description,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        if (businessImage != null) 'business_image': businessImage,
        if (openingHours != null) 'opening_hours': openingHours,
      };

      if (existing != null) {
        // Update existing business
        final response = await _supabase
            .from('nkd_businesses')
            .update(businessData)
            .eq('business_id', existing['business_id'])
            .select()
            .single();
        return response;
      } else {
        // Create new business
        final response = await _supabase
            .from('nkd_businesses')
            .insert(businessData)
            .select()
            .single();

        // Create free subscription with 5 connects
        await _supabase.from('nkd_subscriptions').insert({
          'user_id': userId,
          'business_id': response['business_id'],
          'subscription_type': 'free',
          'connects_remaining': 5,
          'connects_total': 5,
        });

        return response;
      }
    } catch (e) {
      print('Business create/update error: $e');
      return null;
    }
  }

  // Get business by user ID
  Future<Map<String, dynamic>?> getBusinessByUserId(int userId) async {
    try {
      final response = await _supabase
          .from('nkd_businesses')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Get business error: $e');
      return null;
    }
  }

  // Get business by business ID (public view)
  Future<Map<String, dynamic>?> getBusinessById(int businessId) async {
    try {
      final response = await _supabase
          .from('nkd_businesses')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Get business by ID error: $e');
      return null;
    }
  }

  // Get nearby businesses
  Future<List<Map<String, dynamic>>> getNearbyBusinesses({
    double? latitude,
    double? longitude,
    double radiusKm = 10.0,
    String? category,
    int limit = 20,
    bool topRatedFirst = false,
  }) async {
    try {
      final baseQuery = _supabase
          .from('nkd_businesses')
          .select()
          .eq('is_active', true);

      var query = baseQuery;
      if (category != null && category != 'All') {
        query = query.eq('business_category', category);
      }

        final orderedQuery = topRatedFirst
          ? query.order('rating_average', ascending: false)
          : query;

        final int fetchLimit = (latitude != null && longitude != null)
          ? math.min(limit * 5, 200)
          : limit;
        final businesses = await orderedQuery.limit(fetchLimit);

      // If location provided, filter by distance
      if (latitude != null && longitude != null) {
        final List<Map<String, dynamic>> nearbyBusinesses = [];
        for (var business in businesses) {
          if (business['latitude'] != null && business['longitude'] != null) {
            final distance = _calculateDistance(
              latitude,
              longitude,
              business['latitude'].toDouble(),
              business['longitude'].toDouble(),
            );
            if (distance <= radiusKm) {
              business['distance_km'] = distance;
              nearbyBusinesses.add(business);
            }
          }
        }
        nearbyBusinesses.sort(
          (a, b) => (a['distance_km'] as double).compareTo(
            b['distance_km'] as double,
          ),
        );
        return nearbyBusinesses.take(limit).toList();
      }

      return List<Map<String, dynamic>>.from(businesses).take(limit).toList();
    } catch (e) {
      print('Get nearby businesses error: $e');
      return [];
    }
  }

  // Search businesses
  Future<List<Map<String, dynamic>>> searchBusinesses({
    String? query,
    String? category,
    String? city,
    int limit = 50,
  }) async {
    try {
      var searchQuery = _supabase
          .from('nkd_businesses')
          .select()
          .eq('is_active', true);

      if (category != null && category != 'All') {
        searchQuery = searchQuery.eq('business_category', category);
      }

      if (city != null && city.isNotEmpty) {
        searchQuery = searchQuery.ilike('city', '%$city%');
      }

      final businesses = await searchQuery.limit(limit);

      // Filter by search query if provided
      if (query != null && query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        return businesses.where((business) {
          final name = (business['business_name'] ?? '').toLowerCase();
          final desc = (business['description'] ?? '').toLowerCase();
          final cat = (business['business_category'] ?? '').toLowerCase();
          return name.contains(queryLower) ||
              desc.contains(queryLower) ||
              cat.contains(queryLower);
        }).toList();
      }

      return List<Map<String, dynamic>>.from(businesses);
    } catch (e) {
      print('Search businesses error: $e');
      return [];
    }
  }

  // Increment business views
  Future<void> incrementBusinessViews(int businessId) async {
    try {
      // Manual update (RPC function not available)
      final business = await _supabase
          .from('nkd_businesses')
          .select('total_views')
          .eq('business_id', businessId)
          .single();

      await _supabase
          .from('nkd_businesses')
          .update({'total_views': (business['total_views'] ?? 0) + 1})
          .eq('business_id', businessId);
    } catch (e) {
      print('Increment views error: $e');
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);
}
