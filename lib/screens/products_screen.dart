import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/dress.dart';
import '../services/dress_service.dart';
import '../theme.dart';
import '../widgets/dress_card.dart';
import 'login_screen.dart';

/// Se mantiene el nombre ProductsScreen para que login_screen.dart
/// siga navegando aquí sin cambios. Ahora muestra el catálogo de vestidos.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _service = DressService();
  late Future<List<Dress>> _future;
  String _query = '';
  String _category = 'Todos';

  @override
  void initState() {
    super.initState();
    _future = _service.getAll();
  }

  void _reload() => setState(() => _future = _service.getAll());

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  List<Dress> _filter(List<Dress> all) {
    return all.where((d) {
      final matchCat = _category == 'Todos' || d.category == _category;
      final q = _query.trim().toLowerCase();
      final matchQ = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.color.toLowerCase().contains(q) ||
          d.size.toLowerCase() == q;
      return matchCat && matchQ;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.pink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.checkroom_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Catálogo Cherry',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.ink)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Dress>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.pink));
          }
          if (snap.hasError) {
            return _ErrorView(message: '${snap.error}', onRetry: _reload);
          }
          final all = snap.data ?? [];
          final categories = [
            'Todos',
            ...{for (final d in all) d.category}
          ];
          final shown = _filter(all);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, color o talla',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.pink, width: 2),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    final selected = c == _category;
                    return ChoiceChip(
                      label: Text(c),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = c),
                      selectedColor: AppColors.pink,
                      backgroundColor: Colors.white,
                      showCheckmark: false,
                      side: BorderSide(
                          color:
                              selected ? AppColors.pink : Colors.grey.shade300),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.ink,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Text('${shown.length} vestidos',
                        style: const TextStyle(color: AppColors.muted)),
                    const Spacer(),
                    if (ApiConfig.useMock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.pinkSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Modo demo',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.pinkDark)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? const Center(
                        child: Text('No encontramos vestidos con ese filtro',
                            style: TextStyle(color: AppColors.muted)))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: shown.length,
                        itemBuilder: (_, i) => DressCard(
                          dress: shown[i],
                          onTap: () => _showDetail(shown[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetail(Dress d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: DressImage(dress: d),
                ),
              ),
              const SizedBox(height: 18),
              Text(d.category.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.pink)),
              const SizedBox(height: 4),
              Text(d.name,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 10),
              Text(d.description,
                  style: const TextStyle(
                      height: 1.4, color: AppColors.muted, fontSize: 15)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                      icon: Icons.straighten_rounded, text: 'Talla ${d.size}'),
                  _InfoChip(icon: Icons.palette_rounded, text: d.color),
                  _InfoChip(
                      icon: Icons.inventory_2_rounded,
                      text: d.inStock ? '${d.stock} disponibles' : 'Agotado'),
                ],
              ),
              const SizedBox(height: 20),
              Text('\$${d.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.pinkDark),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.pinkDark)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.pink),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el catálogo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  minimumSize: const Size(160, 48)),
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
