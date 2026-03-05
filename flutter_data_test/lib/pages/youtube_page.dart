import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as ypi;

class YoutubePage extends StatefulWidget {
  final String videoId;
  final String title;
  final String url;

  const YoutubePage({
    super.key,
    required this.videoId,
    required this.title,
    required this.url,
  });

  @override
  State<YoutubePage> createState() => _YoutubePageState();
}

class _YoutubePageState extends State<YoutubePage> {
  late ypf.YoutubePlayerController mobileController;
  late ypi.YoutubePlayerController webController;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      webController = ypi.YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: true,
        params: const ypi.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
    } else {
      mobileController = ypf.YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const ypf.YoutubePlayerFlags(
          mute: false,
          loop: false,
          autoPlay: true,
        ),
      );
      mobileController.addListener(() {
        if (!mounted) return;
        setState(() {});
      });
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
      appBar: AppBar(title: const Text("Now Playing")),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          player,
          const SizedBox(height: 16),
          Text(widget.title),
          const SizedBox(height: 8),
          Text(widget.url),
        ],
      ),
    );
  }
}
