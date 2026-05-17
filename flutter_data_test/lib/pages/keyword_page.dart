import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/search_options.dart';
import '../services/category_service.dart';
import '../services/gemini_service.dart';
import '../services/video_service.dart';
import '../widgets/featured_channels_widget.dart';
import '../widgets/filter_dialog_widget.dart';
import '../widgets/retro_ui.dart';
import 'youtube_page.dart';

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
  bool filterClickbait = true;

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
        filterClickbait: filterClickbait,
        keyword: keywordCtrl.text.trim(),
        avoidWordsCtrl: avoidWordsCtrl,
        advancedDescriptionCtrl: advancedDescriptionCtrl,
        onApply: (kids, duration, type, clickbait) {
          setState(() {
            kidsMode = kids;
            selectedDuration = duration;
            selectedVideoType = type;
            filterClickbait = clickbait;
          });
        },
        onReset: () {
          setState(() {
            kidsMode = false;
            selectedDuration = 'any';
            selectedVideoType = 'Any';
            filterClickbait = true;
          });
        },
      ),
    );
  }

  void _openImportDialog() {
    final codeCtrl = TextEditingController();
    bool isImporting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: RetroPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Import Category',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      RetroIconButton(
                        tooltip: 'Close',
                        icon: Icons.close_rounded,
                        size: 44,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const RetroWindowBar(title: 'SHARE_CODE.EXE'),
                  const SizedBox(height: 14),
                  Text(
                    'Enter a share code to load another user\'s filters.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    style: const TextStyle(
                      color: auroraInk,
                      letterSpacing: 3,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Share code',
                      hintText: 'LF7-X2K',
                      prefixIcon: Icon(Icons.download_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 154,
                      child: isImporting
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : RetroButton(
                              label: 'Import',
                              icon: Icons.download_rounded,
                              onPressed: () async {
                                if (codeCtrl.text.trim().isEmpty) return;
                                setDialogState(() => isImporting = true);

                                final data = await CategoryService()
                                    .loadCategoryByCode(codeCtrl.text);

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

                                setState(() {
                                  kidsMode = data['kidsMode'] ?? false;
                                  selectedDuration = data['duration'] ?? 'any';
                                  selectedVideoType =
                                      data['videoType'] ?? 'Any';
                                  avoidWordsCtrl.text =
                                      data['avoidWords'] ?? '';
                                  advancedDescriptionCtrl.text =
                                      data['advancedDescription'] ?? '';
                                  final keyword =
                                      data['keyword'] as String? ?? '';
                                  if (keyword.isNotEmpty) {
                                    keywordCtrl.text = keyword;
                                  }
                                });

                                Navigator.pop(ctx);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Loaded: ${data['name']}'),
                                  ),
                                );
                              },
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

  Future<void> _searchVideo() async {
    String keyword = keywordCtrl.text.trim();
    if (keyword.isEmpty) return;

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

    final result = await _videoService.fetchVideo(
      keyword,
      kidsMode: kidsMode,
      selectedDuration: selectedDuration,
      filterClickbait: filterClickbait,
      avoidWords: avoidWordsCtrl.text.trim(),
      metadataContext: advancedDescriptionCtrl.text.trim(),
    );

    if (result == null) {
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

    final id = result['videoId']!;
    final title = result['title'] ?? '';
    final url = result['url']!;

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
      filterClickbait: filterClickbait,
      avoidWords: avoidWordsCtrl.text.trim(),
      advancedDescription: advancedDescriptionCtrl.text.trim(),
    );

    if (!mounted) return;
    final selectedKeyword = await nav.push<String>(
      MaterialPageRoute(
        builder: (_) =>
            YoutubePage(initialVideo: result, searchOptions: searchOptions),
      ),
    );

    if (selectedKeyword != null && selectedKeyword.isNotEmpty) {
      keywordCtrl.text = selectedKeyword;
      await _searchVideo();
    }
  }

  Widget _buildCatalogHeader() {
    return RetroPanel(
      color: auroraYellow,
      shadowOffset: const Offset(7, 7),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Text(
            'Tape Shelf',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: auroraWhite,
              shadows: const [Shadow(color: auroraInk, offset: Offset(2, 2))],
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 152,
                child: RetroButton(
                  label: 'Import',
                  icon: Icons.download_rounded,
                  isPrimary: false,
                  onPressed: _openImportDialog,
                ),
              ),
              SizedBox(
                width: 168,
                child: RetroButton(
                  label: 'Add a tape',
                  icon: Icons.add_rounded,
                  onPressed: _openFilterDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchConsole() {
    return RetroPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RetroWindowBar(title: 'CHANNEL_TUNER.EXE'),
          const SizedBox(height: 16),
          Text(
            'Tune into your own curated channel',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Search by mood, genre, topic, or vibe.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;
              final searchField = TextField(
                controller: keywordCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchVideo(),
                decoration: const InputDecoration(
                  labelText: 'Search tapes',
                  hintText: 'late night jazz, city pop, gaming live',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              );
              final actions = Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 138,
                    child: RetroButton(
                      label: 'Filters',
                      icon: Icons.tune_rounded,
                      isPrimary: false,
                      onPressed: _openFilterDialog,
                    ),
                  ),
                  SizedBox(
                    width: 152,
                    child: RetroButton(
                      label: isLoading ? 'Tuning' : 'Launch',
                      icon: isLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.play_circle_fill_rounded,
                      onPressed: isLoading ? null : _searchVideo,
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [searchField, const SizedBox(height: 14), actions],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 14),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (kidsMode) _buildFilterChip('Kids mode'),
              if (selectedDuration != 'any') _buildFilterChip(selectedDuration),
              if (selectedVideoType != 'Any')
                _buildFilterChip(selectedVideoType),
              if (filterClickbait) _buildFilterChip('Clickbait filter'),
              if (avoidWordsCtrl.text.trim().isNotEmpty)
                _buildFilterChip('Avoid: ${avoidWordsCtrl.text.trim()}'),
              if (advancedDescriptionCtrl.text.trim().isNotEmpty)
                _buildFilterChip('Advanced search: ${advancedDescriptionCtrl.text.trim()}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSelectionCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _searchVideo,
        child: RetroPanel(
          color: auroraBlue,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          shadowOffset: const Offset(7, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'NOW AIRING',
                    style: TextStyle(
                      color: auroraInk,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: auroraInk,
                      border: Border.all(color: auroraWhite, width: 2),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: auroraWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                keywordCtrl.text.trim().isEmpty
                    ? 'No tape selected'
                    : keywordCtrl.text.trim(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: auroraWhite,
                  shadows: const [
                    Shadow(color: auroraInk, offset: Offset(2, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                videoTitle ?? 'Tap to relaunch this channel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: auroraWhite,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: auroraGreen,
        border: Border.all(color: auroraInk, width: 3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: auroraInk,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RetroAppBar(
        title: 'Aurora Home',
        actions: [
          RetroIconButton(
            tooltip: 'Sign out',
            icon: Icons.person_rounded,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: ResponsivePage(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCatalogHeader(),
              const SizedBox(height: 22),
              if (videoTitle != null || videoUrl != null) ...[
                _buildCurrentSelectionCard(),
                const SizedBox(height: 22),
              ],
              _buildSearchConsole(),
              const SizedBox(height: 26),
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
    );
  }
}
