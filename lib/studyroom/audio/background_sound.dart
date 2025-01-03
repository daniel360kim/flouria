import 'package:studybeats/api/audio/objects.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import 'volumebar.dart';
import 'package:studybeats/api/audio/sfx_service.dart';

class BackgroundSoundControl extends StatefulWidget {
  const BackgroundSoundControl(
      {required this.id, required this.initialPosition, super.key});

  final int id;
  final Offset initialPosition;

  @override
  State<BackgroundSoundControl> createState() => _BackgroundSoundControlState();
}

class _BackgroundSoundControlState extends State<BackgroundSoundControl>
    with WidgetsBindingObserver {
  late Offset _offset;
  bool _selected = false;
  bool _loading = true;

  final _player = AudioPlayer();

  final _sfxService = SfxService();

  BackgroundSound? backgroundSound;

  Future<void> _loadBackgroundSoundControl() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });

    backgroundSound = await _sfxService.getBackgroundSoundInfo(widget.id);
    final audioUrl = await _sfxService.getBackgroundSoundUrl(backgroundSound!);

    // Define two overlapping audio sources
    final firstSource = ClippingAudioSource(
        child: AudioSource.uri(Uri.parse(audioUrl)),
        // Optionally adjust the start and end times if necessary
        start: const Duration(seconds: 2),
        end: Duration(seconds: backgroundSound!.durationMs ~/ 1000 - 2));

    // Use a concatenating audio source to play both sources with seamless overlay
    await _player.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          firstSource,
        ],
      ),
    );

    _player.setLoopMode(LoopMode.all); // Repeat the combined sources seamlessly

    // Mark loading as complete
    setState(() {
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _offset = widget.initialPosition;
    _loadBackgroundSoundControl();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: _offset.dx,
          top: _offset.dy,
          child: Draggable(
            feedback: Container(),
            onDragUpdate: (details) {
              setState(() {
                _offset = Offset(
                  _offset.dx + details.delta.dx,
                  _offset.dy + details.delta.dy,
                );
              });
            },
            onDraggableCanceled: (velocity, offset) {
              setState(() {
                _offset = offset;
              });
            },
            child: Column(
              children: [
                _loading
                    ? const ShimmerLoadingWidget() // Replace this with your shimmer or loading widget
                    : Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: _selected
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            IconData(
                              backgroundSound!.iconId,
                              fontFamily: backgroundSound!.fontFamily,
                            ),
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _selected ? _player.pause() : play();
                            setState(() {
                              _selected = !_selected;
                            });
                          },
                        ),
                      ),
                if (_selected && !_loading) const SizedBox(height: 5),
                if (_selected && !_loading) buildControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildControls() {
    return Container(
      height: 150,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          VolumeBar(
              initialVolume: 50,
              onChanged: (volume) {
                setVolume(volume / 100);
              })
        ],
      ),
    );
  }

  Future<void> play() async {
    await _player.setVolume(0.5);
    await _player.play();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }
}

class ShimmerLoadingWidget extends StatelessWidget {
  const ShimmerLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }
}
