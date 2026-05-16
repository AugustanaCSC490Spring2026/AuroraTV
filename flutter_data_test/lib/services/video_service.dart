// YouTube API video fetching service
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import '../config/api_keys.dart';

class VideoService {
  static final VideoService _instance = VideoService._internal();
  final unescape = HtmlUnescape();

  factory VideoService() {
    return _instance;
  }

  VideoService._internal();

  Future<Map<String, String>?> fetchVideo(
    String keyword, {
    bool kidsMode = false,
    String selectedDuration = 'any',
    bool filterClickbait = true,
    String avoidWords = '',
    String metadataContext = '',
    Set<String> excludedVideoIds = const {},
  }) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'q': keyword,
      'type': 'video',
      'maxResults': '25',
      'videoEmbeddable': 'true',
      'safeSearch': kidsMode ? 'strict' : 'moderate',
      'videoDuration': selectedDuration,
      'key': youtubeApiKey,
    });

    final res = await http.get(uri);
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) return null;

    final allItems = data['items'];
    if (allItems is! List) return null;

    final videosById = <String, Map<String, String>>{};

    for (final item in allItems) {
      if (item['id'] is! Map<String, dynamic>) continue;
      if (item['snippet'] is! Map<String, dynamic>) continue;

      final videoId = item['id']['videoId'];
      final snippet = item['snippet'] as Map<String, dynamic>;
      final videoTitle = snippet['title'];

      if ((videoId is String && videoId.isNotEmpty) &&
          (videoTitle is String && videoTitle.isNotEmpty)) {
        if (excludedVideoIds.contains(videoId)) continue;

        final title = unescape.convert(videoTitle);
        if (filterClickbait && _isClickbait(title)) continue;

        final videoUrl = "https://www.youtube.com/watch?v=$videoId";
        videosById[videoId] = {
          'videoId': videoId,
          'title': title,
          'url': videoUrl,
          'description': unescape.convert(snippet['description'] ?? ''),
          'channelTitle': unescape.convert(snippet['channelTitle'] ?? ''),
          'tags': '',
        };
      }
    }

    if (videosById.isEmpty) return null;

    await _hydrateVideoMetadata(videosById);

    final rankedVideos = _rankVideos(
      videosById.values.toList(),
      keyword: keyword,
      metadataContext: metadataContext,
      avoidWords: avoidWords,
    );

    return rankedVideos.isEmpty ? null : rankedVideos.first.video;
  }

  Future<void> _hydrateVideoMetadata(
    Map<String, Map<String, String>> videosById,
  ) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/videos', {
      'part': 'snippet',
      'id': videosById.keys.join(','),
      'key': youtubeApiKey,
    });

    final res = await http.get(uri);
    final data = jsonDecode(res.body);
    if (data is! Map<String, dynamic>) return;

    final items = data['items'];
    if (items is! List) return;

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'];
      final snippet = item['snippet'];
      if (id is! String || snippet is! Map<String, dynamic>) continue;

      final video = videosById[id];
      if (video == null) continue;

      final tags = snippet['tags'];
      video['description'] = unescape.convert(snippet['description'] ?? '');
      video['channelTitle'] = unescape.convert(snippet['channelTitle'] ?? '');
      video['tags'] = tags is List ? tags.join(' ') : '';
    }
  }

  List<_RankedVideo> _rankVideos(
    List<Map<String, String>> videos, {
    required String keyword,
    required String metadataContext,
    required String avoidWords,
  }) {
    final queryTerms = _termsFor('$keyword $metadataContext');
    final blockedTerms = _termsFor(avoidWords);
    final rankedVideos = <_RankedVideo>[];

    for (final video in videos) {
      final title = video['title']?.toLowerCase() ?? '';
      final description = video['description']?.toLowerCase() ?? '';
      final tags = video['tags']?.toLowerCase() ?? '';
      final searchableText = '$title $description $tags';

      if (blockedTerms.any(searchableText.contains)) continue;

      var score = 0;
      for (final term in queryTerms) {
        if (title.contains(term)) score += 6;
        if (tags.contains(term)) score += 4;
        if (description.contains(term)) score += 2;
      }

      if (queryTerms.isNotEmpty &&
          queryTerms.every((term) => searchableText.contains(term))) {
        score += 8;
      }

      rankedVideos.add(_RankedVideo(video: video, score: score));
    }

    rankedVideos.shuffle();
    rankedVideos.sort((a, b) => b.score.compareTo(a.score));
    return rankedVideos;
  }

  List<String> _termsFor(String text) {
    const stopWords = {
      'about',
      'after',
      'and',
      'are',
      'for',
      'from',
      'into',
      'the',
      'this',
      'that',
      'video',
      'videos',
      'with',
      'you',
      'your',
    };

    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((term) => term.length > 2 && !stopWords.contains(term))
        .toSet()
        .toList();
  }

  bool _isClickbait(String title) {
    // Convert to lowercase for case-insensitive checks
    final lowerTitle = title.toLowerCase();

    // Clickbait phrases
    final clickbaitPhrases = [
      'you won\'t believe',
      'you will not believe',
      'shocking',
      'unbelievable',
      'amazing',
      'incredible',
      'mind blowing',
      'blow your mind',
      'insane',
      'crazy',
      'epic',
      'ultimate',
      'secret',
      'hidden',
      'exposed',
      'revealed',
      'truth',
      'conspiracy',
      'scandal',
    ];

    for (final phrase in clickbaitPhrases) {
      if (lowerTitle.contains(phrase)) {
        return true;
      }
    }

    // Listicles: top/best followed by number
    final listicleRegex = RegExp(r'\b(top|best)\s+\d+\b', caseSensitive: false);
    if (listicleRegex.hasMatch(title)) {
      return true;
    }

    // Excessive caps: more than 70% of letters are uppercase
    final letters = RegExp(
      r'[a-zA-Z]',
    ).allMatches(title).map((m) => m.group(0)!);
    if (letters.isNotEmpty) {
      final upperCount = letters.where((c) => c == c.toUpperCase()).length;
      if (upperCount / letters.length > 0.7) {
        return true;
      }
    }

    // Emojis: check for characters in emoji Unicode ranges
    if (title.runes.any(
      (r) => r >= 0x1F300 && r <= 0x1F9FF || r >= 0x2600 && r <= 0x27BF,
    )) {
      return true;
    }

    // Multiple exclamation marks
    if (title.contains('!!') || title.contains('???')) {
      return true;
    }

    return false;
  }
}

class _RankedVideo {
  final Map<String, String> video;
  final int score;

  const _RankedVideo({required this.video, required this.score});
}
