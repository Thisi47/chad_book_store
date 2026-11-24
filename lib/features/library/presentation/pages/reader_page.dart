import 'dart:async';

import 'package:chad_book_store/features/cart/data/order_repository.dart';
import 'package:chad_book_store/features/library/data/reading_progress_repository.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

final readingUrlProvider = FutureProvider.autoDispose.family<String, String>((
  ref,
  bookId,
) {
  return ref.read(orderRepositoryProvider).getReadingUrl(bookId);
});

class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  final _controller = PdfViewerController();
  late final ReadingProgressRepository _progressRepository;
  late final String? _userId;
  late final Future<ReaderPreferences> _preferencesFuture;
  Timer? _saveTimer;
  PdfReadingLayout _layout = PdfReadingLayout.continuous;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _progressRepository = ref.read(readingProgressRepositoryProvider);
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _preferencesFuture = _loadPreferences();
  }

  Future<ReaderPreferences> _loadPreferences() async {
    final userId = _userId;
    if (userId == null) {
      return const ReaderPreferences(
        layout: PdfReadingLayout.continuous,
        initialPage: 1,
      );
    }
    final preferences = await _progressRepository.getPreferences(
      userId: userId,
      bookId: widget.book.id,
    );
    if (mounted) {
      setState(() {
        _layout = preferences.layout;
        _currentPage = preferences.initialPage;
      });
    }
    return preferences;
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() => _currentPage = details.newPageNumber);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _saveProgress);
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() => _totalPages = _controller.pageCount);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _saveProgress);
  }

  Future<void> _saveProgress() async {
    final userId = _userId;
    if (userId == null || _currentPage < 1) return;
    await _progressRepository.saveProgress(
      userId: userId,
      bookId: widget.book.id,
      page: _currentPage,
      totalPages: _totalPages,
    );
    if (mounted) ref.invalidate(lastReadingProgressProvider(userId));
  }

  Future<void> _showReadingSettings() async {
    final colors = Theme.of(context).colorScheme;
    final layout = await showModalBottomSheet<PdfReadingLayout>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confort de lecture',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez comment parcourir les pages.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _LayoutOption(
                icon: Icons.swap_vert_rounded,
                title: 'Défilement continu',
                subtitle: 'Faites défiler les pages de haut en bas.',
                selected: _layout == PdfReadingLayout.continuous,
                onTap: () =>
                    Navigator.of(sheetContext).pop(PdfReadingLayout.continuous),
              ),
              _LayoutOption(
                icon: Icons.menu_book_rounded,
                title: 'Page par page',
                subtitle: 'Parcourez le livre avec un geste horizontal.',
                selected: _layout == PdfReadingLayout.pageByPage,
                onTap: () =>
                    Navigator.of(sheetContext).pop(PdfReadingLayout.pageByPage),
              ),
            ],
          ),
        ),
      ),
    );

    if (layout == null || layout == _layout) return;
    setState(() => _layout = layout);
    final userId = _userId;
    if (userId != null) {
      await _progressRepository.saveLayout(userId: userId, layout: layout);
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_userId != null && _currentPage > 1) {
      unawaited(
        _progressRepository.saveProgress(
          userId: _userId,
          bookId: widget.book.id,
          page: _currentPage,
          totalPages: _totalPages,
        ),
      );
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readingUrl = ref.watch(readingUrlProvider(widget.book.id));
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Confort de lecture',
            onPressed: _showReadingSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: FutureBuilder<ReaderPreferences>(
        future: _preferencesFuture,
        builder: (context, preferencesSnapshot) {
          if (!preferencesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final preferences = preferencesSnapshot.data!;
          return readingUrl.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 42,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Impossible d’ouvrir ce livre pour le moment.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          ref.invalidate(readingUrlProvider(widget.book.id)),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
            data: (url) => SfPdfViewer.network(
              url,
              controller: _controller,
              initialPageNumber: preferences.initialPage,
              pageLayoutMode: _layout == PdfReadingLayout.pageByPage
                  ? PdfPageLayoutMode.single
                  : PdfPageLayoutMode.continuous,
              scrollDirection: _layout == PdfReadingLayout.pageByPage
                  ? PdfScrollDirection.horizontal
                  : PdfScrollDirection.vertical,
              canShowScrollStatus: false,
              onPageChanged: _onPageChanged,
              onDocumentLoaded: _onDocumentLoaded,
            ),
          );
        },
      ),
      bottomNavigationBar: _ReadingProgressBar(
        page: _currentPage,
        totalPages: _totalPages,
        onPrevious: _currentPage > 1 ? _controller.previousPage : null,
        onNext: _totalPages > _currentPage ? _controller.nextPage : null,
      ),
    );
  }
}

class _ReadingProgressBar extends StatelessWidget {
  const _ReadingProgressBar({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = totalPages > 0 ? (page / totalPages).clamp(0.0, 1.0) : 0.0;
    return Material(
      color: colors.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Page précédente',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      totalPages > 0 ? 'Page $page sur $totalPages' : 'Lecture',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(value: progress),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Page suivante',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutOption extends StatelessWidget {
  const _LayoutOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: selected ? colors.secondaryContainer : null,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: selected ? colors.primary : null),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: colors.primary)
            : null,
      ),
    );
  }
}
