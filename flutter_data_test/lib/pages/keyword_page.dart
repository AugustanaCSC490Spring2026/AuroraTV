import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'youtube_page.dart';
import '../constants/colors.dart';
import '../services/video_service.dart';
import '../services/gemini_service.dart';
import '../services/category_service.dart';
import '../models/search_options.dart';
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
  String selectedDuration = 'any';
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
        keyword: keywordCtrl.text.trim(),
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
            selectedDuration = 'any';
            selectedVideoType = 'Any';
          });
        },
      ),
    );
  }

  // ── NEW: Import a shared category by code ──
  void _openImportDialog() {
    final codeCtrl = TextEditingController();
    bool isImporting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: auroraPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: auroraDeep, width: 1.2),
          ),
          title: const Text(
            'Import Category',
            style: TextStyle(color: auroraMint, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a share code to load another user\'s filters.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  letterSpacing: 3,
                  fontSize: 18,
                ),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Share Code',
                  hintText: 'e.g. LF7-X2K',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (isImporting)
              const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  if (codeCtrl.text.trim().isEmpty) return;
                  setDialogState(() => isImporting = true);

                  final data = await CategoryService().loadCategoryByCode(
                    codeCtrl.text,
                  );

                  if (!ctx.mounted) return;

                  if (data == null) {
                    setDialogState(() => isImporting = false);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Code not found. Double-check and try again.',
                        ),
                      ),
                    );
                    return;
                  }

                  // Apply loaded filters to the page
                  setState(() {
                    kidsMode = data['kidsMode'] ?? false;
                    selectedDuration = data['duration'] ?? 'any';
                    selectedVideoType = data['videoType'] ?? 'Any';
                    avoidWordsCtrl.text = data['avoidWords'] ?? '';
                    advancedDescriptionCtrl.text =
                        data['advancedDescription'] ?? '';
                    if ((data['keyword'] as String? ?? '').isNotEmpty) {
                      keywordCtrl.text = data['keyword'];
                    }
                  });

                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Loaded: ${data['name']}')),
                  );
                },
                child: const Text('Import'),
              ),
          ],
        ),
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
      keyword = await _geminiService.optimizeSearchQuery(
        keyword,
        avoidWordsCtrl.text.trim(),
        advancedDescriptionCtrl.text.trim(),
      );
    }
    premadeCategory = false;

    final result = await _videoService.fetchVideos(
      keyword,
      kidsMode: kidsMode,
      selectedDuration: selectedDuration,
    );

    if (result.isEmpty) {
      setState(() {
        videoTitle = null;
        videoUrl = null;
        videoId = null;
        isLoading = false;
      });

      if (!mounted) return;
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

    final searchOptions = SearchOptions(
      keyword: keyword,
      kidsMode: kidsMode,
      selectedDuration: selectedDuration,
      avoidWords: avoidWordsCtrl.text.trim(),
      advancedDescription: advancedDescriptionCtrl.text.trim(),
    );

    if (!mounted) return;
    final selectedKeyword = await nav.push<String>(
      MaterialPageRoute(
        builder: (_) =>
            YoutubePage(videos: result, searchOptions: searchOptions),
      ),
    );

    if (selectedKeyword != null && selectedKeyword.isNotEmpty) {
      keywordCtrl.text = selectedKeyword;
      await _searchVideo();
    }
  }

  Widget _buildTunerPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: auroraPanel,
        border: Border.all(color: auroraDeep, width: 1.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHANNEL CUSTOMIZER',
            style: TextStyle(
              color: auroraGlow,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tune into your own curated channel',
            style: TextStyle(
              color: auroraMint,
              fontFamily: 'AuroraFont',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Search by mood, genre, topic, or vibe',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: keywordCtrl,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _searchVideo(),
                  decoration: const InputDecoration(
                    labelText: "Search Broadcast",
                    hintText: "e.g. late night jazz, city pop, gaming live",
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildSquareIconButton(
                onTap: _openFilterDialog,
                icon: Icons.tune,
                color: auroraGlow,
                tooltip: 'Filters',
              ),
              const SizedBox(width: 8),
              _buildSquareIconButton(
                onTap: _openImportDialog,
                icon: Icons.download_rounded,
                color: auroraMint,
                tooltip: 'Import Category',
              ),
            ],
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (kidsMode) _buildFilterChip('Kids Mode'),
              if (selectedDuration != 'any') _buildFilterChip(selectedDuration),
              if (selectedVideoType != 'Any')
                _buildFilterChip(selectedVideoType),
              if (avoidWordsCtrl.text.trim().isNotEmpty)
                _buildFilterChip('Avoid: ${avoidWordsCtrl.text.trim()}'),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _searchVideo,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_fill_rounded),
              label: Text(isLoading ? 'Scanning Signal...' : 'Launch Channel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSelectionCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(0),
        onTap: _searchVideo,
        splashColor: auroraGlow.withOpacity(0.1),
        highlightColor: auroraGlow.withOpacity(0.04),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF04131F),
            border: Border.all(color: auroraDeep, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP LABEL ROW
              Row(
                children: [
                  const Text(
                    'NOW AIRING',
                    style: TextStyle(
                      color: auroraGlow,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // LIVE TAG
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // MAIN TITLE (BIG)
              Text(
                keywordCtrl.text.trim().isEmpty
                    ? 'No channel selected'
                    : keywordCtrl.text.trim(),
                style: const TextStyle(
                  color: auroraMint,
                  fontFamily: 'AuroraFont',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: 10),

              // SUBTEXT
              const Text(
                'Tap to relaunch this channel',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareIconButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A2538),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: auroraDeep, width: 1.2),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        color: color,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: auroraDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: auroraBlueTeal, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: auroraMint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const SizedBox(),
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
        color: auroraNavy,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: SizedBox(
                      height: 120,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.center,
                          heightFactor: 0.5,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                if (videoTitle != null || videoUrl != null)
                  _buildCurrentSelectionCard(),

                const SizedBox(height: 18),

                _buildTunerPanel(),

                const SizedBox(height: 22),

                FeaturedChannelsWidget(
                  onChannelTap: (keyword) async {
                    premadeCategory = true;
                    keywordCtrl.text = keyword;
                    await _searchVideo();
                  },
                ),

                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
