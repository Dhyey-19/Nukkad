import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> logEvent({
    required int businessId,
    required String eventType,
    int? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.from('nkd_business_analytics').insert({
        'business_id': businessId,
        'event_type': eventType,
        if (userId != null) 'user_id': userId,
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      // Swallow analytics errors to avoid blocking UI flows.
      // ignore: avoid_print
      print('Analytics log error: $e');
    }
  }

  Future<List<int>> getDailyEventCounts({
    int? businessId,
    String eventType = 'view',
    int days = 7,
  }) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1));

      var query = _supabase
          .from('nkd_business_analytics')
          .select('created_at')
          .eq('event_type', eventType)
          .gte('created_at', start.toIso8601String());

      if (businessId != null) {
        query = query.eq('business_id', businessId);
      }

      final response = await query;

      final counts = List<int>.filled(days, 0);
      for (final row in response as List) {
        final createdAt = row['created_at'];
        if (createdAt == null) continue;
        final dt = DateTime.tryParse(createdAt.toString());
        if (dt == null) continue;
        final normalized = DateTime(dt.year, dt.month, dt.day);
        final index = normalized.difference(start).inDays;
        if (index >= 0 && index < days) {
          counts[index] += 1;
        }
      }
      return counts;
    } catch (e) {
      // ignore: avoid_print
      print('Analytics fetch error: $e');
      return List<int>.filled(days, 0);
    }
  }
}
