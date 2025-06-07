import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import 'dart:async';

// Provider for the API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  // Auth state
  String? _authToken;
  Map<String, dynamic>? _currentUser;

  // HTTP client with extended timeout for slow connections
  final http.Client _client = http.Client();

  // Get the appropriate base URL based on platform
  String get baseUrl {
    // Use the Render deployed backend - or your own backend
    const String deployedUrl = 'https://bizzy-buddy-backend.onrender.com/api';

    // Return deployed URL
    return deployedUrl;
  }

  // Set the auth token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Set the current user
  void setCurrentUser(Map<String, dynamic> user) {
    _currentUser = user;
  }

  // Clear auth state
  void clearAuth() {
    _authToken = null;
    _currentUser = null;
  }

  // Headers
  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      // Use the stored token if available and none is provided
      if (token == null && _authToken != null)
        'Authorization': 'Bearer $_authToken',
    };
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = jsonDecode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    } else {
      final errorMessage = responseBody['message'] ?? 'Unknown error occurred';
      throw Exception(errorMessage);
    }
  }

  // Execute API call with timeout and retries
  Future<dynamic> _executeWithRetry({
    required Future<http.Response> Function() apiCall,
    int retries = 2,
    int timeoutSeconds = 60, // Extended timeout for slow API
  }) async {
    int attempts = 0;

    while (attempts <= retries) {
      attempts++;
      try {
        final responseCompleter = Completer<http.Response>();

        // Create timeout that completes with an exception
        final timeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
          if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(TimeoutException(
                'API request timed out after $timeoutSeconds seconds'));
          }
        });

        // Start API call
        apiCall().then((response) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(response);
          }
        }).catchError((error) {
          if (!responseCompleter.isCompleted) {
            responseCompleter.completeError(error);
          }
        });

        // Wait for either response or timeout
        final response = await responseCompleter.future;
        timeoutTimer.cancel();

        return _handleResponse(response);
      } catch (e) {
        debugPrint('API call attempt $attempts failed: $e');
        if (attempts > retries) {
          throw Exception('API call failed after $retries retries: $e');
        }
        // Wait before retrying
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    throw Exception('API call failed');
  }

  // Authentication Methods

  // Register a new user
  Future<ApiUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('Attempting to register user: $email');

    final userData = await _executeWithRetry(
      apiCall: () => _client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers(null),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ),
    );

    // Store auth state
    if (userData['token'] != null) {
      setAuthToken(userData['token'] as String);
      setCurrentUser(userData);
    }

    return ApiUser.fromJson(userData);
  }

  // Login a user
  Future<ApiUser> login({
    required String email,
    required String password,
  }) async {
    debugPrint('Attempting to login user: $email');

    final userData = await _executeWithRetry(
      apiCall: () => _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(null),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ),
    );

    // Store auth state
    if (userData['token'] != null) {
      setAuthToken(userData['token'] as String);
      setCurrentUser(userData);
    }

    return ApiUser.fromJson(userData);
  }

  // Validate token
  Future<bool> validateToken(String token) async {
    final responseData = await _executeWithRetry(
      apiCall: () => _client.post(
        Uri.parse('$baseUrl/auth/validate'),
        headers: _headers(token),
      ),
    );

    return responseData['valid'] ?? false;
  }

  // Get current user
  Future<ApiUser> getCurrentUser() async {
    debugPrint('Attempting to get current user from API...');

    final userData = await _executeWithRetry(
      apiCall: () => _client.get(
        Uri.parse('$baseUrl/auth/user'),
        headers: _headers(_authToken),
      ),
    );

    // Update stored user data
    setCurrentUser(userData);

    return ApiUser.fromJson(userData);
  }

  // User Management

  // Get all users
  Future<List<ApiUser>> getAllUsers() async {
    final responseData = await _executeWithRetry(
      apiCall: () => _client.get(
        Uri.parse('$baseUrl/users'),
        headers: _headers(_authToken),
      ),
    );

    return (responseData as List)
        .map((userData) => ApiUser.fromJson(userData))
        .toList();
  }

  // Audio Room Methods

  // Get all audio rooms
  Future<List<ApiRoom>> getAudioRooms() async {
    try {
      final responseData = await _executeWithRetry(
        apiCall: () => _client.get(
          Uri.parse('$baseUrl/audio-rooms'),
          headers: _headers(_authToken),
        ),
      );

      return (responseData as List)
          .map((roomData) => ApiRoom.fromJson(roomData))
          .toList();
    } catch (e) {
      debugPrint('Error getting audio rooms: $e');
      return [];
    }
  }

  // Create a new audio room
  Future<ApiRoom> createAudioRoom({
    String? roomName,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final roomData = await _executeWithRetry(
        apiCall: () => _client.post(
          Uri.parse('$baseUrl/audio-rooms'),
          headers: _headers(_authToken),
          body: jsonEncode({
            'roomName': roomName,
            'settings': settings ?? {'audio': true, 'video': false},
          }),
        ),
      );

      return ApiRoom.fromJson(roomData);
    } catch (e) {
      debugPrint('Error creating audio room: $e');
      throw Exception('Failed to create audio room: $e');
    }
  }

  // Get a specific audio room
  Future<ApiRoom> getAudioRoom(String roomId) async {
    try {
      final roomData = await _executeWithRetry(
        apiCall: () => _client.get(
          Uri.parse('$baseUrl/audio-rooms/$roomId'),
          headers: _headers(_authToken),
        ),
      );

      return ApiRoom.fromJson(roomData);
    } catch (e) {
      debugPrint('Error getting audio room: $e');
      throw Exception('Failed to get audio room: $e');
    }
  }

  // Join an audio room
  Future<ApiRoom> joinAudioRoom(String roomId) async {
    try {
      final roomData = await _executeWithRetry(
        apiCall: () => _client.post(
          Uri.parse('$baseUrl/audio-rooms/$roomId/join'),
          headers: _headers(_authToken),
        ),
      );

      return ApiRoom.fromJson(roomData);
    } catch (e) {
      debugPrint('Error joining audio room: $e');
      throw Exception('Failed to join audio room: $e');
    }
  }

  // Leave an audio room
  Future<Map<String, dynamic>> leaveAudioRoom(String roomId) async {
    try {
      return await _executeWithRetry(
        apiCall: () => _client.post(
          Uri.parse('$baseUrl/audio-rooms/$roomId/leave'),
          headers: _headers(_authToken),
        ),
      );
    } catch (e) {
      debugPrint('Error leaving audio room: $e');
      throw Exception('Failed to leave audio room: $e');
    }
  }

  // Call Management Methods

  // Create a new call
  Future<ApiCall> createCall() async {
    try {
      final callData = await _executeWithRetry(
        apiCall: () => _client.post(
          Uri.parse('$baseUrl/calls'),
          headers: _headers(_authToken),
        ),
      );

      return ApiCall.fromJson(callData);
    } catch (e) {
      debugPrint('Error creating call: $e');
      rethrow;
    }
  }

  // Join a call
  Future<ApiCall> joinCall(String callId) async {
    try {
      final callData = await _executeWithRetry(
        apiCall: () => _client.post(
          Uri.parse('$baseUrl/calls/$callId/join'),
          headers: _headers(_authToken),
        ),
      );

      return ApiCall.fromJson(callData);
    } catch (e) {
      debugPrint('Error joining call: $e');
      rethrow;
    }
  }

  // Leave a call
  Future<ApiCall> leaveCall(String callId) async {
    try {
      final callData = await _executeWithRetry(
        apiCall: () => _client.post(
          Uri.parse('$baseUrl/calls/$callId/leave'),
          headers: _headers(_authToken),
        ),
      );

      return ApiCall.fromJson(callData);
    } catch (e) {
      debugPrint('Error leaving call: $e');
      rethrow;
    }
  }

  // End a call
  Future<ApiCall> endCall(String callId) async {
    try {
      final callData = await _executeWithRetry(
        apiCall: () => _client.post(
          Uri.parse('$baseUrl/calls/$callId/end'),
          headers: _headers(_authToken),
        ),
      );

      return ApiCall.fromJson(callData);
    } catch (e) {
      debugPrint('Error ending call: $e');
      rethrow;
    }
  }

  // Get user's calls
  Future<List<ApiCall>> getUserCalls() async {
    try {
      final responseData = await _executeWithRetry(
        apiCall: () => _client.get(
          Uri.parse('$baseUrl/calls'),
          headers: _headers(_authToken),
        ),
      );

      return (responseData as List)
          .map((callData) => ApiCall.fromJson(callData))
          .toList();
    } catch (e) {
      debugPrint('Error getting user calls: $e');
      return [];
    }
  }

  // Get user data
  Future<Map<String, dynamic>> getUser(String token) async {
    debugPrint('Fetching user data with token');
    final response = await _client.get(
      Uri.parse('$baseUrl/user'),
      headers: _headers(token),
    );

    return _handleResponse(response);
  }

  // Refresh token
  Future<Map<String, dynamic>> refreshToken(String token) async {
    debugPrint('Refreshing token');
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: _headers(token),
    );

    return _handleResponse(response);
  }

  // Get tasks
  Future<List<Map<String, dynamic>>> getTasks() async {
    debugPrint('Fetching tasks');
    final response = await _client.get(
      Uri.parse('$baseUrl/tasks'),
      headers: _headers(_authToken),
    );

    final result = _handleResponse(response);
    return List<Map<String, dynamic>>.from(result['data'] ?? []);
  }

  // Get sales data
  Future<Map<String, dynamic>> getSales({String period = 'week'}) async {
    debugPrint('Fetching sales data for period: $period');
    final response = await _client.get(
      Uri.parse('$baseUrl/sales?period=$period'),
      headers: _headers(_authToken),
    );

    return _handleResponse(response);
  }

  // Get a fresh Stream token
  Future<Map<String, dynamic>> getStreamToken() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/stream/token'),
      headers: _headers(_authToken),
    );

    return _handleResponse(response);
  }

  // Audio Room Methods (Additional)

  // Get room details
  Future<ApiRoom> getRoomDetails(String roomId) async {
    try {
      final roomData = await _executeWithRetry(
        apiCall: () => _client.get(
          Uri.parse('$baseUrl/audio-rooms/$roomId'),
          headers: _headers(_authToken),
        ),
      );

      return ApiRoom.fromJson(roomData);
    } catch (e) {
      debugPrint('Error getting room details: $e');
      rethrow;
    }
  }

  // Join room
  Future<ApiRoom> joinRoom(String roomId) async {
    try {
      final roomData = await _executeWithRetry(
        apiCall: () => _client.post(
          Uri.parse('$baseUrl/audio-rooms/$roomId/join'),
          headers: _headers(_authToken),
        ),
      );

      return ApiRoom.fromJson(roomData);
    } catch (e) {
      debugPrint('Error joining room: $e');
      rethrow;
    }
  }

  // Leave room
  Future<ApiRoom> leaveRoom(String roomId) async {
    try {
      final roomData = await _executeWithRetry(
        apiCall: () => _client.post(
          Uri.parse('$baseUrl/audio-rooms/$roomId/leave'),
          headers: _headers(_authToken),
        ),
      );

      return ApiRoom.fromJson(roomData);
    } catch (e) {
      debugPrint('Error leaving room: $e');
      rethrow;
    }
  }

  // Error handling interceptor
  void _handleError(dynamic error) {
    if (error is http.ClientException) {
      throw Exception('Network error: ${error.message}');
    } else if (error is TimeoutException) {
      throw Exception('Request timed out');
    } else if (error is FormatException) {
      throw Exception('Invalid response format');
    } else {
      throw Exception('An unexpected error occurred: $error');
    }
  }

  // Token refresh logic
  Future<void> _refreshToken() async {
    try {
      if (_authToken == null) return;

      final response = await _client.post(
        Uri.parse('$baseUrl/auth/validate'),
        headers: _headers(_authToken),
      );

      if (response.statusCode == 401) {
        // Token is invalid, clear auth state
        clearAuth();
        throw Exception('Session expired. Please login again.');
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      rethrow;
    }
  }

  // Dispose method
  void dispose() {
    _client.close();
  }
}
