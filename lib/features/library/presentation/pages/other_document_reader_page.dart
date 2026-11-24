import 'dart:convert';
import 'dart:async';

import 'package:chad_book_store/features/cart/data/order_repository.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:chad_book_store/features/library/data/reading_progress_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final readingSourceProvider = FutureProvider.autoDispose
    .family<ReadingSource, String>((ref, bookId) {
      return ref.read(orderRepositoryProvider).getReadingSource(bookId);
    });

class OtherDocumentReaderPage extends ConsumerStatefulWidget {
  const OtherDocumentReaderPage({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<OtherDocumentReaderPage> createState() =>
      _OtherDocumentReaderPageState();
}

class _OtherDocumentReaderPageState
    extends ConsumerState<OtherDocumentReaderPage> {
  final _epubController = EpubController();
  String? _error;
  late final String? _userId;
  late final Future<ReaderPreferences> _preferences;
  Timer? _saveTimer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _preferences = _userId == null
        ? Future.value(
            const ReaderPreferences(
              layout: PdfReadingLayout.continuous,
              initialPage: 1,
            ),
          )
        : ref
              .read(readingProgressRepositoryProvider)
              .getPreferences(userId: _userId, bookId: widget.book.id);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  void _onEpubRelocated(EpubLocation location) {
    if (!mounted) return;
    setState(() => _progress = location.progress.clamp(0.0, 1.0));
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      final userId = _userId;
      if (userId == null) return;
      final current = await _epubController.getCurrentLocation();
      await ref
          .read(readingProgressRepositoryProvider)
          .saveEpubProgress(
            userId: userId,
            bookId: widget.book.id,
            cfi: current.startCfi,
            fraction: current.progress,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(readingSourceProvider(widget.book.id));
    final extension = widget.book.readingPath?.split('.').last.toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (extension == 'epub')
            Center(child: Text('${(_progress * 100).round()}%')),
          if (extension == 'epub') ...[
            IconButton(
              tooltip: 'Chapitre précédent',
              onPressed: _epubController.prev,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Chapitre suivant',
              onPressed: _epubController.next,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ],
      ),
      body: source.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ReaderMessage(
          icon: Icons.cloud_off_rounded,
          message:
              'Impossible de récupérer ce document. Vérifiez votre connexion puis réessayez.',
          onRetry: () => ref.invalidate(readingSourceProvider(widget.book.id)),
        ),
        data: (document) {
          if (_error != null) {
            return _ReaderMessage(
              icon: Icons.menu_book_outlined,
              message: 'Ce fichier EPUB semble invalide ou incomplet.',
            );
          }
          if (!{'epub', 'txt', 'md', 'markdown'}.contains(document.extension)) {
            return _ReaderMessage(
              icon: Icons.insert_drive_file_outlined,
              message:
                  'Le format .${document.extension} n’est pas encore pris en charge. Formats disponibles : EPUB, PDF, TXT et Markdown.',
            );
          }
          if (document.extension == 'epub') {
            return FutureBuilder<ReaderPreferences>(
              future: _preferences,
              builder: (context, saved) {
                if (!saved.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return EpubViewer(
                  epubController: _epubController,
                  epubSource: EpubSource.fromUrl(document.url),
                  initialCfi: saved.data!.epubCfi,
                  onRelocated: _onEpubRelocated,
                  displaySettings: EpubDisplaySettings(
                    fontSize: 18,
                    flow: EpubFlow.scrolled,
                    theme: Theme.of(context).brightness == Brightness.dark
                        ? EpubTheme.dark()
                        : EpubTheme.light(),
                  ),
                  onLoadError: (error) {
                    if (mounted) setState(() => _error = error.message);
                  },
                );
              },
            );
          }
          return _TextDocument(
            url: document.url,
            markdown: document.extension != 'txt',
          );
        },
      ),
    );
  }
}

class _TextDocument extends StatefulWidget {
  const _TextDocument({required this.url, required this.markdown});
  final String url;
  final bool markdown;

  @override
  State<_TextDocument> createState() => _TextDocumentState();
}

class _TextDocumentState extends State<_TextDocument> {
  late Future<String> _content;

  @override
  void initState() {
    super.initState();
    _content = _load();
  }

  Future<String> _load() async {
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Le document est temporairement indisponible.');
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _content,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _ReaderMessage(
          icon: Icons.wifi_off_rounded,
          message:
              'Le document texte ne peut pas être chargé. Réessayez quand la connexion sera disponible.',
          onRetry: () => setState(() => _content = _load()),
        );
      }
      return SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: widget.markdown
                  ? MarkdownBody(data: snapshot.data ?? '')
                  : Text(
                      snapshot.data ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.75,
                        fontSize: 18,
                      ),
                    ),
            ),
          ),
        ),
      );
    },
  );
}

class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: colors.primary),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
