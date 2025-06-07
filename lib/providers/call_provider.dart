import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

final callsProvider =
    StateNotifierProvider<CallsNotifier, AsyncValue<List<ApiCall>>>((ref) {
  return CallsNotifier(ref.watch(apiServiceProvider));
});

class CallsNotifier extends StateNotifier<AsyncValue<List<ApiCall>>> {
  final ApiService _apiService;

  CallsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadCalls();
  }

  Future<void> loadCalls() async {
    try {
      state = const AsyncValue.loading();
      final calls = await _apiService.getUserCalls();
      state = AsyncValue.data(calls);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<ApiCall> createCall() async {
    try {
      final call = await _apiService.createCall();

      // Update state with new call
      state.whenData((calls) {
        state = AsyncValue.data([...calls, call]);
      });

      return call;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<ApiCall> joinCall(String callId) async {
    try {
      final call = await _apiService.joinCall(callId);

      // Update state with joined call
      state.whenData((calls) {
        final updatedCalls = calls.map((c) {
          if (c.callId == callId) {
            return call;
          }
          return c;
        }).toList();
        state = AsyncValue.data(updatedCalls);
      });

      return call;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<ApiCall> leaveCall(String callId) async {
    try {
      final call = await _apiService.leaveCall(callId);

      // Update state with left call
      state.whenData((calls) {
        final updatedCalls = calls.map((c) {
          if (c.callId == callId) {
            return call;
          }
          return c;
        }).toList();
        state = AsyncValue.data(updatedCalls);
      });

      return call;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<ApiCall> endCall(String callId) async {
    try {
      final call = await _apiService.endCall(callId);

      // Update state with ended call
      state.whenData((calls) {
        final updatedCalls = calls.map((c) {
          if (c.callId == callId) {
            return call;
          }
          return c;
        }).toList();
        state = AsyncValue.data(updatedCalls);
      });

      return call;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
