import 'dart:ui';

import 'package:flourish_web/studyroom/audio/objects.dart';
import 'package:flourish_web/studyroom/audio/audio.dart';
import 'package:flourish_web/studyroom/audio/seekbar.dart';
import 'package:flourish_web/studyroom/studytools/scene.dart';
import 'package:flourish_web/studyroom/widgets/controls/playlist_controls.dart';
import 'package:flourish_web/studyroom/widgets/controls/scene_controls.dart';
import 'package:flourish_web/studyroom/widgets/controls/songinfo.dart';
import 'package:flourish_web/studyroom/widgets/controls/volume.dart';
import 'package:flourish_web/studyroom/widgets/screens/aichat/aichat.dart';
import 'package:flourish_web/studyroom/widgets/screens/equalizer.dart';
import 'package:flourish_web/studyroom/widgets/screens/queue.dart';
import 'package:flourish_web/studyroom/widgets/screens/scene_select.dart';
import 'package:flourish_web/studyroom/widgets/screens/songcredits.dart';
import 'package:flourish_web/studyroom/widgets/screens/timer.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'widgets/controls/music_controls.dart';

class Player extends StatefulWidget {
  const Player({
    required this.playlistId,
    required this.scenes,
    required this.onShowTimer,
    super.key,
  });

  final int playlistId;
  final List<StudyScene> scenes;
  final ValueChanged<PomodoroDurations> onShowTimer;

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> with WidgetsBindingObserver {
  late final Audio _audio;

  Song currentSongInfo = const Song(
    id: 0,
    name: 'Loading...',
    artist: 'Loading...',
    duration: 0,
    link: 'Loading...',
    songPath: '',
    thumbnailPath: '',
    waveformPath: '',
  );

  SongCloudInfo currentCloudSongInfo = const SongCloudInfo(
    isFavorite: false,
    timesPlayed: 0,
    totalPlaytime: Duration.zero,
    averagePlaytime: Duration.zero,
  );

  List<Song> songQueue = [];

  bool verticalLayout = false;

  bool _showQueue = false;
  bool _showSongInfo = false;
  bool _showEqualizer = false;

  bool _showSceneSelection = false;
  bool _showTimerSelection = false;
  bool _showAiChat = true;

  @override
  void initState() {
    super.initState();

    _audio = Audio(playlistId: widget.playlistId);

    _audio.initPlayer();
    _audio.isLoaded.addListener(() {
      if (_audio.isLoaded.value) {
        updateSong();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _audio.audioPlayer.play();
    } else {
      _audio.audioPlayer.pause();
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void updateSong() async {
    setState(() {
      currentSongInfo = _audio.getCurrentSongInfo();
      songQueue = _audio.getSongOrder();
    });

    _audio.getCurrentSongCloudInfo().then((value) {
      setState(() {
        currentCloudSongInfo = value;
      });
    });
  }

  void updateSongWithIndex(int newIndex) async {}

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _showSceneSelection
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: SceneSelector(
                        song: currentSongInfo,
                        scenes: widget.scenes,
                      ),
                    )
                  : const SizedBox.shrink(),
              _showTimerSelection
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: PomodoroTimer(
                        onStartPressed: (value) {
                          widget.onShowTimer(value);
                          // Unselect the timer icon on the control bar
                          SceneControls(
                            onChatPressed: (value) {},
                            onScreneSelectPressed: (value) {},
                            onTimerPressed: (value) {},
                          ).handleTimerPressed(_sceneControlsKey);
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
              _showAiChat
                  ? const Align(
                      alignment: Alignment.bottomLeft,
                      child: AiChat(),
                    )
                  : const SizedBox.shrink(),
              if (_showQueue || _showSongInfo || _showEqualizer) const Spacer(),
              _showQueue
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: SongQueue(
                        currentSong: currentSongInfo,
                        queue: songQueue,
                        onSongSelected: (index) {
                          _audio.play();
                          _audio.seekToIndex(index).then((value) {
                            updateSong();
                          });
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
              _showSongInfo
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: SongCredits(
                        song: currentSongInfo,
                      ),
                    )
                  : const SizedBox.shrink(),
              _showEqualizer
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: StreamBuilder<PositionData>(
                          stream: _audio.positionDataStream,
                          builder: (context, snapshot) {
                            final elapsedDuration =
                                snapshot.data?.position ?? Duration.zero;
                            return EqualizerControls(
                              song: currentSongInfo,
                              elapsedDuration: elapsedDuration,
                              onSpeedChange: (value) => _audio.setSpeed(value),
                            );
                          }),
                    )
                  : const SizedBox.shrink(),
            ]),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 20.0),
            width: MediaQuery.of(context).size.width,
            height: verticalLayout ? 300 : 80,
            child: Stack(
              children: [
                buildBackdrop(),
                buildControls(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBackdrop() {
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20.0));

    if (_showQueue || _showSongInfo || _showEqualizer) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(20.0),
        bottomLeft: Radius.circular(20.0),
        bottomRight: Radius.circular(20.0),
      );
    }
    if (_showSceneSelection || _showTimerSelection || _showAiChat) {
      borderRadius = const BorderRadius.only(
        topRight: Radius.circular(20.0),
        bottomLeft: Radius.circular(20.0),
        bottomRight: Radius.circular(20.0),
      );
    }

    if (!_showQueue &&
        !_showSongInfo &&
        !_showEqualizer &&
        !_showSceneSelection &&
        !_showTimerSelection &&
        !_showAiChat) {
      borderRadius = const BorderRadius.all(Radius.circular(20.0));
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: Colors.white.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget buildControls() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 1000) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buildControlWidgets(),
        );
      } else {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buildControlWidgets(),
        );
      }
    });
  }

  final GlobalKey<SceneControlsState> _sceneControlsKey =
      GlobalKey<SceneControlsState>();

  List<Widget> buildControlWidgets() {
    return [
      SceneControls(
          key: _sceneControlsKey,
          onScreneSelectPressed: (value) {
            setState(() {
              _showSceneSelection = value;
            });
          },
          onChatPressed: (value) {
            setState(() {
              _showAiChat = value;
            });
          },
          onTimerPressed: (value) {
            setState(() {
              _showTimerSelection = value;
            });
          }),
      StreamBuilder<PlayerState>(
        stream: _audio.audioPlayer.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final playing = playerState?.playing;
          if (playing != null) {
            return Controls(
              onShuffle: () {
                _audio.shuffle();
                updateSong();
              },
              onPrevious: _previousSong,
              onPlay: _audio.play,
              onPause: _audio.pause,
              onNext: _nextSong,
              onFavorite: (value) {
                _toggleFavorite(value);
              },
              isPlaying: playing,
              isFavorite: currentCloudSongInfo.isFavorite,
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
      SongInfo(
        song: currentSongInfo,
        positionData: _audio.positionDataStream,
        onSeekRequested: (newPosition) => _audio.seek(newPosition),
      ),
      VolumeSlider(
        volumeChanged: (volume) => _audio.setVolume(volume),
      ),
      IconControls(
        onInfoPressed: (enabled) {
          setState(() {
            _showSongInfo = enabled;
          });
        },
        onListPressed: (enabled) {
          setState(() {
            _showQueue = enabled;
          });
        },
        onEqualizerPressed: (enabled) {
          setState(() {
            _showEqualizer = enabled;
          });
        },
      ),
    ];
  }

  void _toggleFavorite(bool isFavorite) async {
    setState(() {
      currentCloudSongInfo =
          currentCloudSongInfo.copyWith(isFavorite: isFavorite);
    });

    try {
      await _audio.setFavorite(isFavorite);
    } catch (e) {
      // TODO implement proper ui error handling
      // Revert the optimistic update if the backend operation fails
      setState(() {
        currentCloudSongInfo =
            currentCloudSongInfo.copyWith(isFavorite: !isFavorite);
      });
    }
  }

  void _nextSong() async {
    setState(() {
      currentSongInfo = _audio.getNextSongInfo();
    });

    try {
      await _audio.nextSong();
      setState(() async {
        currentCloudSongInfo = await _audio.getCurrentSongCloudInfo();
      });
    } catch (e) {
      // TODO implement proper error handling within the ui
      // TODO detect if the exception was caused by the songcloudinfo API call
      // or if it from the nextSong api call

      // if it is from the nextSong method, no need to do anything because
      // the index w/in the _audio class will have alr been updated
      // but if the cloudSong api call fails we need to figure out what to do then
    }
  }

  void _previousSong() async {
    setState(() {
      currentSongInfo = _audio.getPreviousSongInfo();
    });

    try {
      await _audio.previousSong();
      setState(() async {
        currentCloudSongInfo = await _audio.getCurrentSongCloudInfo();
      });
    } catch (e) {
      // TODO implement proper error handling within the ui
      // TODO detect if the exception was caused by the songcloudinfo API call
      // or if it from the previousSong api call

      // if it is from the previousSong method, no need to do anything because
      // the index w/in the _audio class will have alr been updated
      // but if the cloudSong api call fails we need to figure out what to do then
    }
  }
}
