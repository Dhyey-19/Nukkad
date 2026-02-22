import 'package:supabase_flutter/supabase_flutter.dart';

class SavedBusinessService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isSaved({required int customerId, required int businessId}) async {
    try {
      final row = await _supabase
          .from('nkd_saved_businesses')
          .select('saved_id')
          .eq('customer_id', customerId)
          .eq('business_id', businessId)
          .maybeSingle();
      return row != null;
    } catch (e) {
      print('Is saved error: $e');
      return false;
    }
  }

  Future<bool> saveBusiness({required int customerId, required int businessId}) async {
    try {
      await _supabase.from('nkd_saved_businesses').upsert({
        'customer_id': customerId,
        'business_id': businessId,
      }, onConflict: 'customer_id,business_id');
      return true;
    } catch (e) {
      print('Save business error: $e');
      return false;
    }
  }

  Future<bool> unsaveBusiness({required int customerId, required int businessId}) async {
    try {
      await _supabase
          .from('nkd_saved_businesses')
          .delete()
          .eq('customer_id', customerId)
          .eq('business_id', businessId);
      return true;
    } catch (e) {
      print('Unsave business error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedBusinesses({required int customerId}) async {
    try {
      final response = await _supabase
          .from('nkd_saved_businesses')
          .select('saved_id, created_at, nkd_businesses(*)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get saved businesses error: $e');
      return [];
    }
  }

  Future<int> getSavedCount({required int customerId}) async {
    try {
      final response = await _supabase
          .from('nkd_saved_businesses')
          .select('saved_id')
          .eq('customer_id', customerId);
      return (response as List).length;
    } catch (e) {
      print('Get saved count error: $e');
      return 0;
    }
  }
}

