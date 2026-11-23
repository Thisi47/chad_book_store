import 'package:chad_book_store/core/constants/app_constants.dart';
import 'package:chad_book_store/features/cart/presentation/cart_provider.dart';
import 'package:chad_book_store/features/products/data/products_repository.dart';
import 'package:chad_book_store/features/products/domain/book.dart';
import 'package:chad_book_store/features/products/presentation/widgets/book_card.dart';
import 'package:chad_book_store/core/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Future<List<Book>> _booksFuture;
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Tout';

  @override
  void initState() {
    super.initState();
    _booksFuture = ref.read(productsRepositoryProvider).getAllBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final cartCount = ref.watch(cartProvider).length;
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalInset = screenWidth >= 1100
        ? (screenWidth - 1000) / 2
        : screenWidth >= 700
        ? 40.0
        : 20.0;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            if (screenWidth >= 370) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  AppConstants.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mes favoris',
            onPressed: () => context.push('/favorites'),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          IconButton(
            tooltip: 'Mon panier',
            onPressed: () => context.push('/cart'),
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger le catalogue.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final books = snapshot.data ?? [];
          if (books.isEmpty) {
            return const Center(
              child: Text('Aucun livre disponible pour le moment.'),
            );
          }
          final categories = [
            'Tout',
            ...books
                .map((b) => b.category)
                .whereType<String>()
                .where((c) => c.trim().isNotEmpty)
                .toSet(),
          ];
          final filtered = books.where((book) {
            final matchesCategory =
                _category == 'Tout' || book.category == _category;
            final term = _query.trim().toLowerCase();
            final matchesSearch =
                term.isEmpty ||
                book.title.toLowerCase().contains(term) ||
                book.author.toLowerCase().contains(term) ||
                (book.category?.toLowerCase().contains(term) ?? false);
            return matchesCategory && matchesSearch;
          }).toList();
          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset,
                    12,
                    horizontalInset,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BONJOUR${user == null ? '' : ' ${user.userMetadata?['full_name']?.toString().split(' ').first ?? ''}'}',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.7,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Une histoire vous attend.',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.08,
                              letterSpacing: -1,
                            ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Titre, auteur, catégorie…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 21),
                      if (_query.isEmpty && _category == 'Tout')
                        _FeaturedBook(
                          book: books.first,
                          onTap: () =>
                              context.push('/details', extra: books.first),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Explorer par genre',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '${filtered.length} livres',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _query.isNotEmpty
                            ? 'Résultats'
                            : _category == 'Tout'
                            ? 'À découvrir'
                            : _category,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Aucun livre ne correspond à votre recherche.'),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset,
                    0,
                    horizontalInset,
                    24,
                  ),
                  sliver: SliverGrid.builder(
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth >= 1000
                          ? 4
                          : screenWidth >= 650
                          ? 3
                          : 2,
                      childAspectRatio:
                          MediaQuery.textScalerOf(context).scale(1) > 1.2
                          ? (screenWidth >= 650 ? .56 : .48)
                          : screenWidth >= 650
                          ? .66
                          : .57,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) => BookCard(
                      book: filtered[index],
                      onTap: () =>
                          context.push('/details', extra: filtered[index]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
    );
  }
}

class _FeaturedBook extends StatelessWidget {
  const _FeaturedBook({required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 188),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'LE LIVRE DU MOMENT',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        book.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Text(
                            'Découvrir',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 108,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: book.coverUrl == null
                        ? Container(
                            color: Colors.white12,
                            child: const Icon(
                              Icons.auto_stories,
                              color: Colors.white,
                              size: 38,
                            ),
                          )
                        : Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: Colors.white12,
                              child: const Icon(
                                Icons.auto_stories,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
