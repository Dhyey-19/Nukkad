import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Signup function
  Future<bool> signup({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
    String? businessName,
    String? businessCategory,
  }) async {
    try {
      final existing = await _supabase
          .from('nkd_users')
          .select('user_id')
          .eq('phone', phone)
          .maybeSingle();
      if (existing != null) {
        return false;
      }

      final hashedPassword = _hashPassword(password);

      await _supabase.from('nkd_users').insert({
        'full_name': fullName,
        'phone': phone,
        'password': hashedPassword,
        'role': role,
        if (email != null) 'email': email,
        if (businessName != null) 'business_name': businessName,
        if (businessCategory != null) 'business_category': businessCategory,
      });

      // If insert succeeds, return true
      return true;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

  Future<bool> isPhoneRegistered(String phone) async {
    try {
      final existing = await _supabase
          .from('nkd_users')
          .select('user_id')
          .eq('phone', phone)
          .maybeSingle();
      return existing != null;
    } catch (e) {
      print('Phone check error: $e');
      return false;
    }
  }

  // Login function
  Future<Map<String, dynamic>?> login(String phone, String password) async {
    try {
      final hashedPassword = _hashPassword(password);

      final response = await _supabase
          .from('nkd_users')
          .select()
          .eq('phone', phone)
          .eq('password', hashedPassword)
          .eq('is_active', true)
          .single();

      return response;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Fetch business categories
  Future<List<String>> fetchBusinessCategories() async {
    try {
      final response = await _supabase
          .from('business_categories')
          .select('category_name')
          .order('category_name');

      return (response as List).map((item) => item['category_name'] as String).toList();
    } catch (e) {
      print('Fetch categories error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      final response = await _supabase.from('nkd_users').select().eq('user_id', userId).single();
      return response;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  Future<bool> updateUser({
    required int userId,
    String? fullName,
    String? email,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final data = <String, dynamic>{
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (profileImage != null) 'profile_image': profileImage,
      };
      if (data.isEmpty) return true;
      await _supabase.from('nkd_users').update(data).eq('user_id', userId);
      return true;
    } catch (e) {
      print('Update user error: $e');
      return false;
    }
  }

  Future<bool> resetPasswordByPhone({
    required String phone,
    required String newPassword,
  }) async {
    try {
      final existing = await _supabase
          .from('nkd_users')
          .select('user_id')
          .eq('phone', phone)
          .eq('is_active', true)
          .maybeSingle();

      if (existing == null) {
        return false;
      }

      final hashedPassword = _hashPassword(newPassword);
      await _supabase
          .from('nkd_users')
          .update({'password': hashedPassword})
          .eq('user_id', existing['user_id']);
      return true;
    } catch (e) {
      print('Reset password error: $e');
      return false;
    }
  }
}