import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as ypi;

import '../constants/colors.dart';
import '../models/frame_options.dart';
import '../models/search_options.dart';
import '../services/video_service.dart';
import '../widgets/retro_ui.dart';

class YoutubePage extends StatefulWidget {
  final Map<String, String> initialVideo;
  final SearchOptions searchOptions;

  const YoutubePage({
    super.key,
    required this.initialVideo,
    required this.searchOptions,
  });

  @override
  State<YoutubePage> createState() => _YoutubePageState();
}

class _YoutubePageState extends State<YoutubePage> {
  late Map<String, String> currentVideo;
  late SearchOptions searchOptions;
  late ypf.YoutubePlayerController mobileController;
  late ypi.YoutubePlayerController webController;

  final _videoService = VideoService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, String>> playedVideos = [];
  final Set<String> playedVideoIds = {};

  int currentChannelIndex = 0;
  int volume = 50;
  bool handledEndPlay = false;
  bool isAccountMenuOpen = false;
  bool isFindingNext = false;
  DisplayMode selectedMode = DisplayMode.normal;

  final channels = const [
    {
      'title': 'Lo-fi',
      'keyword': 'lofi hip hop radio',
      'icon': Icons.music_note,
    },
    {'title': 'News', 'keyword': 'live news', 'icon': Icons.public},
    {
      'title': 'Gaming',
      'keyword': 'live gaming stream',
      'icon': Icons.sports_esports,
    },
    {'title': 'Nature', 'keyword': 'nature live cam', 'icon': Icons.landscape},
    {'title': 'Podcasts', 'keyword': 'live podcast', 'icon': Icons.mic},
    {'title': 'Throwbacks', 'keyword': '80s music live', 'icon': Icons.album},
  ];

