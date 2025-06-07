import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'api_service.dart';
import '../models/api_models.dart';

class VideoCallService {
  final ApiService _apiService = ApiService();
  late StreamVideo _streamVideo;
  bool _isInitialized = false;

  // Initialize the Stream Video client with token from backend
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get current user data from backend
      debugPrint('Initializing video call service...');
      final ApiUser userData = await _apiService.getCurrentUser();
      debugPrint(
          'Got user data for ${userData.name} with ID ${userData.userId}');

      // Clean userId to ensure it's valid for Stream
      final userId = userData.userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      // Get fresh Stream token
      final tokenData = await _apiService.getStreamToken();
      final streamToken = tokenData['token'] as String;

      // Initialize Stream Video
      debugPrint('Creating StreamVideo instance with userId: $userId');
      try {
        _streamVideo = StreamVideo(
          const String.fromEnvironment('STREAM_API_KEY',
              defaultValue: 'kkggw6byahn8'), // Stream Video API key from env
          user: User.regular(
            userId: userId,
            role: userData.role,
            name: userData.name,
          ),
          userToken: streamToken,
        );
        debugPrint('StreamVideo instance created successfully');
      } catch (streamError) {
        debugPrint('Error creating StreamVideo instance: $streamError');
        debugPrint('Attempting to refresh token and retry...');

        // Try to get a fresh token
        final freshTokenData = await _apiService.getStreamToken();
        final freshToken = freshTokenData['token'] as String;

        _streamVideo = StreamVideo(
          const String.fromEnvironment('STREAM_API_KEY',
              defaultValue: 'kkggw6byahn8'),
          user: User.regular(
            userId: userId,
            role: userData.role,
            name: userData.name,
          ),
          userToken: freshToken,
        );
        debugPrint('Retry with fresh token successful');
      }

      _isInitialized = true;
      debugPrint('Video call service initialized');
    } catch (e, stackTrace) {
      debugPrint('Error initializing video call service: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to initialize video call service: $e');
    }
  }

  // Create a new call using our backend
  Future<Call> createCall() async {
    try {
      // Ensure we're initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Create call via backend API
      final callData = await _apiService.createCall();

      // Create local call instance using Stream Video SDK
      final call = _streamVideo.makeCall(
        callType: StreamCallType(),
        id: callData.callId,
      );

      // Connect to the call
      await call.getOrCreate();

      return call;
    } catch (e) {
      throw Exception('Failed to create call: $e');
    }
  }

  // Join an existing call
  Future<Call> joinCall(String callId) async {
    try {
      // Ensure we're initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Join call via backend API
      await _apiService.joinCall(callId);

      // Create local call instance
      final call = _streamVideo.makeCall(
        callType: StreamCallType(),
        id: callId,
      );

      // Connect to the call
      await call.getOrCreate();

      return call;
    } catch (e) {
      throw Exception('Failed to join call: $e');
    }
  }

  // Leave a call
  Future<void> leaveCall(Call call) async {
    try {
      // Leave call via backend API
      await _apiService.leaveCall(call.id.toString());

      // Disconnect from the call locally
      await call.leave();
    } catch (e) {
      throw Exception('Failed to leave call: $e');
    }
  }

  // End a call (only call creator or admin)
  Future<void> endCall(Call call) async {
    try {
      // End call via backend API
      await _apiService.endCall(call.id.toString());

      // End the call locally
      await call.end();
    } catch (e) {
      throw Exception('Failed to end call: $e');
    }
  }

  // Get call history
  Future<List<ApiCall>> getCallHistory() async {
    try {
      return await _apiService.getUserCalls();
    } catch (e) {
      throw Exception('Failed to fetch call history: $e');
    }
  }
}
