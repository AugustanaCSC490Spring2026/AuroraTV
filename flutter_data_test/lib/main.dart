import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'pages/youtube_page.dart';
import 'config/api_keys.dart';

const Color auroraMint = Color(0xFFC5FDD3);
const Color auroraLight = Color(0xFF94E1B4);
const Color auroraGreen = Color(0xFF69C5A0);
const Color auroraTeal = Color(0xFF45A994);
const Color auroraBlueTeal = Color(0xFF288D8A);
const Color auroraDeep = Color(0xFF126171);
const Color auroraNavy = Color(0xFF033854);
const Color auroraPanel = Color(0xFF08263D);
const Color auroraGlow = Color(0xFF5EF2D6);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AuroraTv',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: auroraNavy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: auroraBlueTeal,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: auroraMint,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
          iconTheme: IconThemeData(color: auroraMint),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: auroraPanel,
          hintStyle: const TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: auroraLight),
          prefixIconColor: auroraGlow,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: auroraDeep, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: auroraGlow, width: 1.8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: auroraBlueTeal,
            foregroundColor: auroraMint,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
      home: const KeyWordPage(),
    );
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
  bool isLoading = false;

  final unescape = HtmlUnescape();

  @override
  void dispose() {
    keywordCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, String>>> fetchVideos(String keyword) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'q': keyword,
      'type': 'video',
      'maxResults': '10',
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

    return videos;
  }

  Future<void> _searchVideo() async {
  final keyword = keywordCtrl.text.trim();

  if (keyword.isEmpty) return;

  setState(() {
    isLoading = true;
  });

  final nav = Navigator.of(context);
  final result = await fetchVideos(keyword);

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

  nav.push(
    MaterialPageRoute(
      builder: (_) => YoutubePage(videos: result),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AuroraTv"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [auroraDeep, auroraNavy, Color(0xFF021C2E)],
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
                        TextField(
                          controller: keywordCtrl,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => _searchVideo(),
                          decoration: const InputDecoration(
                            labelText: "Search",
                            hintText: "e.g. lo-fi beats, synthwave, 80s hits",
                            prefixIcon: Icon(Icons.search),
                          ),
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
                  if (videoTitle != null || videoUrl != null)
                    Container(
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
                              videoTitle!,
                              style: const TextStyle(
                                color: auroraMint,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (videoUrl != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              videoUrl!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
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
