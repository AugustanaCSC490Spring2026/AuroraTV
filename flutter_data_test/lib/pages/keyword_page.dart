// Keyword search page for video discovery

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'youtube_page.dart';
import '../constants/colors.dart';
import '../services/video_service.dart';
import '../services/gemini_service.dart';
import '../widgets/featured_channels_widget.dart';
import '../widgets/filter_dialog_widget.dart';

class KeyWordPage extends StatefulWidget {
  const KeyWordPage({super.key});

  @override
  State<KeyWordPage> createState() => _KeyWordPageState();
}

class _KeyWordPageState extends State<KeyWordPage> {
  final TextEditingController keywordCtrl = TextEditingController();
  String? videoTitle;
  String? videoUrl;
  String? videoId;
  bool isLoading = false;
  bool premadeCategory = false;

  bool kidsMode = false;
  String selectedDuration = 'Any';
  String selectedVideoType = 'Any';

  final TextEditingController avoidWordsCtrl = TextEditingController();
  final TextEditingController advancedDescriptionCtrl = TextEditingController();

  final _videoService = VideoService();
  final _geminiService = GeminiService();

  @override
  void dispose() {
    keywordCtrl.dispose();
    avoidWordsCtrl.dispose();
    advancedDescriptionCtrl.dispose();
    super.dispose();
  }

  void _openFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialogWidget(
        kidsMode: kidsMode,
        selectedDuration: selectedDuration,
        selectedVideoType: selectedVideoType,
        avoidWordsCtrl: avoidWordsCtrl,
        advancedDescriptionCtrl: advancedDescriptionCtrl,
        onApply: (kids, duration, type) {
          setState(() {
            kidsMode = kids;
            selectedDuration = duration;
            selectedVideoType = type;
          });
        },
        onReset: () {
          setState(() {
            kidsMode = false;
            selectedDuration = 'Any';
            selectedVideoType = 'Any';
          });
        },
      ),
    );
  }

  Future<void> _searchVideo() async {
    debugPrint(premadeCategory.toString());

    String keyword = keywordCtrl.text.trim();

    if (keyword.isEmpty) return;

    debugPrint(keyword);

    setState(() {
      isLoading = true;
    });

    final nav = Navigator.of(context);

    if (!premadeCategory) {
      keyword = await _geminiService.optimizeSearchQuery(keyword);
    }
    premadeCategory = false;

    final result = await _videoService.fetchVideos(keyword);

    if (result.isEmpty) {
      setState(() {
        videoTitle = null;
        videoUrl = null;
        videoId = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No embeddable video found. Try another search.'),
        ),
      );
      return;
    }

    final id = result[0]['videoId']!;
    final title = result[0]['title'] ?? '';
    final url = result[0]['url']!;

    setState(() {
      videoTitle = title;
      videoUrl = url;
      videoId = id;
      isLoading = false;
    });

    final selectedKeyword = await nav.push<String>(
      MaterialPageRoute(builder: (_) => YoutubePage(videos: result)),
    );

    if (selectedKeyword != null && selectedKeyword.isNotEmpty) {
      keywordCtrl.text = selectedKeyword;
      await _searchVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: SizedBox(
          height: 60,
          width: 120,
          child: ClipRect(
            child: Align(
              alignment: Alignment.center,
              widthFactor: 0.4,
              child: Image.asset('assets/images/logo.png'),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [auroraDeep, auroraNavy, const Color(0xFF021C2E)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 760),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: auroraPanel.withOpacity(0.94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: auroraDeep, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Color(0x33288D8A),
                    blurRadius: 32,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "A U R O R A   T V",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: auroraGlow,
                      fontSize: 18,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF04131F),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: auroraDeep, width: 1.4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Search a channel or video",
                          style: TextStyle(
                            color: auroraMint,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Retro-inspired streaming",
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: keywordCtrl,
                                style: const TextStyle(color: Colors.white),
                                onSubmitted: (_) => _searchVideo(),
                                decoration: const InputDecoration(
                                  labelText: "Search",
                                  hintText:
                                      "e.g. lo-fi beats, synthwave, 80s hits",
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: auroraPanel,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: auroraDeep,
                                  width: 1.2,
                                ),
                              ),
                              child: IconButton(
                                onPressed: _openFilterDialog,
                                icon: const Icon(Icons.tune),
                                color: auroraGlow,
                                tooltip: 'Filters',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (kidsMode)
                              Chip(
                                backgroundColor: auroraDeep,
                                label: const Text(
                                  'Kids Mode',
                                  style: TextStyle(color: auroraMint),
                                ),
                              ),
                            if (selectedDuration != 'Any')
                              Chip(
                                backgroundColor: auroraDeep,
                                label: Text(
                                  selectedDuration,
                                  style: const TextStyle(color: auroraMint),
                                ),
                              ),
                            if (selectedVideoType != 'Any')
                              Chip(
                                backgroundColor: auroraDeep,
                                label: Text(
                                  selectedVideoType,
                                  style: const TextStyle(color: auroraMint),
                                ),
                              ),
                            if (avoidWordsCtrl.text.trim().isNotEmpty)
                              Chip(
                                backgroundColor: auroraDeep,
                                label: Text(
                                  'Avoid: ${avoidWordsCtrl.text.trim()}',
                                  style: const TextStyle(color: auroraMint),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _searchVideo,
                          icon: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_circle_fill_rounded),
                          label: Text(
                            isLoading ? "Loading..." : "Launch Channel",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FeaturedChannelsWidget(
                    onChannelTap: (keyword) async {
                      premadeCategory = true;
                      keywordCtrl.text = keyword;
                      await _searchVideo();
                    },
                  ),
                  if (videoTitle != null || videoUrl != null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _searchVideo,
                        // ignore: deprecated_member_use
                        splashColor: auroraGlow.withOpacity(0.2),
                        // ignore: deprecated_member_use
                        highlightColor: auroraGlow.withOpacity(0.08),
                        child: Ink(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF061B2C),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: auroraDeep),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "CURRENT SELECTION",
                                style: TextStyle(
                                  color: auroraGlow,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (videoTitle != null)
                                Text(
                                  keywordCtrl.text.trim(),
                                  style: const TextStyle(
                                    color: auroraMint,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
