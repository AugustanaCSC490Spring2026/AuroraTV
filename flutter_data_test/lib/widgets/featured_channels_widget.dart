import 'package:flutter/material.dart';

import '../constants/colors.dart';

class FeaturedChannelsWidget extends StatelessWidget {
  final ValueChanged<String> onChannelTap;

  static const _channels = [
    _FeaturedChannel(title: "Lo-fi",      keyword: "lofi hip hop radio",  icon: Icons.music_note),
    _FeaturedChannel(title: "News",       keyword: "live news",            icon: Icons.public),
    _FeaturedChannel(title: "Gaming",     keyword: "live gaming stream",   icon: Icons.sports_esports),
    _FeaturedChannel(title: "Nature",     keyword: "nature live cam",      icon: Icons.landscape),
    _FeaturedChannel(title: "Podcasts",   keyword: "live podcast",         icon: Icons.mic),
    _FeaturedChannel(title: "Throwbacks", keyword: "80s music live",       icon: Icons.album),
  ];

  const FeaturedChannelsWidget({super.key, required this.onChannelTap});

  @override
  Widget build(BuildContext context) {
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
          itemCount: _channels.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final channel = _channels[index];
            return GestureDetector(
              onTap: () => onChannelTap(channel.keyword),
              child: Container(
                decoration: BoxDecoration(
                  color: auroraPanel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: auroraDeep),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(channel.icon, color: auroraGlow, size: 34),
                    const SizedBox(height: 10),
                    Text(channel.title, style: const TextStyle(color: auroraMint, fontWeight: FontWeight.bold, fontSize: 16)),
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

class _FeaturedChannel {
  final String title;
  final String keyword;
  final IconData icon;

  const _FeaturedChannel({required this.title, required this.keyword, required this.icon});
}