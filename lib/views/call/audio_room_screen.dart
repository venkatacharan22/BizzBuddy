import 'package:flutter/material.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';
import 'dart:math' as math;

class AudioRoomScreen extends StatefulWidget {
  final Call audioRoomCall;

  const AudioRoomScreen({
    super.key,
    required this.audioRoomCall,
  });

  @override
  State<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends State<AudioRoomScreen> {
  late CallState _callState;
  bool _microphoneEnabled = false;

  @override
  void initState() {
    super.initState();
    _callState = widget.audioRoomCall.state.value;

    // Set up permission handler for audio requests
    widget.audioRoomCall.onPermissionRequest = (permissionRequest) {
      widget.audioRoomCall.grantPermissions(
        userId: permissionRequest.user.id,
        permissions: permissionRequest.permissions.toList(),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Room: ${_callState.callId}'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          onPressed: () async {
            await widget.audioRoomCall.leave();
            if (!mounted) return;
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.close),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _microphoneEnabled ? Colors.green : Colors.red,
        child: Icon(
          _microphoneEnabled ? Icons.mic : Icons.mic_off,
          color: Colors.white,
        ),
        onPressed: () async {
          try {
            if (_microphoneEnabled) {
              // Mute microphone
              await widget.audioRoomCall.setMicrophoneEnabled(enabled: false);
              setState(() {
                _microphoneEnabled = false;
              });
            } else {
              // Check if user has permission to talk
              if (!widget.audioRoomCall
                  .hasPermission(CallPermission.sendAudio)) {
                // Request permission to talk
                await widget.audioRoomCall.requestPermissions(
                  [CallPermission.sendAudio],
                );
              }
              // Unmute microphone
              await widget.audioRoomCall.setMicrophoneEnabled(enabled: true);
              setState(() {
                _microphoneEnabled = true;
              });
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Microphone error: $e')),
            );
          }
        },
      ),
      body: Column(
        children: [
          // Room info card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Call ID: ${_callState.callId}'),
                  const SizedBox(height: 4),
                  Text(
                      'Created: ${_callState.createdAt.toString().split('.')[0]}'),
                  const SizedBox(height: 4),
                  Text('Status: ${_callState.status.toString()}'),
                ],
              ),
            ),
          ),
          // Participants section title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Participants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Participants grid
          Expanded(
            child: StreamBuilder<CallState>(
              initialData: _callState,
              stream: widget.audioRoomCall.state.valueStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error loading participants'),
                  );
                }

                if (snapshot.hasData && !snapshot.hasError) {
                  final callState = snapshot.data!;

                  if (callState.callParticipants.isEmpty) {
                    return const Center(
                      child: Text('No participants in the room yet'),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                    ),
                    itemCount: callState.callParticipants.length,
                    itemBuilder: (context, index) {
                      final participant = callState.callParticipants[index];
                      return _buildParticipantTile(participant);
                    },
                  );
                }

                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(CallParticipantState participant) {
    // Get participant information
    const isActive = true; // Simplified - we'll assume everyone is active
    final name = participant.userId;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use participant's session ID directly
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Icon(
            isActive ? Icons.mic : Icons.mic_off,
            size: 16,
            color: isActive ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}
