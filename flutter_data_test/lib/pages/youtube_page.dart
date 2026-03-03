import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  late final YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        mute: false,
        loop: false,
        autoPlay: true,
      ),
    );

    controller.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  void togglePlayPause() {
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  void deactivate() {
    controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
        ),
        builder: (context, player) => Scaffold(
          appBar: AppBar(title: const Text("Now Playing")),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              player,
              const SizedBox(height: 16),
              Text(widget.title),
              const SizedBox(height: 8),
              Text(widget.url),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: togglePlayPause,
                child: Text(controller.value.isPlaying ? 'Pause' : 'Play'),
              ),
            ],
          ),
        ),
      );
}