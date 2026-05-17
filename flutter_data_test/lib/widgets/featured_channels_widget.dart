import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'retro_ui.dart';

class FeaturedChannelsWidget extends StatelessWidget {
  final ValueChanged<String> onChannelTap;

  static const _channels = [
    TapeData(
      title: 'Lo-fi',
      keyword: 'lofi hip hop radio',
      color: auroraYellow,
      height: 176,
      width: 58,
    ),
    TapeData(
      title: 'News',
      keyword: 'live news',
      color: auroraGreen,
      height: 152,
      width: 46,
    ),
    TapeData(
      title: 'Gaming',
      keyword: 'live gaming stream',
      color: auroraBlue,
      height: 188,
      width: 56,
    ),
    TapeData(
      title: 'Nature',
      keyword: 'nature live cam',
      color: auroraCream,
      height: 192,
      width: 58,
    ),
    TapeData(
      title: 'Podcasts',
      keyword: 'live podcast',
      color: auroraBlue,
      height: 168,
      width: 56,
    ),
    TapeData(
      title: 'Throwbacks',
      keyword: '80s music live',
      color: auroraInk,
      height: 182,
      width: 62,
    ),
    TapeData(
      title: 'City Pop',
      keyword: 'city pop radio',
      color: auroraYellow,
      height: 160,
      width: 48,
    ),
    TapeData(
      title: 'Late Night',
      keyword: 'late night jazz radio',
      color: auroraBlue,
      height: 184,
      width: 60,
    ),
  ];

  const FeaturedChannelsWidget({super.key, required this.onChannelTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Start Watching', style: text.headlineMedium),
        const SizedBox(height: 12),
        TapeShelf(
          tapes: _channels,
          onTapePressed: (tape) => onChannelTap(tape.keyword),
        ),
      ],
    );
  }
}
