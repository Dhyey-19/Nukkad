import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getBusinessReviews(int businessId,
      {int limit = 20}) async {
    try {
      final data = await _supabase
          .from('nkd_reviews')
          .select('review_id, rating, review_text, created_at, nkd_users!inner(full_name)')
          .eq('business_id', businessId)
          .eq('is_visible', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Get business reviews error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserReview({
    required int businessId,
    required int customerId,
  }) async {
    try {
      final review = await _supabase
          .from('nkd_reviews')
          .select()
          .eq('business_id', businessId)
          .eq('customer_id', customerId)
          .maybeSingle();
      return review;
    } catch (e) {
      print('Get user review error: $e');
      return null;
    }
  }

  Future<bool> upsertReview({
    required int businessId,
    required int customerId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      await _supabase.from('nkd_reviews').upsert({
        'business_id': businessId,
        'customer_id': customerId,
        'rating': rating,
        'review_text': reviewText,
      });
      return true;
    } catch (e) {
      print('Upsert review error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerReviews({
    required int customerId,
    int limit = 50,
  }) async {
    try {
      final data = await _supabase
          .from('nkd_reviews')
          .select(
              'review_id, rating, review_text, created_at, nkd_businesses!inner(business_id, business_name, business_category)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Get customer reviews error: $e');
      return [];
    }
  }
}

