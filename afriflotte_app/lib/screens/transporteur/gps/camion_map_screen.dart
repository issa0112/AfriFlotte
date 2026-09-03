import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../constants/fraicheur.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/camion_recherche.dart';
import '../../../services/recherche_camion_service.dart';
import '../../../utils/telephone.dart';

const _bleuNuit = Color(0xFF102C5C);

/// Carte + suivi en direct d'un camion précis, ouvert depuis une carte de
/// [GpsTransportScreen]. Pas de nouvel endpoint : on ré-interroge
/// `/transporteur/flotte-positions/` (déjà utilisé par l'écran flotte) toutes
/// les 12s et on ne garde que ce camion — cette vue "suivi" n'est qu'un zoom
/// sur une donnée déjà exposée, `resoudre_position_camion` reste la seule
/// source de vérité côté serveur.
class CamionMapScreen extends StatefulWidget {
  final String token;
  final CamionRecherche camion;

  const CamionMapScreen({super.key, required this.token, required this.camion});

  @override
  State<CamionMapScreen> createState() => _CamionMapScreenState();
}

class _CamionMapScreenState extends State<CamionMapScreen> {
  late CamionRecherche _camion;
  final MapController _mapController = MapController();
  Timer? _timer;
  bool _suivre = true;
  bool _chargementErreur = false;

  static const Duration _intervalleRafraichissement = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _camion = widget.camion;
    _timer = Timer.periodic(_intervalleRafraichissement, (_) => _rafraichir());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _rafraichir() async {
    try {
      final flotte = await RechercheCamionService.mesPositionsFlotte(
        widget.token,
      );
      final maj = flotte.where((c) => c.id == _camion.id).firstOrNull;
      if (maj == null || !mounted) return;

      setState(() {
        _camion = maj;
        _chargementErreur = false;
      });

      final position = maj.position;
      if (position != null && _suivre) {
        _mapController.move(
          ll.LatLng(position.latitude, position.longitude),
          _mapController.camera.zoom,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _chargementErreur = true);
    }
  }

  void _recentrer() {
    final position = _camion.position;
    if (position == null) return;
    setState(() => _suivre = true);
    _mapController.move(ll.LatLng(position.latitude, position.longitude), 15);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final position = _camion.position;
    final couleur = couleurFraicheur(position?.fraicheur ?? 'INCONNUE');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.gpsMapTitle(_camion.immatriculation)),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
      ),
      body: position == null
          ? _AucunePosition(l10n: l10n)
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: ll.LatLng(
                      position.latitude,
                      position.longitude,
                    ),
                    initialZoom: 15,
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture && _suivre) {
                        setState(() => _suivre = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      // tile.openstreetmap.org bloque désormais la plupart
                      // des apps qui l'utilisent directement (politique
                      // d'usage OSMF, cf. osm.wiki/Blocked — un browser web
                      // ne peut pas définir de User-Agent personnalisé, donc
                      // impossible à contourner côté Flutter Web). CARTO a
                      // été testé en remplacement mais ses tuiles anonymes
                      // portent désormais un filigrane "API KEY REQUIRED" —
                      // le mirroir OSM France, lui, sert les mêmes données
                      // sans clé ni filigrane pour un usage raisonnable.
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.afriflotte.app',
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                        TextSourceAttribution('OpenStreetMap France'),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: ll.LatLng(
                            position.latitude,
                            position.longitude,
                          ),
                          width: 46,
                          height: 46,
                          child: Icon(
                            Icons.local_shipping_rounded,
                            color: couleur,
                            size: 38,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 130,
                  child: FloatingActionButton.small(
                    heroTag: 'recentrer',
                    backgroundColor: _bleuNuit,
                    foregroundColor: Colors.white,
                    tooltip: l10n.gpsMapRecenter,
                    onPressed: _recentrer,
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _PanneauInfos(
                    l10n: l10n,
                    camion: _camion,
                    suivi: _suivre,
                    erreur: _chargementErreur,
                    couleur: couleur,
                  ),
                ),
              ],
            ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _AucunePosition extends StatelessWidget {
  final AppLocalizations l10n;

  const _AucunePosition({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bleuNuit,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_rounded,
                size: 52,
                color: Colors.white38,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.gpsMapNoPositionTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.gpsMapNoPositionSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanneauInfos extends StatelessWidget {
  final AppLocalizations l10n;
  final CamionRecherche camion;
  final bool suivi;
  final bool erreur;
  final Color couleur;

  const _PanneauInfos({
    required this.l10n,
    required this.camion,
    required this.suivi,
    required this.erreur,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    final position = camion.position;
    final chauffeur = camion.chauffeurActuel;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: suivi ? const Color(0xFF16A34A) : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                suivi ? l10n.gpsMapFollowing : l10n.gpsMapPaused,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: suivi ? const Color(0xFF16A34A) : Colors.grey.shade600,
                ),
              ),
              if (erreur) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.wifi_off_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  libelleFraicheur(l10n, position?.fraicheur),
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            camion.immatriculation,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            chauffeur != null
                ? '${chauffeur.nom} · ${formaterLocal(chauffeur.telephone, chauffeur.pays)}'
                : l10n.gpsNoChauffeurAssigned,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
          ),
          if (position != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.gpsMapSource(position.source),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
