import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as ypi;
import 'package:pointer_interceptor/pointer_interceptor.dart';

class YoutubePage extends StatefulWidget {
  final List<Map<String, String>> videos;

  const YoutubePage({super.key, required this.videos});

  @override
  State<YoutubePage> createState() => _YoutubePageState();
}

class _YoutubePageState extends State<YoutubePage> {
  late ypf.YoutubePlayerController mobileController;
  late ypi.YoutubePlayerController webController;

  int currentIndex = 0;
  bool handledEndPlay = false;

  Map<String, String> get currentVideo => widget.videos[currentIndex];

  @override
  void initState() {
    super.initState();

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

  void playNext() {
    if (currentIndex + 1 >= widget.videos.length) return;
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
    {"title": "Lo-fi", "keyword": "lofi hip hop radio", "icon": Icons.music_note},
    {"title": "News", "keyword": "live news", "icon": Icons.public},
    {"title": "Gaming", "keyword": "live gaming stream", "icon": Icons.sports_esports},
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
        title: const Text("Now Playing"),
        actions: [
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: currentIndex + 1 < widget.videos.length ? playNext : null,
            tooltip: "Skip",
          ),
        ],
      ),
      drawer: PointerInterceptor(
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.black87),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    "Channels",
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
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
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          player,
          const SizedBox(height: 16),
          Text(currentVideo['title'] ?? ''),
          const SizedBox(height: 8),
          Text(currentVideo['url'] ?? ''),
        ],
      ),
    );
  }
}