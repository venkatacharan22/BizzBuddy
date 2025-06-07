import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/api_models.dart';
import '../../providers/video_call_provider.dart';
import '../../services/api_service.dart';
import 'audio_room_screen.dart';

class AudioRoomHome extends ConsumerStatefulWidget {
  const AudioRoomHome({super.key});

  @override
  ConsumerState<AudioRoomHome> createState() => _AudioRoomHomeState();
}

class _AudioRoomHomeState extends ConsumerState<AudioRoomHome> {
  final _roomIdController = TextEditingController();
  final _roomNameController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;
  String? _errorMessage;
  List<ApiRoom> _rooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final rooms = await apiService.getAudioRooms();

      if (mounted) {
        setState(() {
          _rooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load rooms: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createAudioRoom() async {
    if (_roomNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a room name';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      // First create the room via API
      final apiService = ref.read(apiServiceProvider);
      final room = await apiService.createAudioRoom(
        roomName: _roomNameController.text,
        settings: {'audio': true, 'video': false},
      );

      // Then create the Stream call
      final videoProvider = ref.read(videoCallProvider);
      await videoProvider.initialize();
      final call = await videoProvider.createAudioRoom(
        callId: room.streamCallId ?? room.id,
      );

      if (!mounted) return;

      // Navigate to audio room screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioRoomScreen(audioRoomCall: call),
        ),
      ).then((_) => _loadRooms());
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create audio room: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _joinAudioRoom(String roomId) async {
    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      // First join the room via API
      final apiService = ref.read(apiServiceProvider);
      final room = await apiService.joinAudioRoom(roomId);

      // Then join the Stream call
      final videoProvider = ref.read(videoCallProvider);
      await videoProvider.initialize();
      final call = await videoProvider.joinAudioRoom(
        room.streamCallId ?? roomId,
      );

      if (!mounted) return;

      // Navigate to audio room screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioRoomScreen(audioRoomCall: call),
        ),
      ).then((_) => _loadRooms());
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to join audio room: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Rooms'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRooms,
            tooltip: 'Refresh rooms',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading audio rooms...\nThis may take up to a minute',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Create room card
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Create an Audio Room',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _roomNameController,
                            decoration: const InputDecoration(
                              labelText: 'Room Name',
                              hintText: 'Enter a name for your room',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isCreating ? null : _createAudioRoom,
                            child: _isCreating
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Creating Room...'),
                                    ],
                                  )
                                : const Text('Create Audio Room'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Join room by ID card
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Join by Room ID',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _roomIdController,
                            decoration: const InputDecoration(
                              labelText: 'Room ID',
                              hintText: 'Enter a room ID to join',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isJoining
                                ? null
                                : () => _joinAudioRoom(_roomIdController.text),
                            child: _isJoining
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Joining Room...'),
                                    ],
                                  )
                                : const Text('Join Audio Room'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null)
                    Card(
                      color: Colors.red.shade100,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_errorMessage!),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                },
                                child: const Text('Dismiss'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Room list header
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Available Audio Rooms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Room list (scrollable)
                  Expanded(
                    child: _rooms.isEmpty
                        ? Center(
                            child: Text(
                              'No audio rooms available.\nCreate your first room!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _rooms.length,
                            itemBuilder: (context, index) {
                              final room = _rooms[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(room.roomName),
                                  subtitle: Text(
                                      'Host: ${room.hostName ?? "Unknown"} • ${room.participantCount} participants'),
                                  trailing: ElevatedButton(
                                    onPressed: _isJoining
                                        ? null
                                        : () => _joinAudioRoom(room.id),
                                    child: const Text('Join'),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
