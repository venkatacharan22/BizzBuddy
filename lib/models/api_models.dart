import '../models/product.dart';
import '../models/sale.dart';

// Product model for API
class ApiProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;
  final String category;
  final String createdAt;
  final String updatedAt;
  final String? imageUrl;
  final Map<String, dynamic>? attributes;

  ApiProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.attributes,
  });

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      stockQuantity: json['stockQuantity'],
      category: json['category'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      imageUrl: json['imageUrl'],
      attributes: json['attributes'],
    );
  }

  // Convert API product to BizzyBuddy Product model
  Product toBizzyBuddyProduct() {
    return Product(
      id: id,
      name: name,
      price: price,
      quantity: int.tryParse(stockQuantity.toString()) ?? 0,
      category: category,
      description: description,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

// Sale model for API
class ApiSale {
  final String id;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String date;

  ApiSale({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.date,
  });

  factory ApiSale.fromJson(Map<String, dynamic> json) {
    return ApiSale(
      id: json['id'],
      productId: json['productId'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      date: json['date'],
    );
  }

  // Convert API sale to BizzyBuddy Sale model
  Sale toBizzyBuddySale() {
    return Sale(
      id: id,
      productId: productId,
      quantity: quantity,
      unitPrice: unitPrice,
      totalAmount: totalAmount,
      date: DateTime.parse(date),
      createdAt: DateTime.now(),
    );
  }
}

// Analytics model for API
class ApiAnalytics {
  final Map<String, dynamic> salesSummary;
  final Map<String, dynamic> topProducts;
  final List<Map<String, dynamic>> categoryPerformance;
  final Map<String, dynamic> revenueTrend;

  ApiAnalytics({
    required this.salesSummary,
    required this.topProducts,
    required this.categoryPerformance,
    required this.revenueTrend,
  });

  factory ApiAnalytics.fromJson(Map<String, dynamic> json) {
    return ApiAnalytics(
      salesSummary: json['salesSummary'],
      topProducts: json['topProducts'],
      categoryPerformance:
          List<Map<String, dynamic>>.from(json['categoryPerformance']),
      revenueTrend: json['revenueTrend'],
    );
  }
}

// Room model for API
class ApiRoom {
  final String id;
  final String roomName;
  final String host;
  final List<String> participants;
  final String? streamCallId;
  final Map<String, dynamic> settings;
  final String createdAt;
  final String updatedAt;

  ApiRoom({
    required this.id,
    required this.roomName,
    required this.host,
    required this.participants,
    this.streamCallId,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiRoom.fromJson(Map<String, dynamic> json) {
    return ApiRoom(
      id: json['id'] ?? json['_id'] ?? '',
      roomName: json['roomName'] ?? 'Unnamed Room',
      host: json['host'] is Map
          ? json['host']['userId'] ?? ''
          : json['host'] ?? '',
      participants: json['participants'] is List
          ? (json['participants'] as List).map((p) {
              if (p is Map) {
                return p['userId']?.toString() ?? '';
              }
              return p?.toString() ?? '';
            }).toList()
          : [],
      streamCallId: json['streamCallId'],
      settings: json['settings'] ?? {'audio': true, 'video': false},
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  // Get host name (if host is populated)
  String? get hostName {
    if (host is Map) {
      return (host as Map)['name'];
    }
    return null;
  }

  // Get participants count
  int get participantCount => participants.length;
}

// User model for API
class ApiUser {
  final String userId;
  final String name;
  final String email;
  final String role;
  final String token;
  final String streamToken;

  ApiUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    required this.streamToken,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      token: json['token'] ?? '',
      streamToken: json['streamToken'] ?? '',
    );
  }
}

// Call model for API
class ApiCall {
  final String callId;
  final String createdBy;
  final List<Map<String, dynamic>> participants;
  final String status;
  final String startedAt;
  final String? endedAt;
  final int? duration;

  ApiCall({
    required this.callId,
    required this.createdBy,
    required this.participants,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.duration,
  });

  factory ApiCall.fromJson(Map<String, dynamic> json) {
    return ApiCall(
      callId: json['callId'] ?? '',
      createdBy: json['createdBy'] ?? '',
      participants: json['participants'] != null
          ? List<Map<String, dynamic>>.from(json['participants'])
          : [],
      status: json['status'] ?? 'unknown',
      startedAt: json['startedAt'] ?? DateTime.now().toIso8601String(),
      endedAt: json['endedAt'],
      duration: json['duration'],
    );
  }
}
