import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/video_call_provider.dart';
import '../../models/api_models.dart';
import 'call_screen.dart';

class VideoCallTestScreen extends ConsumerStatefulWidget {
  const VideoCallTestScreen({super.key});

  @override
  ConsumerState<VideoCallTestScreen> createState() =>
      _VideoCallTestScreenState();
}

class _VideoCallTestScreenState extends ConsumerState<VideoCallTestScreen> {
  final _callIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  List<ApiCall> _callHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  @override
  void dispose() {
    _callIdController.dispose();
    super.dispose();
  }

  Future<void> _loadCallHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _errorMessage = null;
    });

    try {
      final videoProvider = ref.read(videoCallProvider);
      await videoProvider.initialize();

      final history = await videoProvider.getCallHistory();

      if (mounted) {
        setState(() {
          _callHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load call history: $e';
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _createCall() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final videoProvider = ref.read(videoCallProvider);
      await videoProvider.initialize();

      final call = await videoProvider.createCall();

      if (!mounted) return;

      // Navigate to call screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(call: call),
        ),
      ).then((_) => _loadCallHistory());
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create call: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinCall() async {
    if (_callIdController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a call ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final videoProvider = ref.read(videoCallProvider);
      await videoProvider.initialize();

      final call =
          await videoProvider.joinCallById(_callIdController.text.trim());

      if (!mounted) return;

      // Navigate to call screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(call: call),
        ),
      ).then((_) => _loadCallHistory());
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to join call: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create call section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create a New Call',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createCall,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Call'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Join call section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Join Existing Call',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _callIdController,
                      decoration: const InputDecoration(
                        labelText: 'Call ID',
                        hintText: 'Enter the call ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _joinCall,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Join Call'),
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade900,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Call history section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Calls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingHistory)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _callHistory.isEmpty
                        ? const Center(
                            child: Text('No recent calls'),
                          )
                        : ListView.builder(
                            itemCount: _callHistory.length,
                            itemBuilder: (context, index) {
                              final call = _callHistory[index];
                              return Card(
                                child: ListTile(
                                  title: Text('Call ID: ${call.callId}'),
                                  subtitle: Text(
                                    'Status: ${call.status}\n'
                                    'Started: ${call.startedAt}',
                                  ),
                                  trailing: call.status == 'active'
                                      ? ElevatedButton(
                                          onPressed: () => _joinCall(),
                                          child: const Text('Join'),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