  @override
  void initState() {
    super.initState();

    currentVideo = Map.from(widget.initialVideo);
    searchOptions = widget.searchOptions;
    _trackPlayedVideo(currentVideo);

    if (kIsWeb) {
      webController = ypi.YoutubePlayerController.fromVideoId(
        videoId: currentVideo['videoId']!,
        autoPlay: true,
        params: const ypi.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
      webController.listen((value) {
        if (value.playerState == ypi.PlayerState.ended && !handledEndPlay) {
          handledEndPlay = true;
          playNext();
        } else if (value.playerState != ypi.PlayerState.ended) {
          handledEndPlay = false;
        }

        if (mounted) setState(() {});
      });
    } else {
      mobileController = ypf.YoutubePlayerController(
        initialVideoId: currentVideo['videoId']!,
        flags: const ypf.YoutubePlayerFlags(
          mute: false,
          loop: false,
          autoPlay: true,
        ),
      );
      mobileController.addListener(() {
        if (!mounted) return;
        final state = mobileController.value.playerState;
        if (state == ypf.PlayerState.ended && !handledEndPlay) {
          handledEndPlay = true;
          playNext();
        } else if (state != ypf.PlayerState.ended) {
          handledEndPlay = false;
        }
        setState(() {});
      });
    }
  }

  void _trackPlayedVideo(Map<String, String> video) {
    final videoId = video['videoId'];
    if (videoId == null || playedVideoIds.contains(videoId)) return;

    playedVideoIds.add(videoId);
    playedVideos.add(video);
  }

  Future<Map<String, String>?> _findNextVideo(String keyword) {
    return _videoService.fetchVideo(
      keyword,
      kidsMode: searchOptions.kidsMode,
      selectedDuration: searchOptions.selectedDuration,
      filterClickbait: searchOptions.filterClickbait,
      avoidWords: searchOptions.avoidWords,
      metadataContext: searchOptions.advancedDescription,
      excludedVideoIds: playedVideoIds,
    );
  }

  void _loadVideo(Map<String, String> video) {
    final nextId = video['videoId'];
    if (nextId == null) return;

    setState(() {
      currentVideo = video;
      handledEndPlay = false;
      _trackPlayedVideo(video);
    });

    if (kIsWeb) {
      webController.loadVideoById(videoId: nextId);
    } else {
      mobileController.load(nextId);
    }
  }

  Future<void> _showNoVideoFoundMessage() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No new embeddable video found. Try another channel.'),
      ),
    );
  }

  Future<void> findAndPlayNextVideo() async {
    if (isFindingNext) return;

    setState(() {
      isFindingNext = true;
    });

    try {
      final nextVideo = await _findNextVideo(searchOptions.keyword);
      if (!mounted) return;

      if (nextVideo == null) {
        await _showNoVideoFoundMessage();
        return;
      }

      _loadVideo(nextVideo);
    } catch (e) {
      debugPrint('Find next video error: $e');
      await _showNoVideoFoundMessage();
    } finally {
      if (mounted) {
        setState(() {
          isFindingNext = false;
        });
      } else {
        isFindingNext = false;
      }
    }
  }

  void changeVolume(int newVolume) {
    setState(() {
      volume = newVolume;
    });

    if (kIsWeb) {
      webController.setVolume(newVolume);
    } else {
      mobileController.setVolume(newVolume);
    }
  }

  Future<void> switchChannel() async {
    final nextIndex = (currentChannelIndex + 1) % channels.length;
    final keyword = channels[nextIndex]['keyword'] as String?;

    if (keyword == null) return;

    try {
      final newVideo = await _videoService.fetchVideo(
        keyword,
        kidsMode: searchOptions.kidsMode,
        selectedDuration: searchOptions.selectedDuration,
        filterClickbait: searchOptions.filterClickbait,
        avoidWords: searchOptions.avoidWords,
        metadataContext: searchOptions.advancedDescription,
        excludedVideoIds: playedVideoIds,
      );

      if (!mounted) return;
      if (newVideo == null) {
        await _showNoVideoFoundMessage();
        return;
      }

      setState(() {
        currentChannelIndex = nextIndex;
        searchOptions = SearchOptions(
          keyword: keyword,
          kidsMode: searchOptions.kidsMode,
          selectedDuration: searchOptions.selectedDuration,
          filterClickbait: searchOptions.filterClickbait,
          avoidWords: searchOptions.avoidWords,
          advancedDescription: searchOptions.advancedDescription,
        );
        handledEndPlay = false;
      });

      _loadVideo(newVideo);
    } catch (e) {
      debugPrint('Channel switch error: $e');
    }
  }

  void playNext() => findAndPlayNextVideo();

  @override
  void deactivate() {
    if (!kIsWeb) {
      mobileController.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (kIsWeb) {
      webController.close();
    } else {
      mobileController.dispose();
    }
    super.dispose();
  }

  Widget buildVideoPlayer(Widget player) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: RetroPanel(
            padding: const EdgeInsets.all(18),
            shadowOffset: const Offset(10, 10),
            borderWidth: 5,
            child: Row(
              children: [
                Expanded(child: _buildScreen(player)),
                const SizedBox(width: 16),
                PointerInterceptor(child: _buildControlColumn()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(Widget player) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: auroraInk, width: 4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [auroraBlue, auroraYellow, auroraGreen],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: ClipRect(child: player)),
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(opacity: 0.22, child: RetroScanlines()),
            ),
          ),
          Positioned(
            left: 18,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: auroraInk,
              child: Text(
                'CH ${(currentChannelIndex + 1).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: auroraCream,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          if (selectedMode == DisplayMode.retroTv)
            Positioned.fill(
              child: IgnorePointer(
                child: Image.asset(
                  frameAssetMap[DisplayMode.retroTv]!,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlColumn() {
    return SizedBox(
      width: 104,
      child: Column(
        children: [
          Expanded(
            child: _ControlSlot(
              label: 'VOL',
              child: VolumeKnob(
                volume: volume,
                onChanged: changeVolume,
                size: 54,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _ControlSlot(
              label: 'TUNE',
              child: ChannelKnob(
                channelIndex: currentChannelIndex,
                onPressed: switchChannel,
                size: 54,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _ControlSlot(
              label: 'NEXT',
              child: IconButton(
                tooltip: 'Find next',
                onPressed: isFindingNext ? null : playNext,
                icon: isFindingNext
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Icon(Icons.skip_next_rounded, size: 34),
                color: auroraInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingPanel() {
    return RetroPanel(
      padding: const EdgeInsets.all(16),
      shadowOffset: const Offset(7, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RetroWindowBar(title: 'NOW_PLAYING.EXE'),
          const SizedBox(height: 14),
          Text(
            currentVideo['title'] ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            currentVideo['url'] ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayPanel() {
    return RetroPanel(
      padding: const EdgeInsets.all(16),
      shadowOffset: const Offset(7, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display Mode', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _DisplayChoice(
            title: 'Normal',
            value: DisplayMode.normal,
            groupValue: selectedMode,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedMode = value;
              });
            },
          ),
          _DisplayChoice(
            title: 'Retro TV',
            value: DisplayMode.retroTv,
            groupValue: selectedMode,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedMode = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return PointerInterceptor(
      child: Drawer(
        backgroundColor: auroraCream,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: auroraBlue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.home_rounded, color: auroraInk),
                    title: const Text(
                      'Home',
                      style: TextStyle(
                        color: auroraInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Channels',
                    style: TextStyle(
                      color: auroraInk,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            ...channels.map((channel) {
              return ListTile(
                leading: Icon(channel['icon'] as IconData, color: auroraInk),
                title: Text(
                  channel['title'] as String,
                  style: const TextStyle(
                    color: auroraInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () {
                  final keyword = channel['keyword'] as String;
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.pop(keyword);
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_rounded, color: auroraInk),
              title: const Text(
                'Create Channel',
                style: TextStyle(color: auroraInk, fontWeight: FontWeight.w800),
              ),
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();

                final controller = TextEditingController();

                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return Dialog(
                      backgroundColor: Colors.transparent,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: RetroPanel(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create Channel',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: controller,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Enter a search term',
                                  prefixIcon: Icon(Icons.search_rounded),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: RetroButton(
                                      label: 'Cancel',
                                      icon: Icons.close_rounded,
                                      isPrimary: false,
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 120,
                                    child: RetroButton(
                                      label: 'Open',
                                      icon: Icons.play_arrow_rounded,
                                      onPressed: () {
                                        final keyword = controller.text.trim();
                                        Navigator.pop(dialogContext);
                                        if (keyword.isNotEmpty) {
                                          nav.pop(keyword);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget player;

    if (kIsWeb) {
      player = ypi.YoutubePlayer(
        controller: webController,
        aspectRatio: 16 / 9,
      );
    } else {
      player = ypf.YoutubePlayerBuilder(
        player: ypf.YoutubePlayer(
          controller: mobileController,
          showVideoProgressIndicator: true,
        ),
        builder: (context, player) => player,
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: RetroAppBar(
        title: 'Entertainment Room',
        leadingIcon: Icons.menu_rounded,
        onLeadingPressed: () => _scaffoldKey.currentState?.openDrawer(),
        actions: [
          RetroIconButton(
            tooltip: 'Back to shelf',
            icon: Icons.arrow_back_rounded,
            isPrimary: true,
            onPressed: () => Navigator.pop(context),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            color: auroraCream,
            surfaceTintColor: Colors.transparent,
            onOpened: () {
              setState(() {
                isAccountMenuOpen = true;
              });
            },
            onCanceled: () {
              setState(() {
                isAccountMenuOpen = false;
              });
            },
            onSelected: (value) async {
              setState(() {
                isAccountMenuOpen = false;
              });

              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).popUntil((route) => route.isFirst);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            child: const RetroIconButton(
              tooltip: 'Account',
              icon: Icons.person_rounded,
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          ResponsivePage(
            maxWidth: 1040,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildVideoPlayer(player),
                  const SizedBox(height: 28),
                  _buildNowPlayingPanel(),
                  const SizedBox(height: 22),
                  _buildDisplayPanel(),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          if (isAccountMenuOpen)
            Positioned.fill(
              child: PointerInterceptor(
                child: Container(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlSlot extends StatelessWidget {
  const _ControlSlot({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: label == 'NEXT' ? auroraYellow : auroraGreen,
        border: Border.all(color: auroraInk, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Center(child: child)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: auroraInk,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplayChoice extends StatelessWidget {
  const _DisplayChoice({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final DisplayMode value;
  final DisplayMode groupValue;
  final ValueChanged<DisplayMode?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected ? auroraGreen : auroraWhite,
        child: InkWell(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: auroraInk, width: 3),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: auroraInk,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: auroraInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Knob extends StatelessWidget {
  final double size;
  final double angle;

  const Knob({super.key, required this.size, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: auroraCream,
          border: Border.all(color: auroraInk, width: size * 0.08),
          boxShadow: const [
            BoxShadow(blurRadius: 0, offset: Offset(3, 3), color: auroraShadow),
          ],
        ),
        child: Center(
          child: Container(
            width: size * 0.08,
            height: size * 0.42,
            decoration: BoxDecoration(
              color: auroraInk,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class VolumeKnob extends StatelessWidget {
  final int volume;
  final double size;
  final ValueChanged<int> onChanged;

  const VolumeKnob({
    super.key,
    required this.volume,
    required this.onChanged,
    this.size = 40,
  });

  void _updateVolume(BuildContext context, Offset localPosition) {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final vector = localPosition - center;

    final angle = math.atan2(vector.dy, vector.dx);

    final newVolume = (((angle + math.pi) / (2 * math.pi)) * 100).round().clamp(
      0,
      100,
    );

    onChanged(newVolume);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (details) => _updateVolume(context, details.localPosition),
      onPanUpdate: (details) => _updateVolume(context, details.localPosition),
      child: Knob(size: size, angle: (volume / 100) * 2 * math.pi),
    );
  }
}

class ChannelKnob extends StatelessWidget {
  final int channelIndex;
  final double size;
  final VoidCallback onPressed;

  const ChannelKnob({
    super.key,
    required this.channelIndex,
    required this.onPressed,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Knob(size: size, angle: channelIndex * 0.55),
    );
  }
}
