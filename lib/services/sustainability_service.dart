import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sustainability.dart';
import '../models/sale.dart';
import '../models/product.dart';

class SustainabilityService {
  final Box<CarbonFootprint> _carbonFootprintBox;
  final Box<GreenBadge> _badgesBox;
  final Box<Sale> _salesBox;
  final Box<Product> _productsBox;
  Timer? _updateTimer;

  SustainabilityService({
    required Box<CarbonFootprint> carbonFootprintBox,
    required Box<GreenBadge> badgesBox,
    required Box<Sale> salesBox,
    required Box<Product> productsBox,
  })  : _carbonFootprintBox = carbonFootprintBox,
        _badgesBox = badgesBox,
        _salesBox = salesBox,
        _productsBox = productsBox {
    _startRealTimeUpdates();
  }

  void _startRealTimeUpdates() {
    // Update every 5 minutes
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      updateSustainabilityMetrics();
    });
  }

  Future<void> updateSustainabilityMetrics() async {
    final carbonFootprint = await _calculateCarbonFootprint();
    final badges = await _checkAndAwardBadges(carbonFootprint);

    // Update carbon footprint
    await _carbonFootprintBox.put('current', carbonFootprint);

    // Add new badges
    for (final badge in badges) {
      if (!_badgesBox.values.any((b) => b.id == badge.id)) {
        await _badgesBox.add(badge);
      }
    }
  }

  Future<CarbonFootprint> _calculateCarbonFootprint() async {
    double totalCarbonSaved = 0;
    final Map<String, double> categorySavings = {};

    // Calculate carbon savings from sales
    for (final sale in _salesBox.values) {
      final product = _productsBox.get(sale.productId);
      if (product != null) {
        // Example calculation - adjust based on your actual metrics
        final carbonSaved = sale.quantity * (product.carbonFootprint ?? 0);
        totalCarbonSaved += carbonSaved;

        // Update category savings
        categorySavings.update(
          product.category,
          (value) => (value + carbonSaved).toDouble(),
          ifAbsent: () => carbonSaved.toDouble(),
        );
      }
    }

    return CarbonFootprint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      totalCarbonSaved: totalCarbonSaved,
      categorySavings: categorySavings,
      lastUpdated: DateTime.now(),
    );
  }

  Future<List<GreenBadge>> _checkAndAwardBadges(
      CarbonFootprint footprint) async {
    final List<GreenBadge> newBadges = [];

    // Check for carbon savings milestones
    if (footprint.totalCarbonSaved >= 1000 && !_hasBadge('carbon_saver')) {
      newBadges.add(GreenBadge(
        id: 'carbon_saver',
        name: 'Carbon Saver',
        description: 'Saved over 1000kg of CO2 emissions',
        iconPath: 'carbon_saver',
        points: 100,
        earnedAt: DateTime.now(),
      ));
    }

    // Check for category-specific achievements
    for (final category in footprint.categorySavings.keys) {
      if (footprint.categorySavings[category]! >= 500 &&
          !_hasBadge('${category}_champion')) {
        newBadges.add(GreenBadge(
          id: '${category}_champion',
          name: '${category.capitalize()} Champion',
          description: 'Saved over 500kg of CO2 in $category category',
          iconPath: '${category}_champion',
          points: 50,
          earnedAt: DateTime.now(),
        ));
      }
    }

    return newBadges;
  }

  bool _hasBadge(String badgeId) {
    return _badgesBox.values.any((badge) => badge.id == badgeId);
  }

  void dispose() {
    _updateTimer?.cancel();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
