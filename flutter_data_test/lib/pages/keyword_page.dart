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
  static const _sharedTapeColors = [
    auroraYellow,
    auroraGreen,
    auroraBlue,
    auroraCream,
    auroraInk,
  ];

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
  final List<_SharedCategoryTape> _addedTapes = [];

  @override
  void dispose() {
    keywordCtrl.dispose();
    avoidWordsCtrl.dispose();
    advancedDescriptionCtrl.dispose();
    super.dispose();
  }

  String _normalizeShareCode(String code) {
    final stripped = code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (stripped.isEmpty) return '';
    if (stripped.length == 6) {
      return '${stripped.substring(0, 3)}-${stripped.substring(3)}';
    }
    return code.toUpperCase().trim();
  }

  String _readCategoryText(
    Map<String, dynamic> data,
    String key, [
    String fallback = '',
  ]) {
    final value = data[key];
    if (value is! String) return fallback;

    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  bool _readCategoryBool(Map<String, dynamic> data, String key, bool fallback) {
    final value = data[key];
    return value is bool ? value : fallback;
  }

  int _shareCodeSeed(String shareCode) {
    return shareCode.codeUnits.fold<int>(
      0,
      (seed, unit) => (seed * 31 + unit) & 0x7fffffff,
    );
  }

  _SharedCategoryTape? _buildSharedCategoryTape(
    String shareCode,
    Map<String, dynamic> data,
  ) {
    final keyword = _readCategoryText(data, 'keyword');
    if (keyword.isEmpty) return null;

    final title = _readCategoryText(data, 'name', keyword);
    final seed = _shareCodeSeed(shareCode);

    return _SharedCategoryTape(
      shareCode: shareCode,
      title: title,
      keyword: keyword,
      color: _sharedTapeColors[seed % _sharedTapeColors.length],
      height: 156 + (seed % 5) * 8,
      width: 48 + (seed % 4) * 4,
      kidsMode: _readCategoryBool(data, 'kidsMode', false),
      selectedDuration: _readCategoryText(data, 'duration', 'any'),
      selectedVideoType: _readCategoryText(data, 'videoType', 'Any'),
      filterClickbait: _readCategoryBool(data, 'filterClickbait', true),
      avoidWords: _readCategoryText(data, 'avoidWords'),
      advancedDescription: _readCategoryText(data, 'advancedDescription'),
    );
  }

  Future<void> _startWatchingTape(TapeData tape) async {
    if (tape is _SharedCategoryTape) {
      setState(() {
        kidsMode = tape.kidsMode;
        selectedDuration = tape.selectedDuration;
        selectedVideoType = tape.selectedVideoType;
        filterClickbait = tape.filterClickbait;
        avoidWordsCtrl.text = tape.avoidWords;
        advancedDescriptionCtrl.text = tape.advancedDescription;
        premadeCategory = true;
        keywordCtrl.text = tape.keyword;
      });
    } else {
      setState(() {
        premadeCategory = true;
        keywordCtrl.text = tape.keyword;
      });
    }

    await _searchVideo();
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

  void _openAddTapeDialog() {
    final codeCtrl = TextEditingController();
    bool isAdding = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> addTape() async {
            final shareCode = _normalizeShareCode(codeCtrl.text);
            if (shareCode.isEmpty || isAdding) return;

            setDialogState(() => isAdding = true);

            Map<String, dynamic>? data;
            try {
              data = await CategoryService().loadCategoryByCode(shareCode);
            } catch (error) {
              if (!ctx.mounted) return;
              setDialogState(() => isAdding = false);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Failed to add tape: $error')),
              );
              return;
            }

            if (!ctx.mounted) return;

            if (data == null) {
              setDialogState(() => isAdding = false);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Code not found. Double-check and try again.'),
                ),
              );
              return;
            }

            final tape = _buildSharedCategoryTape(shareCode, data);
            if (tape == null) {
              setDialogState(() => isAdding = false);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('That code does not include a playable tape.'),
                ),
              );
              return;
            }

            if (!mounted) return;
            setState(() {
              _addedTapes.removeWhere(
                (addedTape) => addedTape.shareCode == tape.shareCode,
              );
              _addedTapes.insert(0, tape);
            });

            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added ${tape.title} to Start Watching.')),
            );
          }

          return Dialog(
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
                            'Add Tape',
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
                    const RetroWindowBar(title: 'ADD_TAPE.EXE'),
                    const SizedBox(height: 14),
                    Text(
                      'Enter a share code to add it to Start Watching.',
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
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => addTape(),
                      decoration: const InputDecoration(
                        labelText: 'Share code',
                        hintText: 'LF7-X2K',
                        prefixIcon: Icon(Icons.add_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 154,
                        child: isAdding
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : RetroButton(
                                label: 'Add tape',
                                icon: Icons.add_rounded,
                                onPressed: addTape,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(codeCtrl.dispose);
  }

  void _openImportDialog() {
    final codeCtrl = TextEditingController();
    bool isImporting = false;

    showDialog<void>(
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
                                final shareCode = _normalizeShareCode(
                                  codeCtrl.text,
                                );
                                if (shareCode.isEmpty) return;
                                setDialogState(() => isImporting = true);

                                Map<String, dynamic>? data;
                                try {
                                  data = await CategoryService()
                                      .loadCategoryByCode(shareCode);
                                } catch (error) {
                                  if (!ctx.mounted) return;
                                  setDialogState(() => isImporting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to import: $error'),
                                    ),
                                  );
                                  return;
                                }

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

                                if (!mounted) return;
                                setState(() {
                                  kidsMode = _readCategoryBool(
                                    data!,
                                    'kidsMode',
                                    false,
                                  );
                                  selectedDuration = _readCategoryText(
                                    data,
                                    'duration',
                                    'any',
                                  );
                                  selectedVideoType = _readCategoryText(
                                    data,
                                    'videoType',
                                    'Any',
                                  );
                                  filterClickbait = _readCategoryBool(
                                    data,
                                    'filterClickbait',
                                    true,
                                  );
                                  avoidWordsCtrl.text = _readCategoryText(
                                    data,
                                    'avoidWords',
                                  );
                                  advancedDescriptionCtrl.text =
                                      _readCategoryText(
                                        data,
                                        'advancedDescription',
                                      );
                                  final keyword = _readCategoryText(
                                    data,
                                    'keyword',
                                  );
                                  if (keyword.isNotEmpty) {
                                    keywordCtrl.text = keyword;
                                  }
                                });

                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Loaded: ${_readCategoryText(data, 'name', 'Shared category')}',
                                    ),
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
    ).whenComplete(codeCtrl.dispose);
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
                  onPressed: _openAddTapeDialog,
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
                _buildFilterChip(
                  'Advanced search: ${advancedDescriptionCtrl.text.trim()}',
                ),
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
                addedTapes: _addedTapes,
                onTapePressed: _startWatchingTape,
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SharedCategoryTape extends TapeData {
  const _SharedCategoryTape({
    required this.shareCode,
    required this.kidsMode,
    required this.selectedDuration,
    required this.selectedVideoType,
    required this.filterClickbait,
    required this.avoidWords,
    required this.advancedDescription,
    required super.title,
    required super.keyword,
    required super.color,
    super.height = 176,
    super.width = 58,
  });

  final String shareCode;
  final bool kidsMode;
  final String selectedDuration;
  final String selectedVideoType;
  final bool filterClickbait;
  final String avoidWords;
  final String advancedDescription;
}
