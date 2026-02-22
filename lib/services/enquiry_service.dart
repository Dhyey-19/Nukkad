import 'package:supabase_flutter/supabase_flutter.dart';

class EnquiryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create enquiry
  Future<Map<String, dynamic>?> createEnquiry({
    required int customerId,
    required int businessId,
    required String enquiryTitle,
    required String enquiryMessage,
    String? enquiryType,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) async {
    try {
      // Get customer details if not provided
      if (customerName == null || customerPhone == null) {
        final customer = await _supabase
            .from('nkd_users')
            .select('full_name, phone, email')
            .eq('user_id', customerId)
            .single();
        
        customerName ??= customer['full_name'];
        customerPhone ??= customer['phone'];
        customerEmail ??= customer['email'];
      }

      final enquiry = await _supabase
          .from('nkd_enquiries')
          .insert({
            'customer_id': customerId,
            'business_id': businessId,
            'enquiry_title': enquiryTitle,
            'enquiry_message': enquiryMessage,
            'enquiry_type': enquiryType ?? 'general',
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'customer_email': customerEmail,
            'status': 'pending',
          })
          .select()
          .single();

      // Increment business enquiry count
      try {
        final business = await _supabase
            .from('nkd_businesses')
            .select('total_enquiries')
            .eq('business_id', businessId)
            .single();
        
        await _supabase
            .from('nkd_businesses')
            .update({'total_enquiries': (business['total_enquiries'] ?? 0) + 1})
            .eq('business_id', businessId);
      } catch (e) {
        print('Increment enquiries error: $e');
      }

      // Create notification for business owner
      final business = await _supabase
          .from('nkd_businesses')
          .select('user_id')
          .eq('business_id', businessId)
          .single();

      await _supabase.from('nkd_notifications').insert({
        'user_id': business['user_id'],
        'title': 'New Enquiry Received',
        'message': '$customerName sent you an enquiry: $enquiryTitle',
        'type': 'enquiry',
        'related_id': enquiry['enquiry_id'],
      });

      return enquiry;
    } catch (e) {
      print('Create enquiry error: $e');
      return null;
    }
  }

  // Get enquiries for a business
  Future<List<Map<String, dynamic>>> getBusinessEnquiries(int businessId) async {
    try {
      final response = await _supabase
          .from('nkd_enquiries')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get business enquiries error: $e');
      return [];
    }
  }

  // Get enquiries for a customer
  Future<List<Map<String, dynamic>>> getCustomerEnquiries(int customerId) async {
    try {
      final response = await _supabase
          .from('nkd_enquiries')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get customer enquiries error: $e');
      return [];
    }
  }

  // Update enquiry status
  Future<bool> updateEnquiryStatus(int enquiryId, String status, {String? responseMessage}) async {
    try {
      final updateData = {
        'status': status,
        if (responseMessage != null) 'response_message': responseMessage,
        if (responseMessage != null) 'response_date': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('nkd_enquiries')
          .update(updateData)
          .eq('enquiry_id', enquiryId);
      return true;
    } catch (e) {
      print('Update enquiry status error: $e');
      return false;
    }
  }

  // Mark enquiry as read
  Future<bool> markEnquiryAsRead(int enquiryId) async {
    try {
      await _supabase
          .from('nkd_enquiries')
          .update({'is_read': true})
          .eq('enquiry_id', enquiryId);
      return true;
    } catch (e) {
      print('Mark enquiry as read error: $e');
      return false;
    }
  }

  // Delete enquiry
  Future<bool> deleteEnquiry({required int enquiryId, int? businessId}) async {
    try {
      var query = _supabase.from('nkd_enquiries').delete().eq('enquiry_id', enquiryId);
      if (businessId != null) {
        query = query.eq('business_id', businessId);
      }
      await query;
      return true;
    } on PostgrestException catch (e) {
      print('Delete enquiry error: ${e.message}');
      return false;
    } catch (e) {
      print('Delete enquiry error: $e');
      return false;
    }
  }
}
