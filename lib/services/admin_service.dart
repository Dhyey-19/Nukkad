import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getBusinesses({
    bool? isVerified,
    bool? isActive,
  }) async {
    try {
      var query = _supabase.from('nkd_businesses').select();
      if (isVerified != null) {
        query = query.eq('is_verified', isVerified);
      }
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      // ignore: avoid_print
      print('Get businesses error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUsers({String? role}) async {
    try {
      var query = _supabase.from('nkd_users').select();
      if (role != null && role.isNotEmpty) {
        query = query.eq('role', role);
      }
      final data = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      // ignore: avoid_print
      print('Get users error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final data = await _supabase
          .from('business_categories')
          .select()
          .order('category_name');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      // ignore: avoid_print
      print('Get categories error: $e');
      return [];
    }
  }

  Future<bool> addCategory(String name) async {
    try {
      await _supabase.from('business_categories').insert({
        'category_name': name,
        'is_active': true,
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Add category error: $e');
      return false;
    }
  }

  Future<bool> updateCategory(
    int categoryId,
    String name,
    bool isActive,
  ) async {
    try {
      await _supabase
          .from('business_categories')
          .update({'category_name': name, 'is_active': isActive})
          .eq('category_id', categoryId);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Update category error: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    try {
      await _supabase
          .from('business_categories')
          .delete()
          .eq('category_id', categoryId);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Delete category error: $e');
      return false;
    }
  }

  Future<bool> updateBusinessStatus({
    required int businessId,
    bool? isVerified,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{
        if (isVerified != null) 'is_verified': isVerified,
        if (isActive != null) 'is_active': isActive,
      };
      if (data.isEmpty) return true;
      await _supabase
          .from('nkd_businesses')
          .update(data)
          .eq('business_id', businessId);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Update business status error: $e');
      return false;
    }
  }

  Future<bool> updateUserStatus({
    required int userId,
    required bool isActive,
  }) async {
    try {
      await _supabase
          .from('nkd_users')
          .update({'is_active': isActive})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Update user status error: $e');
      return false;
    }
  }

  Future<Map<String, int>> getCounts() async {
    try {
      final users = await _supabase.from('nkd_users').select('user_id');
      final businesses = await _supabase
          .from('nkd_businesses')
          .select('business_id');
      final enquiries = await _supabase
          .from('nkd_enquiries')
          .select('enquiry_id');
      final offers = await _supabase.from('nkd_offers').select('offer_id');
      final reviews = await _supabase.from('nkd_reviews').select('review_id');

      return {
        'users': (users as List).length,
        'businesses': (businesses as List).length,
        'enquiries': (enquiries as List).length,
        'offers': (offers as List).length,
        'reviews': (reviews as List).length,
      };
    } catch (e) {
      // ignore: avoid_print
      print('Get counts error: $e');
      return {
        'users': 0,
        'businesses': 0,
        'enquiries': 0,
        'offers': 0,
        'reviews': 0,
      };
    }
  }
}
