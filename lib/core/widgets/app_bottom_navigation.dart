import 'package:chad_book_store/features/cart/presentation/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppBottomNavigation extends ConsumerWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final cartCount = ref.watch(cartProvider).length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: .45)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 7, 5, 4),
          child: Row(
            children: [
              _NavigationItem(
                icon: Icons.storefront_outlined,
                selectedIcon: Icons.storefront,
                label: 'Accueil',
                selected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavigationItem(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book,
                label: 'Lire',
                selected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              Expanded(
                child: _CartNavigationItem(
                  count: cartCount,
                  selected: selectedIndex == 2,
                  onTap: () => onDestinationSelected(2),
                ),
              ),
              _NavigationItem(
                icon: Icons.favorite_border,
                selectedIcon: Icons.favorite,
                label: 'Favoris',
                selected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
              _NavigationItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profil',
                selected: selectedIndex == 4,
                onTap: () => onDestinationSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 23,
                  color: foreground,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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

class _CartNavigationItem extends StatelessWidget {
  const _CartNavigationItem({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: count == 0 ? 'Panier' : 'Panier, $count articles',
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: SizedBox(
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: count > 0,
                label: Text(count > 9 ? '9+' : '$count'),
                child: Container(
                  width: 44,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: colors.onPrimary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Panier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
