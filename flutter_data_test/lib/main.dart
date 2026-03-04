import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'pages/youtube_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: KeyWordPage());
  }
}

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
  static const String apiKey = "AIzaSyDqP2aEOMm_GJPGoHrz8M65KWzz09-jbBk";
  final unescape = HtmlUnescape();

  @override
  void dispose() {
    keywordCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>?> fetchFirstVideo(String keyword) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'q': keyword,
      'type': 'video',
      'maxResults': '5',
      'videoEmbeddable': 'true',
      'key': apiKey,
    });

    final res = await http.get(uri);
    final data = jsonDecode(res.body);

    final allItems = data['items'];

    for (final item in allItems) {
      
      if (item['id'] is! Map<String, dynamic>) continue;
      if (item['snippet'] is! Map<String, dynamic>) continue;

      final videoId = item['id']['videoId'];
      final videoTitle = item['snippet']['title'];

      if ((videoId is String && videoId.isNotEmpty) && (videoTitle is String && videoTitle.isNotEmpty)) {
        final videoUrl = "https://www.youtube.com/watch?v=$videoId";
        return {'videoId': videoId, 'title': videoTitle, 'url': videoUrl};
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Youtube Player")),
      body: Padding(
        padding: EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: keywordCtrl,
              decoration: InputDecoration(
                labelText: "Search",
                hintText: "e.g. lo-fi beats",
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final keyword = keywordCtrl.text.trim();

                if (keyword.isEmpty) {
                  return;
                }

                final nav = Navigator.of(context);

                final result = await fetchFirstVideo(keyword);

                if (result == null) {
                  setState(() {
                    videoTitle = null;
                    videoUrl = null;
                    videoId = null;
                  });
                  return;
                }

                final id = result['videoId']!;
                final title = unescape.convert(result['title'] ?? '');
                final url = result['url']!;

                setState(() {
                  videoTitle = title;
                  videoUrl = url;
                  videoId = id;
                });

                nav.push(
                  MaterialPageRoute(
                    builder: (_) =>
                        YoutubePage(videoId: id, title: title, url: url),
                  ),
                );
              },

              child: Text("Button"),
            ),
            SizedBox(height: 10),
            if (videoTitle != null) Text("Title: $videoTitle"),
            SizedBox(height: 10),
            if (videoUrl != null) Text("Link: $videoUrl"),
          ],
        ),
      ),
    );
  }
}
