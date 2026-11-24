import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PdfReadingLayout { continuous, pageByPage }

class ReadingProgress {
  const ReadingProgress({
    required this.bookId,
    required this.page,
    required this.totalPages,
    required this.updatedAt,
  });

  final String bookId;
  final int page;
  final int totalPages;
  final DateTime updatedAt;

  double get fraction => totalPages <= 0 ? 0 : page / totalPages;
}

class ReaderPreferences {
  const ReaderPreferences({
    required this.layout,
    required this.initialPage,
    this.epubCfi,
  });

  final PdfReadingLayout layout;
  final int initialPage;
  final String? epubCfi;
}

final readingProgressRepositoryProvider = Provider<ReadingProgressRepository>(
  (ref) => ReadingProgressRepository(),
);

final lastReadingProgressProvider = FutureProvider.autoDispose
    .family<ReadingProgress?, String>((ref, userId) {
      return ref
          .watch(readingProgressRepositoryProvider)
          .getLastProgress(userId);
    });

class ReadingProgressRepository {
  static const _lastBookPrefix = 'reading.lastBook.';
  static const _layoutPrefix = 'reading.layout.';

  String _bookPrefix(String userId, String bookId) =>
      'reading.$userId.$bookId.';

  Future<ReaderPreferences> getPreferences({
    required String userId,
    required String bookId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = _bookPrefix(userId, bookId);
    final layout = prefs.getString('$_layoutPrefix$userId');
    return ReaderPreferences(
      layout: layout == 'pageByPage'
          ? PdfReadingLayout.pageByPage
          : PdfReadingLayout.continuous,
      initialPage: (prefs.getInt('${prefix}page') ?? 1)
          .clamp(1, 1000000)
          .toInt(),
      epubCfi: prefs.getString('${prefix}epubCfi'),
    );
  }

  Future<void> saveLayout({
    required String userId,
    required PdfReadingLayout layout,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_layoutPrefix$userId', layout.name);
  }

  Future<void> saveProgress({
    required String userId,
    required String bookId,
    required int page,
    required int totalPages,
  }) async {
    if (page < 1) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = _bookPrefix(userId, bookId);
    await Future.wait([
      prefs.setInt('${prefix}page', page),
      prefs.setInt('${prefix}totalPages', totalPages),
      prefs.setInt('${prefix}updatedAt', DateTime.now().millisecondsSinceEpoch),
      prefs.setString('$_lastBookPrefix$userId', bookId),
    ]);
  }

  Future<void> saveEpubProgress({
    required String userId,
    required String bookId,
    required String cfi,
    required double fraction,
  }) async {
    if (cfi.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = _bookPrefix(userId, bookId);
    final percent = (fraction.clamp(0.0, 1.0) * 100).round().clamp(1, 100);
    await Future.wait([
      prefs.setString('${prefix}epubCfi', cfi),
      prefs.setInt('${prefix}page', percent),
      prefs.setInt('${prefix}totalPages', 100),
      prefs.setInt('${prefix}updatedAt', DateTime.now().millisecondsSinceEpoch),
      prefs.setString('$_lastBookPrefix$userId', bookId),
    ]);
  }

  Future<ReadingProgress?> getLastProgress(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookId = prefs.getString('$_lastBookPrefix$userId');
    if (bookId == null) return null;

    final prefix = _bookPrefix(userId, bookId);
    final page = prefs.getInt('${prefix}page');
    if (page == null) return null;

    return ReadingProgress(
      bookId: bookId,
      page: page,
      totalPages: prefs.getInt('${prefix}totalPages') ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('${prefix}updatedAt') ?? 0,
      ),
    );
  }
}
