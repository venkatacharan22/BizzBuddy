import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/sustainability.dart';
import '../../models/sale.dart';
import '../../models/product.dart';
import '../../services/sustainability_service.dart';
import 'package:flutter/material.dart';

final sustainabilityServiceProvider = Provider<SustainabilityService>((ref) {
  final carbonFootprintBox = Hive.box<CarbonFootprint>('carbon_footprint');
  final badgesBox = Hive.box<GreenBadge>('badges');
  final salesBox = Hive.box<Sale>('sales');
  final productsBox = Hive.box<Product>('products');

  return SustainabilityService(
    carbonFootprintBox: carbonFootprintBox,
    badgesBox: badgesBox,
    salesBox: salesBox,
    productsBox: productsBox,
  );
});

final carbonFootprintProvider = StreamProvider<CarbonFootprint?>((ref) {
  final service = ref.watch(sustainabilityServiceProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return Hive.box<CarbonFootprint>('carbon_footprint').get('current');
  });
});

final badgesProvider = StreamProvider<List<GreenBadge>>((ref) {
  final service = ref.watch(sustainabilityServiceProvider);
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return Hive.box<GreenBadge>('badges').values.toList();
  });
});

class SustainabilityProvider extends ChangeNotifier {
  bool _isLoading = false;
  double _carbonFootprint = 0.0;
  List<GreenBadge> _badges = [];

  bool get isLoading => _isLoading;
  double get carbonFootprint => _carbonFootprint;
  List<GreenBadge> get badges => _badges;

  Future<void> loadSustainabilityData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Load actual data from your data source
      // For now, using mock data
      _carbonFootprint = 150.5;
      _badges = [
        GreenBadge(
          id: 'carbon_saver_1',
          iconPath: 'carbon_saver',
          name: 'Carbon Saver',
          description: 'Reduced carbon footprint by 20%',
          points: 100,
          earnedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        GreenBadge(
          id: 'clothing_champion_1',
          iconPath: 'clothing_champion',
          name: 'Clothing Champion',
          description: 'Sold 100+ sustainable clothing items',
          points: 200,
          earnedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];
    } catch (e) {
      debugPrint('Error loading sustainability data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
