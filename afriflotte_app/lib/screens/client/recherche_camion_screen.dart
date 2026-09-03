import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../constants/format_camion.dart';
import '../../constants/fraicheur.dart';
import '../../constants/type_camion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/camion_recherche.dart';
import '../../services/recherche_camion_service.dart';

/// Recherche de camions disponibles par type/capacité, triés par distance à
/// la position du client puis par fraîcheur de la position connue du camion
/// (`/api/recherche-camions/`, cf. `resoudre_position_camion` côté Django).
class RechercheCamionScreen extends StatefulWidget {
  final String token;

  const RechercheCamionScreen({super.key, required this.token});

  @override
  State<RechercheCamionScreen> createState() => _RechercheCamionScreenState();
}

class _RechercheCamionScreenState extends State<RechercheCamionScreen> {
  final _capaciteMinController = TextEditingController();

  String _typeCamion = 'CITERNE';
  String _formatCamion = '';
  double? _latitude;
  double? _longitude;
  bool _localisationEnCours = false;

  List<CamionRecherche>? _resultats;
  bool _rechercheEnCours = false;
  String? _erreur;

  @override
  void dispose() {
    _capaciteMinController.dispose();
    super.dispose();
  }

  Future<void> _utiliserMaPosition() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _localisationEnCours = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(l10n.rechercheCamionEnableLocation);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(l10n.rechercheCamionPermissionDenied);
      }

      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _localisationEnCours = false);
    }
  }

  Future<void> _rechercher() async {
    setState(() {
      _rechercheEnCours = true;
      _erreur = null;
    });

    try {
      final capaciteMin = double.tryParse(
        _capaciteMinController.text.trim().replaceAll(',', '.'),
      );

      final resultats = await RechercheCamionService.rechercher(
        token: widget.token,
        typeCamion: _typeCamion,
        formatCamion: _formatCamion,
        capaciteMin: capaciteMin,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;
      setState(() => _resultats = resultats);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _rechercheEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.rechercheCamionTitle),
        backgroundColor: const Color(0xFF102C5C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _FiltresCard(
            typeCamion: _typeCamion,
            onTypeCamionChanged: (value) => setState(() {
              _typeCamion = value;
              if (!formatsPourType(_typeCamion).contains(_formatCamion)) {
                _formatCamion = '';
              }
            }),
            formatCamion: _formatCamion,
            onFormatCamionChanged: (value) =>
                setState(() => _formatCamion = value),
            capaciteMinController: _capaciteMinController,
            latitude: _latitude,
            longitude: _longitude,
            localisationEnCours: _localisationEnCours,
            rechercheEnCours: _rechercheEnCours,
            onUtiliserPosition: _utiliserMaPosition,
            onRechercher: _rechercher,
          ),
          Expanded(child: _buildResultats(l10n)),
        ],
      ),
    );
  }

  Widget _buildResultats(AppLocalizations l10n) {
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_erreur!, textAlign: TextAlign.center),
        ),
      );
    }

    final resultats = _resultats;

    if (resultats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.rechercheCamionChooseType,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    if (resultats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.rechercheCamionNoneFound),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: resultats.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _CamionResultCard(camion: resultats[index]),
    );
  }
}

class _FiltresCard extends StatelessWidget {
  final String typeCamion;
  final ValueChanged<String> onTypeCamionChanged;
  final String formatCamion;
  final ValueChanged<String> onFormatCamionChanged;
  final TextEditingController capaciteMinController;
  final double? latitude;
  final double? longitude;
  final bool localisationEnCours;
  final bool rechercheEnCours;
  final VoidCallback onUtiliserPosition;
  final VoidCallback onRechercher;

  const _FiltresCard({
    required this.typeCamion,
    required this.onTypeCamionChanged,
    required this.formatCamion,
    required this.onFormatCamionChanged,
    required this.capaciteMinController,
    required this.latitude,
    required this.longitude,
    required this.localisationEnCours,
    required this.rechercheEnCours,
    required this.onUtiliserPosition,
    required this.onRechercher,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final positionDefinie = latitude != null && longitude != null;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: typeCamion,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.rechercheCamionTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: typesCamion
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(libelleTypeCamion(l10n, type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onTypeCamionChanged(value);
              },
            ),
            if (formatsPourType(typeCamion).isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('format_$typeCamion'),
                initialValue: formatCamion.isEmpty ? null : formatCamion,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.formatCamionLabel,
                  border: const OutlineInputBorder(),
                ),
                items: formatsPourType(typeCamion)
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(libelleFormatCamion(l10n, f)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => onFormatCamionChanged(value ?? ''),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: capaciteMinController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.rechercheCamionCapaciteMin,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    positionDefinie
                        ? l10n.rechercheCamionPositionDefined(
                            latitude!.toStringAsFixed(4),
                            longitude!.toStringAsFixed(4),
                          )
                        : l10n.rechercheCamionPositionUndefined,
                    style: TextStyle(
                      color: positionDefinie ? Colors.black87 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: localisationEnCours ? null : onUtiliserPosition,
                  icon: localisationEnCours
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(l10n.rechercheCamionMyPosition),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: rechercheEnCours ? null : onRechercher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF102C5C),
                ),
                icon: rechercheEnCours
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.white),
                label: Text(
                  rechercheEnCours
                      ? l10n.rechercheCamionSearching
                      : l10n.rechercheCamionSearchButton,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CamionResultCard extends StatelessWidget {
  final CamionRecherche camion;

  const _CamionResultCard({required this.camion});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fraicheur = camion.position?.fraicheur ?? 'INCONNUE';
    final couleur = couleurFraicheur(fraicheur);
    final label = libelleFraicheur(l10n, fraicheur);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Color(0xFF102C5C)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camion.immatriculation,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${camion.marque} ${camion.modele} · ${camion.typeCamion}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (camion.distanceKm != null)
                  Text(
                    '${camion.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102C5C),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${camion.capacite.toStringAsFixed(0)} ${camion.uniteCapacite}',
                  style: const TextStyle(fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: couleur,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
