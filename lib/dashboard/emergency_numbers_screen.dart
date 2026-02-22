import 'package:flutter/material.dart';
import 'package:nukkad/services/emergency_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyNumbersScreen extends StatefulWidget {
  const EmergencyNumbersScreen({super.key});

  @override
  State<EmergencyNumbersScreen> createState() => _EmergencyNumbersScreenState();
}

class _EmergencyNumbersScreenState extends State<EmergencyNumbersScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  List<Map<String, dynamic>> emergencyNumbers = [];
  String? selectedCategory;
  bool isLoading = true;

  final List<String> categories = ['All', 'police', 'medical', 'helpline', 'fire', 'emergency', 'information'];

  @override
  void initState() {
    super.initState();
    _loadEmergencyNumbers();
  }

  Future<void> _loadEmergencyNumbers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final numbers = await _emergencyService.getEmergencyNumbers(
        category: selectedCategory == 'All' ? null : selectedCategory,
      );
      setState(() {
        emergencyNumbers = numbers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _callNumber(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot call $phoneNumber')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Emergency Numbers"),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory ?? 'All',
              decoration: const InputDecoration(
                labelText: 'Filter by Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category[0].toUpperCase() + category.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
                _loadEmergencyNumbers();
              },
            ),
          ),

          // Emergency Numbers List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : emergencyNumbers.isEmpty
                    ? const Center(
                        child: Text("No emergency numbers found"),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: emergencyNumbers.length,
                        itemBuilder: (context, index) {
                          final number = emergencyNumbers[index];
                          final isPriority = number['priority'] == 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isPriority
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPriority ? Colors.red : Colors.grey.shade300,
                                width: isPriority ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isPriority
                                      ? Colors.red.withOpacity(0.2)
                                      : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getIconForCategory(number['category']),
                                  color: isPriority ? Colors.red : AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                number['service_name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: isPriority
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (number['description'] != null)
                                    Text(
                                      number['description'],
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    number['phone_number'] ?? '',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.phone, color: Colors.green),
                                onPressed: () => _callNumber(number['phone_number']),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category) {
      case 'police':
        return Icons.local_police;
      case 'medical':
        return Icons.medical_services;
      case 'fire':
        return Icons.fire_extinguisher;
      case 'helpline':
        return Icons.support_agent;
      case 'emergency':
        return Icons.warning;
      default:
        return Icons.phone;
    }
  }
}
