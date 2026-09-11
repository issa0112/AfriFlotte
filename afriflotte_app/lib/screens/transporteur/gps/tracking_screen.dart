import 'package:flutter/material.dart';

import '../../../constants/fraicheur.dart';
import '../../../constants/pays_cedeao.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/camion_recherche.dart';
import '../../../services/recherche_camion_service.dart';
import '../../../utils/telephone.dart';
import 'camion_map_screen.dart';

const _bleuFonce = Color(0xFF071A3A);
const _bleuNuit = Color(0xFF102C5C);

String _formatDuree(AppLocalizations l10n, Duration duree) {
  if (duree.inMinutes < 1) return l10n.gpsJustNow;
  if (duree.inHours < 1) return l10n.gpsAgoMinutes(duree.inMinutes);
  if (duree.inDays < 1) {
    final minutesRestantes = duree.inMinutes % 60;
    return l10n.gpsAgoHoursMinutes(
      duree.inHours,
      minutesRestantes.toString().padLeft(2, '0'),
    );
  }
  return l10n.gpsAgoDays(duree.inDays);
}

/// Localisation de la flotte du transporteur : où sont ses camions/chauffeurs
/// en ce moment, avec la fraîcheur de chaque position (cf.
/// `resoudre_position_camion` côté Django, `/api/transporteur/flotte-positions/`).
/// Remplace l'ancien écran qui utilisait à tort le GPS du téléphone du
/// TRANSPORTEUR lui-même avec des métriques factices (vitesse/batterie/signal
/// codées en dur) — ce que le transporteur veut suivre, ce sont ses
/// camions/chauffeurs, pas sa propre position.
class GpsTransportScreen extends StatefulWidget {
  final String token;

  const GpsTransportScreen({super.key, required this.token});

  @override
  State<GpsTransportScreen> createState() => _GpsTransportScreenState();
}

class _GpsTransportScreenState extends State<GpsTransportScreen> {
  late Future<List<CamionRecherche>> _futureFlotte;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureFlotte = RechercheCamionService.mesPositionsFlotte(widget.token);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField() {
    return TextField(
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
    );
  }

  Future<void> _rafraichir() async {
    final future = RechercheCamionService.mesPositionsFlotte(widget.token);
    setState(() {
      _futureFlotte = future;
    });
    await future.catchError((_) => <CamionRecherche>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Dégradé vertical (pas diagonal) : au niveau de la barre de nav
          // flottante tout en bas, la couleur doit être uniforme sur toute
          // la largeur pour raccorder exactement avec le bleu uni de la
          // barre (`_navyMid` dans LiquidBottomNav, identique à `_bleuNuit`)
          // — en diagonal, seul le coin bas-droit atteignait cette teinte,
          // le reste de la barre tranchait sur un fond encore plus sombre.
          gradient: LinearGradient(
            colors: [_bleuFonce, _bleuNuit],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // `bottom: false` : avec `Scaffold(extendBody: true)`, un SafeArea
        // classique récupère un `MediaQuery.padding.bottom` artificiellement
        // égal à la hauteur de LiquidBottomNav et réserve cet espace — la
        // liste ne peut alors jamais défiler jusqu'à la zone qui passe
        // derrière la barre. La ListView gère déjà son propre padding bas
        // (100) pour ne pas finir sous la barre.
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 6),
                child: _EnTete(),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<CamionRecherche>>(
      future: _futureFlotte,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          );
        }

        if (snapshot.hasError) {
          return _EtatMessage(
            icon: Icons.wifi_off_rounded,
            message: '${snapshot.error}'.replaceFirst('Exception: ', ''),
            onRetry: _rafraichir,
          );
        }

        final flotte = snapshot.data ?? const <CamionRecherche>[];

        if (flotte.isEmpty) {
          return _EtatMessage(
            icon: Icons.local_shipping_outlined,
            message: AppLocalizations.of(context).gpsEmptyTitle,
            onRetry: _rafraichir,
          );
        }

        final query = _searchController.text.trim().toLowerCase();
        final visibles = query.isEmpty
            ? flotte
            : flotte.where((c) {
                final chauffeurNom = c.chauffeurActuel?.nom.toLowerCase() ?? '';
                return c.immatriculation.toLowerCase().contains(query) ||
                    c.ville.toLowerCase().contains(query) ||
                    chauffeurNom.contains(query);
              }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: _buildSearchField(),
            ),
            Expanded(
              child: visibles.isEmpty
                  ? _EtatMessage(
                      icon: Icons.search_off_rounded,
                      message: 'Aucun résultat.',
                      onRetry: _rafraichir,
                    )
                  : RefreshIndicator(
                      onRefresh: _rafraichir,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
                        itemCount: visibles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _CamionFlotteCard(
                          camion: visibles[index],
                          token: widget.token,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gpsFleetTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.gpsFleetSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _EtatMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Future<void> Function() onRetry;

  const _EtatMessage({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white38),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).commonRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CamionFlotteCard extends StatelessWidget {
  final CamionRecherche camion;
  final String token;

  const _CamionFlotteCard({required this.camion, required this.token});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final position = camion.position;
    final fraicheur = position?.fraicheur ?? 'INCONNUE';
    final couleur = couleurFraicheur(fraicheur);
    final chauffeur = camion.chauffeurActuel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CamionMapScreen(token: token, camion: camion),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.local_shipping_rounded, color: couleur),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          camion.immatriculation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${camion.typeCamion} · ${camion.ville}, ${nomParPays(camion.pays) ?? camion.pays}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      libelleFraicheur(l10n, fraicheur),
                      style: TextStyle(
                        color: couleur,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 16,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chauffeur != null
                          ? '${chauffeur.nom} · ${formaterLocal(chauffeur.telephone, chauffeur.pays)}'
                          : l10n.gpsNoChauffeurAssigned,
                      style: TextStyle(
                        color: chauffeur != null
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      position == null
                          ? l10n.gpsNoPositionReported
                          : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'
                                '${position.updatedAt != null ? ' · ${_formatDuree(l10n, DateTime.now().difference(position.updatedAt!))}' : ''}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
