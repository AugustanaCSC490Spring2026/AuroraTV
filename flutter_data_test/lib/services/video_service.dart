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

    final videos = <Map<String, String>>[];

    for (final item in allItems) {
      if (item['id'] is! Map<String, dynamic>) continue;
      if (item['snippet'] is! Map<String, dynamic>) continue;

      final videoId = item['id']['videoId'];
      final videoTitle = item['snippet']['title'];

      if ((videoId is String && videoId.isNotEmpty) &&
          (videoTitle is String && videoTitle.isNotEmpty)) {
        if (excludedVideoIds.contains(videoId)) continue;

        final title = unescape.convert(videoTitle);
        if (filterClickbait && _isClickbait(title)) continue;

        final videoUrl = "https://www.youtube.com/watch?v=$videoId";
        videos.add({'videoId': videoId, 'title': title, 'url': videoUrl});
      }
    }

    videos.shuffle();
    return videos.isEmpty ? null : videos.first;
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
