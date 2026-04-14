import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final _db = FirebaseFirestore.instance;

  // Generates a code like "LF7-X2K"
  String _generateShareCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final part1 =
        List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    final part2 =
        List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    return '$part1-$part2';
  }

  Future<String> saveCategory({
    required String name,
    required String keyword,
    required bool kidsMode,
    required String duration,
    required String videoType,
    required String avoidWords,
    required String advancedDescription,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final shareCode = _generateShareCode();

    // 1. Save the full category document
    final ref = await _db.collection('shared_categories').add({
      'name': name,
      'keyword': keyword,
      'kidsMode': kidsMode,
      'duration': duration,
      'videoType': videoType,
      'avoidWords': avoidWords,
      'advancedDescription': advancedDescription,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'shareCode': shareCode,
      'timesUsed': 0,
    });

    // 2. Save reverse-lookup so we can find it instantly by code alone
    await _db.collection('share_codes').doc(shareCode).set({
      'categoryId': ref.id,
    });

    return shareCode;
  }

  Future<Map<String, dynamic>?> loadCategoryByCode(String code) async {
    final cleaned = code.toUpperCase().trim();

    // Fast lookup: share_codes/{code} → categoryId
    final codeSnap =
        await _db.collection('share_codes').doc(cleaned).get();
    if (!codeSnap.exists) return null;

    final categoryId = codeSnap['categoryId'] as String;

    // Fetch the actual category
    final catSnap =
        await _db.collection('shared_categories').doc(categoryId).get();
    if (!catSnap.exists) return null;

    // Bump usage counter in the background (don't await)
    catSnap.reference.update({'timesUsed': FieldValue.increment(1)});

    return catSnap.data();
  }
}