import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get subscription for user
  Future<Map<String, dynamic>?> getSubscription(int userId) async {
    try {
      final response = await _supabase
          .from('nkd_subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Get subscription error: $e');
      return null;
    }
  }

  // Create yearly subscription (365 Rs)
  Future<Map<String, dynamic>?> createYearlySubscription({
    required int userId,
    required int businessId,
    required String transactionId,
  }) async {
    try {
      // Deactivate existing subscriptions
      await _supabase
          .from('nkd_subscriptions')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('is_active', true);

      // Create new yearly subscription
      final endDate = DateTime.now().add(const Duration(days: 365));
      final subscription = await _supabase
          .from('nkd_subscriptions')
          .insert({
            'user_id': userId,
            'business_id': businessId,
            'subscription_type': 'yearly',
            'payment_amount': 365.00,
            'payment_status': 'completed',
            'payment_date': DateTime.now().toIso8601String(),
            'payment_transaction_id': transactionId,
            'connects_remaining': 999999, // Unlimited for yearly
            'connects_total': 999999,
            'is_active': true,
            'end_date': endDate.toIso8601String(),
          })
          .select()
          .single();

      // Create notification
      await _supabase.from('nkd_notifications').insert({
        'user_id': userId,
        'title': 'Subscription Activated',
        'message': 'Your yearly subscription is now active! You have unlimited connects.',
        'type': 'subscription',
        'related_id': subscription['subscription_id'],
      });

      return subscription;
    } catch (e) {
      print('Create yearly subscription error: $e');
      return null;
    }
  }

  // Check if user has connects remaining
  Future<bool> hasConnectsRemaining(int userId) async {
    try {
      final subscription = await getSubscription(userId);
      if (subscription == null) return false;
      
      // Yearly subscriptions have unlimited connects
      if (subscription['subscription_type'] == 'yearly') {
        return true;
      }
      
      return (subscription['connects_remaining'] ?? 0) > 0;
    } catch (e) {
      print('Check connects error: $e');
      return false;
    }
  }

  // Get remaining connects
  Future<int> getRemainingConnects(int userId) async {
    try {
      final subscription = await getSubscription(userId);
      if (subscription == null) return 0;
      
      if (subscription['subscription_type'] == 'yearly') {
        return 999999; // Unlimited
      }
      
      return subscription['connects_remaining'] ?? 0;
    } catch (e) {
      print('Get remaining connects error: $e');
      return 0;
    }
  }
}
