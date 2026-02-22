import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:nukkad/services/admin_service.dart';
import 'package:nukkad/services/analytics_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, int> counts = {};
  List<int> views = const [];
  List<int> calls = const [];
  List<int> directions = const [];
  List<int> shares = const [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final c = await _adminService.getCounts();
    final v = await _analyticsService.getDailyEventCounts(
      eventType: 'view',
      days: 7,
    );
    final cl = await _analyticsService.getDailyEventCounts(
      eventType: 'call',
      days: 7,
    );
    final dr = await _analyticsService.getDailyEventCounts(
      eventType: 'direction',
      days: 7,
    );
    final sh = await _analyticsService.getDailyEventCounts(
      eventType: 'share',
      days: 7,
    );

    setState(() {
      counts = c;
      views = v;
      calls = cl;
      directions = dr;
      shares = sh;
      isLoading = false;
    });
  }

  Future<void> _exportCsv() async {
    final start = DateTime.now().subtract(const Duration(days: 6));
    final rows = <List<String>>[
      ['Date', 'Views', 'Calls', 'Directions', 'Shares'],
    ];

    for (int i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      rows.add([
        DateFormat('yyyy-MM-dd').format(day),
        (i < views.length ? views[i] : 0).toString(),
        (i < calls.length ? calls[i] : 0).toString(),
        (i < directions.length ? directions[i] : 0).toString(),
        (i < shares.length ? shares[i] : 0).toString(),
      ]);
    }

    final csv = rows.map((r) => r.join(',')).join('\n');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/nukkad_admin_analytics.csv');
    await file.writeAsString(csv, flush: true);

    await Share.shareXFiles([
      XFile(file.path, mimeType: 'text/csv'),
    ], text: 'Nukkad Admin Analytics');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text('Admin Analytics'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportCsv,
              tooltip: 'Export CSV',
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _countsGrid(),
                    const SizedBox(height: 16),
                    _chartCard('Weekly Views', views, AppColors.primary),
                    const SizedBox(height: 16),
                    _chartCard('Weekly Calls', calls, Colors.green),
                    const SizedBox(height: 16),
                    _chartCard('Weekly Directions', directions, Colors.orange),
                    const SizedBox(height: 16),
                    _chartCard('Weekly Shares', shares, Colors.purple),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _countsGrid() {
    final items = [
      _countTile('Users', counts['users'] ?? 0, Icons.people),
      _countTile('Businesses', counts['businesses'] ?? 0, Icons.storefront),
      _countTile('Enquiries', counts['enquiries'] ?? 0, Icons.message),
      _countTile('Offers', counts['offers'] ?? 0, Icons.local_offer),
      _countTile('Reviews', counts['reviews'] ?? 0, Icons.star),
    ];

    return Wrap(spacing: 12, runSpacing: 12, children: items);
  }

  Widget _countTile(String label, int value, IconData icon) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(String title, List<int> data, Color color) {
    final maxValue = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (index) {
                  final y = data[index].toDouble();
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: y,
                        color: color,
                        width: 14,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
                maxY: (maxValue + 2).toDouble(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
