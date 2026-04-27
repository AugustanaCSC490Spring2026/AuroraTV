import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as ypi;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/frame_options.dart';
import '../services/video_service.dart';
import '../models/search_options.dart';
import '../services/gemini_service.dart';
import 'dart:math' as math;

class YoutubePage extends StatefulWidget {
  final List<Map<String, String>> videos;
  final SearchOptions searchOptions;

  const YoutubePage({
    super.key,
    required this.videos,
    required this.searchOptions,
  });

  @override
  State<YoutubePage> createState() => _YoutubePageState();
}

class _YoutubePageState extends State<YoutubePage> {
  late List<Map<String, String>> videos;
  late SearchOptions searchOptions;
  late ypf.YoutubePlayerController mobileController;
  late ypi.YoutubePlayerController webController;

  final _videoService = VideoService();
  final _geminiService = GeminiService();

  int currentIndex = 0;
  int volume = 50;
  bool handledEndPlay = false;
  bool isAccountMenuOpen = false;
  bool isLoadingMore = false;
  DisplayMode selectedMode = DisplayMode.normal;

  Map<String, String> get currentVideo => videos[currentIndex];

  @override
  void initState() {
    super.initState();

    videos = List.from(widget.videos);
    searchOptions = widget.searchOptions;

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

  Future<void> loadMoreVideos() async {
    if (isLoadingMore) return;
    isLoadingMore = true;

    String query = await _geminiService.optimizeSearchQuery(
      searchOptions.keyword,
      searchOptions.avoidWords,
      searchOptions.advancedDescription,
    );

    final moreVideos = await _videoService.fetchVideos(
      query,
      kidsMode: searchOptions.kidsMode,
      selectedDuration: searchOptions.selectedDuration,
    );

    if (!mounted) return;

    setState(() {
      videos.addAll(moreVideos);
    });

    isLoadingMore = false;
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

  void playNext() async {
    if (currentIndex >= videos.length - 2) {
      debugPrint("loading more videos");
      await loadMoreVideos();
    }
    if (currentIndex + 1 >= videos.length) return;
    setState(() {
      currentIndex++;
      handledEndPlay = false;
    });
    final nextId = currentVideo['videoId']!;
    if (kIsWeb) {
      webController.loadVideoById(videoId: nextId);
    } else {
      mobileController.load(nextId);
    }
  }

  @override
  void deactivate() {
    if (!kIsWeb) {
      mobileController.pause();
    }
    super.deactivate();
  }

  Widget buildVideoPlayer(Widget player) {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  42, // left
                  28, // top
                  42, // right
                  32, // bottom
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: player,
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
            if (selectedMode == DisplayMode.retroTv)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final frameWidth = constraints.maxWidth;
                    final frameHeight = constraints.maxHeight;

                    return Stack(
                      children: [
                        Positioned(
                          right: frameWidth * 0.035,
                          top: frameHeight * 0.49,
                          child: PointerInterceptor(
                            child: VolumeKnob(
                              volume: volume,
                              onChanged: changeVolume,
                              size: frameWidth * 0.075,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
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

  final channels = [
    {
      "title": "Lo-fi",
      "keyword": "lofi hip hop radio",
      "icon": Icons.music_note,
    },
    {"title": "News", "keyword": "live news", "icon": Icons.public},
    {
      "title": "Gaming",
      "keyword": "live gaming stream",
      "icon": Icons.sports_esports,
    },
    {"title": "Nature", "keyword": "nature live cam", "icon": Icons.landscape},
    {"title": "Podcasts", "keyword": "live podcast", "icon": Icons.mic},
    {"title": "Throwbacks", "keyword": "80s music live", "icon": Icons.album},
  ];

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
      appBar: AppBar(
        leadingWidth: 120,
        leading: Row(
          children: [
            // Hamburger menu
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            // Logo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      transform: Matrix4.identity()
                        ..scale(1.1), // always slightly bigger
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        title: const Text("Now Playing"),
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: currentIndex + 1 < videos.length ? playNext : null,
            tooltip: "Skip",
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: "Account",
            color: const Color(0xFF04131F),
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
                if (!mounted) return;
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).popUntil((route) => route.isFirst);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Text('Profile', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text('Settings', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      drawer: PointerInterceptor(
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.black87),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.home, color: Colors.white),
                      title: const Text(
                        "Home",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Channels",
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                  ],
                ),
              ),
              ...channels.map((channel) {
                return ListTile(
                  leading: Icon(channel["icon"] as IconData),
                  title: Text(channel["title"] as String),
                  onTap: () {
                    final keyword = channel["keyword"] as String;
                    Navigator.pop(context);
                    Future.microtask(() {
                      Navigator.of(this.context).pop(keyword);
                    });
                  },
                );
              }),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text("Create Channel"),
                onTap: () {
                  Navigator.pop(context);

                  final controller = TextEditingController();

                  showDialog(
                    context: this.context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text("Create Channel"),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: "Enter a search term",
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final keyword = controller.text.trim();
                              Navigator.pop(dialogContext);
                              if (keyword.isNotEmpty) {
                                Future.microtask(() {
                                  Navigator.of(this.context).pop(keyword);
                                });
                              }
                            },
                            child: const Text("Open"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(12),
            children: [
              buildVideoPlayer(player),
              const SizedBox(height: 12),
              const Text(
                'Display Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              RadioListTile<DisplayMode>(
                title: const Text('Normal'),
                value: DisplayMode.normal,
                groupValue: selectedMode,
                onChanged: (value) {
                  setState(() {
                    selectedMode = value!;
                  });
                },
              ),
              RadioListTile<DisplayMode>(
                title: const Text('Retro TV'),
                value: DisplayMode.retroTv,
                groupValue: selectedMode,
                onChanged: (value) {
                  setState(() {
                    selectedMode = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(currentVideo['title'] ?? ''),
              const SizedBox(height: 8),
              Text(currentVideo['url'] ?? ''),
            ],
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
      child: Transform.rotate(
        angle: (volume / 100) * 2 * math.pi,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A1A),
            border: Border.all(
              color: const Color(0xFFD8B56D),
              width: size * 0.05,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(2, 3),
                color: Colors.black54,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: size * 0.08,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8B56D),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
