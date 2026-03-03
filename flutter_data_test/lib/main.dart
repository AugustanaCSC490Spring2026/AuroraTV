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
  static const String apiKey = "AIzaSyDplFBfQ-3sBe2nxOXZuS08Jvn7iIgmjxM";
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
      'maxResults': '1',
      'videoEmbeddable': 'true',
      'key': apiKey,
    });

    final res = await http.get(uri);

    final data = jsonDecode(res.body);
    final items = (data['items'] as List).cast<Map<String, dynamic>>();

    final firstItem = items[0];

    final videoId = firstItem['id']['videoId'] as String;
    final title = firstItem['snippet']['title'] as String;
    final videoUrl = "https://www.youtube.com/watch?v=$videoId";

    return {'videoId': videoId, 'title': title, 'url': videoUrl};
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
