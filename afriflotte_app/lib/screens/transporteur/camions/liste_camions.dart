import 'package:flutter/material.dart';

import '../../../constants/pays_cedeao.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/camion.dart';
import '../../../services/camion_service.dart';
import '../../../widgets/liquid_bottom_nav.dart';
import 'ajouter_camion.dart';
import 'gerer_photos_camion.dart';

const _bleuNuit = Color(0xFF102C5C);

class ListeCamions extends StatefulWidget {
  final String token;

  // Filtre pré-sélectionné à l'ouverture, ex. depuis la carte "Disponibles"
  // du dashboard transporteur. Une des clés de `_filtres` ('TOUS' par
  // défaut) ; voir _appliquerFiltre.
  final String? initialFilter;

  const ListeCamions({super.key, required this.token, this.initialFilter});

  @override
  State<ListeCamions> createState() => _ListeCamionsState();
}

class _ListeCamionsState extends State<ListeCamions> {
  List<Camion> camions = [];
  bool loading = true;
  String? erreur;
  late String _filtre;

  final TextEditingController _searchController = TextEditingController();

  static const _filtres = ['TOUS', 'DISPONIBLE', 'INDISPONIBLE'];

  @override
  void initState() {
    super.initState();
    _filtre = widget.initialFilter ?? 'TOUS';
    chargerCamions();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Camion> _appliquerFiltre(List<Camion> source) {
    Iterable<Camion> filtres = source;

    switch (_filtre) {
      case 'DISPONIBLE':
        filtres = filtres.where((c) => c.disponible);
        break;
      case 'INDISPONIBLE':
        filtres = filtres.where((c) => !c.disponible);
        break;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtres = filtres.where(
        (c) =>
            c.immatriculation.toLowerCase().contains(query) ||
            c.marque.toLowerCase().contains(query) ||
            c.modele.toLowerCase().contains(query) ||
            c.ville.toLowerCase().contains(query),
      );
    }

    return filtres.toList();
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  String _libelleFiltre(AppLocalizations l10n, String filtre) {
    switch (filtre) {
      case 'DISPONIBLE':
        return l10n.camionsAvailable;
      case 'INDISPONIBLE':
        return l10n.camionsUnavailable;
      default:
        return l10n.demandesFilterAll;
    }
  }

  Future<void> chargerCamions() async {
    setState(() {
      loading = true;
      erreur = null;
    });

    try {
      final result = await CamionService.getCamions(widget.token);

      if (mounted) {
        setState(() {
          camions = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          erreur = '$e'.replaceFirst('Exception: ', '');
          loading = false;
        });
      }
    }
  }

  Future<void> _ajouter() async {
    final retour = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterCamion(token: widget.token),
      ),
    );

    if (retour == true) chargerCamions();
  }

  Future<void> _modifier(Camion camion) async {
    final retour = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AjouterCamion(token: widget.token, camion: camion),
      ),
    );

    if (retour == true) chargerCamions();
  }

  Future<void> _gererPhotos(Camion camion) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GererPhotosCamion(token: widget.token, camion: camion),
      ),
    );
    chargerCamions();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.camionsTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            onPressed: chargerCamions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom:
              LiquidBottomNav.height + MediaQuery.of(context).padding.bottom,
        ),
        child: FloatingActionButton(
          onPressed: _ajouter,
          child: const Icon(Icons.add),
        ),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 52,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 14),
              Text(
                erreur!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: chargerCamions,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.commonRetry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bleuNuit,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (camions.isEmpty) {
      return RefreshIndicator(
        onRefresh: chargerCamions,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.camionsEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.camionsEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final visibles = _appliquerFiltre(camions);

    return Column(
      children: [
        _buildSearchField(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: _filtres.map((filtre) {
              final actif = filtre == _filtre;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_libelleFiltre(l10n, filtre)),
                  selected: actif,
                  onSelected: (_) => setState(() => _filtre = filtre),
                  selectedColor: _bleuNuit,
                  labelStyle: TextStyle(
                    color: actif ? Colors.white : _bleuNuit,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  side: BorderSide(
                    color: actif ? _bleuNuit : Colors.grey.shade300,
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: visibles.isEmpty
              ? Center(
                  child: Text(
                    l10n.demandesNoneFound,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: chargerCamions,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: visibles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _CamionCard(
                      camion: visibles[index],
                      onTap: () => _modifier(visibles[index]),
                      onGererPhotos: () => _gererPhotos(visibles[index]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CamionCard extends StatelessWidget {
  final Camion camion;
  final VoidCallback onTap;
  final VoidCallback onGererPhotos;

  const _CamionCard({
    required this.camion,
    required this.onTap,
    required this.onGererPhotos,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: camion.imagePrincipaleUrl != null
                  ? Image.network(
                      camion.imagePrincipaleUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _iconePlaceholder(context),
                    )
                  : _iconePlaceholder(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    camion.immatriculation,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${camion.marque} ${camion.modele} · ${camion.typeCamion}'
                        .trim(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${camion.ville}, ${nomParPays(camion.pays) ?? camion.pays}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Badge(
                        texte: camion.disponible
                            ? l10n.camionsAvailable
                            : l10n.camionsUnavailable,
                        couleur: camion.disponible
                            ? const Color(0xFF34D399)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        texte:
                            '${camion.capacite.toStringAsFixed(0)} ${camion.uniteCapacite}',
                        couleur: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<void>(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: onTap,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(l10n.camionsEditInfo),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: onGererPhotos,
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 18),
                      const SizedBox(width: 10),
                      Text(l10n.camionsManagePhotos),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconePlaceholder(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.local_shipping_rounded, color: Colors.grey.shade400),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texte;
  final Color couleur;

  const _Badge({required this.texte, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texte,
        style: TextStyle(
          color: couleur,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
