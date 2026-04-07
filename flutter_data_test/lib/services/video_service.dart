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

  Future<List<Map<String, String>>> fetchVideos(String keyword) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'q': keyword,
      'type': 'video',
      'maxResults': '20',
      'videoEmbeddable': 'true',
      'key': youtubeApiKey,
    });

    final res = await http.get(uri);
    final data = jsonDecode(res.body);
    final allItems = data['items'];

    List<Map<String, String>> videos = [];

    for (final item in allItems) {
      if (item['id'] is! Map<String, dynamic>) continue;
      if (item['snippet'] is! Map<String, dynamic>) continue;

      final videoId = item['id']['videoId'];
      final videoTitle = item['snippet']['title'];

      if ((videoId is String && videoId.isNotEmpty) &&
          (videoTitle is String && videoTitle.isNotEmpty)) {
        final videoUrl = "https://www.youtube.com/watch?v=$videoId";
        videos.add({
          'videoId': videoId,
          'title': unescape.convert(videoTitle),
          'url': videoUrl,
        });
      }
    }

    videos.shuffle();
    return videos;
  }
}
