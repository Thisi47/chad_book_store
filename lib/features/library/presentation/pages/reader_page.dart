import 'package:chad_book_store/features/cart/data/order_repository.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

final readingUrlProvider = FutureProvider.autoDispose.family<String, String>((
  ref,
  bookId,
) {
  return ref.read(orderRepositoryProvider).getReadingUrl(bookId);
});

class ReaderPage extends ConsumerWidget {
  const ReaderPage({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingUrl = ref.watch(readingUrlProvider(book.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: readingUrl.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Impossible d’ouvrir ce livre : $error'),
          ),
        ),
        data: (url) => SfPdfViewer.network(url),
      ),
    );
  }
}
