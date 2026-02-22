import 'package:supabase_flutter/supabase_flutter.dart';

class OfferService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create offer
  Future<Map<String, dynamic>?> createOffer({
    required int businessId,
    required String offerTitle,
    String? offerDescription,
    required DateTime startDate,
    required DateTime endDate,
    double? discountPercentage,
    double? discountAmount,
    String? offerCode,
  }) async {
    try {
      final offer = await _supabase
          .from('nkd_offers')
          .insert({
            'business_id': businessId,
            'offer_title': offerTitle,
            if (offerDescription != null) 'offer_description': offerDescription,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            if (discountPercentage != null) 'discount_percentage': discountPercentage,
            if (discountAmount != null) 'discount_amount': discountAmount,
            if (offerCode != null) 'offer_code': offerCode,
            'is_active': true,
          })
          .select()
          .single();
      return offer;
    } catch (e) {
      print('Create offer error: $e');
      return null;
    }
  }

  // Get active offers for a business
  Future<List<Map<String, dynamic>>> getBusinessOffers(int businessId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('nkd_offers')
          .select()
          .eq('business_id', businessId)
          .eq('is_active', true)
          .gte('end_date', now)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get business offers error: $e');
      return [];
    }
  }

  // Get all active offers (for customers)
  Future<List<Map<String, dynamic>>> getActiveOffers({String? category, int? limit}) async {
    try {
      final now = DateTime.now().toIso8601String();
      var query = _supabase
          .from('nkd_offers')
          .select('*, nkd_businesses(*)')
          .eq('is_active', true)
          .gte('end_date', now)
          .order('created_at', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      
      List<Map<String, dynamic>> offers = List<Map<String, dynamic>>.from(response);
      
      // Filter by category if provided
      if (category != null && category != 'All') {
        offers = offers.where((offer) {
          final business = offer['nkd_businesses'];
          return business != null && business['business_category'] == category;
        }).toList();
      }

      return offers;
    } catch (e) {
      print('Get active offers error: $e');
      return [];
    }
  }

  // Update offer
  Future<bool> updateOffer(int offerId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('nkd_offers')
          .update(data)
          .eq('offer_id', offerId);
      return true;
    } catch (e) {
      print('Update offer error: $e');
      return false;
    }
  }

  // Delete/deactivate offer
  Future<bool> deleteOffer(int offerId) async {
    try {
      await _supabase
          .from('nkd_offers')
          .update({'is_active': false})
          .eq('offer_id', offerId);
      return true;
    } catch (e) {
      print('Delete offer error: $e');
      return false;
    }
  }
}
