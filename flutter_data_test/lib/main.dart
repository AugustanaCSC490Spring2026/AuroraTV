import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'pages/youtube_page.dart';
import 'pages/auth_page.dart';
import 'config/api_keys.dart';
import 'firebase_options.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

const Color auroraMint = Color(0xFFC5FDD3);
const Color auroraLight = Color(0xFF94E1B4);
const Color auroraGreen = Color(0xFF69C5A0);
const Color auroraTeal = Color(0xFF45A994);
const Color auroraBlueTeal = Color(0xFF288D8A);
const Color auroraDeep = Color(0xFF126171);
const Color auroraNavy = Color(0xFF033854);
const Color auroraPanel = Color(0xFF08263D);
const Color auroraGlow = Color(0xFF5EF2D6);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const KeyWordPage();
          }

          return const AuthPage();
        },
      ),
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
  bool premadeCategory = false;

  late final GenerativeModel model;
  final unescape = HtmlUnescape();

  @override
  void initState() {
    super.initState();
    model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: geminiApiKey,
    );
  }

  @override
  void dispose() {
    keywordCtrl.dispose();
    super.dispose();
  }

  Widget buildFeaturedChannels() {
    final channels = [
      {
        "title": "Lo-fi",
        "keyword": "lofi hip hop radio",
        "icon": Icons.music_note,
      },
      {"title": "News", "keyword": "live news", "icon": Icons.public},
      {
        "title": "Gaming",
        "keyword": "live gaming stream",
        "icon": Icons.sports_esports,
      },
      {
        "title": "Nature",
        "keyword": "nature live cam",
        "icon": Icons.landscape,
      },
      {"title": "Podcasts", "keyword": "live podcast", "icon": Icons.mic},
      {"title": "Throwbacks", "keyword": "80s music live", "icon": Icons.album},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Start Watching",
          style: TextStyle(
            color: auroraMint,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: channels.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final channel = channels[index];

            return GestureDetector(
              onTap: () async {
                premadeCategory = true;
                keywordCtrl.text = channel["keyword"] as String;
                await _searchVideo();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: auroraPanel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: auroraDeep),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      channel["icon"] as IconData,
                      color: auroraGlow,
                      size: 34,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      channel["title"] as String,
                      style: const TextStyle(
                        color: auroraMint,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

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
      // do this idk bruh !!!!
      keyword = await _editText(keyword);
    }
    premadeCategory = false;

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

    final selectedKeyword = await nav.push<String>(
      MaterialPageRoute(builder: (_) => YoutubePage(videos: result)),
    );

    if (selectedKeyword != null && selectedKeyword.isNotEmpty) {
      keywordCtrl.text = selectedKeyword;
      await _searchVideo();
    }
  }

  Future<String> _editText(keyword) async {
    debugPrint("Gemini used");
    try {
      final response = await model.generateContent([
        Content.text(
          'Turn this into an optimized YouTube search query. Keep it short, natural, and focused on the main topic. Return only the search query, with no explanation or quotation marks:\n\n$keyword',
        ),
      ]);

      final shaped = (response.text ?? '').trim();
      debugPrint(shaped);
      if (shaped.isEmpty) return keyword;
      return shaped;
    } catch (e) {
      debugPrint('Gemini error: $e');
      return keyword;
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
                  buildFeaturedChannels(),
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
