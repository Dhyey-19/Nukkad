import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all emergency numbers
  Future<List<Map<String, dynamic>>> getEmergencyNumbers({String? category}) async {
    try {
      var query = _supabase
          .from('nkd_emergency_numbers')
          .select()
          .eq('is_active', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query.order('priority', ascending: true).order('service_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get emergency numbers error: $e');
      return [];
    }
  }

  // Get emergency numbers by category
  Future<List<Map<String, dynamic>>> getEmergencyNumbersByCategory(String category) async {
    return getEmergencyNumbers(category: category);
  }
}
