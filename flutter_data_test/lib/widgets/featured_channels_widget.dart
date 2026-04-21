// Featured channels display widget
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FeaturedChannelsWidget extends StatelessWidget {
  final Function(String) onChannelTap;

  const FeaturedChannelsWidget({super.key, required this.onChannelTap});

  @override
  Widget build(BuildContext context) {
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
      {
        "title": "Nature",
        "keyword": "nature live cam",
        "icon": Icons.landscape,
      },
      {"title": "Podcasts", "keyword": "live podcast", "icon": Icons.mic},
      {"title": "Throwbacks", "keyword": "80s music live", "icon": Icons.album},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Start Watching",
          style: TextStyle(
            color: auroraMint,
            fontFamily: 'AuroraFont',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: channels.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final channel = channels[index];

            return GestureDetector(
              onTap: () {
                onChannelTap(channel["keyword"] as String);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: auroraPanel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: auroraDeep),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      channel["icon"] as IconData,
                      color: auroraGlow,
                      size: 34,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      channel["title"] as String,
                      style: const TextStyle(
                        color: auroraMint,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
