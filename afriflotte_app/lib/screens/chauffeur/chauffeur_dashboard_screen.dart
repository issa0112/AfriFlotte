import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/statut_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/api_service.dart';
import '../../services/chauffeur_service.dart';
import '../../services/storage_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/avatar_picker.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_switcher.dart';
import '../auth/auth_screen.dart';
import 'chauffeur_mission_detail_screen.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

class ChauffeurDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> chauffeur;

  const ChauffeurDashboardScreen({super.key, required this.chauffeur});

  @override
  State<ChauffeurDashboardScreen> createState() =>
      _ChauffeurDashboardScreenState();
}

class _ChauffeurDashboardScreenState extends State<ChauffeurDashboardScreen> {
  List<dynamic> missions = [];
  bool loading = true;
  String? errorMessage;

  late Map<String, dynamic> _chauffeur;
  bool _photoEnCours = false;

  StreamSubscription<Position>? _positionSubscription;
  bool _localisationActive = false;
  bool _permissionRefusee = false;

  // mission_id -> mission_statut du dernier chargement, pour détecter un
  // changement fait par le transporteur entre deux rafraîchissements (pas
  // de vraie notification côté chauffeur, qui n'a pas de compte User —
  // voir `chauffeur_mission_detail_screen.dart`).
  Map<int, String> _statutsConnus = {};

  String get _codeAcces => _chauffeur['code_acces']?.toString() ?? '';

  Future<void> _changerPhoto(XFile fichier) async {
    final chauffeurId = int.tryParse(_chauffeur['id'].toString());
    if (chauffeurId == null) return;

    setState(() => _photoEnCours = true);

    try {
      final photoUrl = await ChauffeurService.modifierMaPhoto(
        chauffeurId: chauffeurId,
        codeAcces: _codeAcces,
        photo: fichier,
      );

      if (!mounted) return;
      setState(() => _chauffeur = {..._chauffeur, 'photo': photoUrl});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _photoEnCours = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _chauffeur = widget.chauffeur;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMissions());
    _demarrerEnvoiPosition();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// Envoie la position du chauffeur tant que cet écran est ouvert —
  /// indépendamment de toute mission en cours. C'est volontaire : le camion
  /// n'a pas son propre GPS, sa position est résolue côté serveur à partir
  /// de celle de son chauffeur (`resoudre_position_camion`), et c'est ce qui
  /// permet à un client de le trouver dans une recherche pendant qu'il est
  /// disponible (donc *hors* mission) — couper l'envoi en dehors d'un
  /// EN_COURS le rendrait introuvable pile quand il est cherchable. Accuracy
  /// medium/filtre 100m plutôt que high/50m : économise la batterie sans
  /// nuire à la fraîcheur perçue, dont les paliers (`classifier_fraicheur`
  /// côté Django) se comptent en minutes, pas en mètres.
  ///
  /// Ce n'est pas non plus un vrai service en arrière-plan (l'envoi s'arrête
  /// si l'app est fermée ou mise en veille) — juste ce qu'il faut pour que
  /// le camion reste localisable pendant que le chauffeur utilise l'app.
  Future<void> _demarrerEnvoiPosition() async {
    final chauffeurId = int.tryParse(widget.chauffeur['id'].toString());
    if (chauffeurId == null) return;

    if (mounted) setState(() => _permissionRefusee = false);

    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _permissionRefusee = true);
      return;
    }

    if (mounted) setState(() => _localisationActive = true);

    await _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 100,
          ),
        ).listen(
          (Position position) {
            ApiService.envoyerPositionChauffeur(
              chauffeurId: chauffeurId,
              codeAcces: _codeAcces,
              latitude: position.latitude,
              longitude: position.longitude,
            );
          },
          onError: (Object e) {
            if (mounted) setState(() => _localisationActive = false);
          },
        );
  }

  /// [signalerChangements] à `false` juste après un retour de l'écran détail
  /// (le chauffeur vient d'agir lui-même, il a déjà vu la confirmation là-bas
  /// — pas besoin de le lui répéter ici).
  Future<void> _loadMissions({bool signalerChangements = true}) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final id = widget.chauffeur['id'];
      if (id == null) {
        throw Exception(l10n.chauffeurDashIdNotFound);
      }
      final result = await ApiService.getChauffeurMissions(
        int.parse(id.toString()),
        _codeAcces,
      );
      if (!mounted) return;

      final nouveauxStatuts = <int, String>{
        for (final m in result.whereType<Map<String, dynamic>>())
          if (m['mission_id'] != null)
            (m['mission_id'] as int): m['mission_statut']?.toString() ?? '',
      };

      final aChange =
          signalerChangements &&
          _statutsConnus.isNotEmpty &&
          nouveauxStatuts.entries.any(
            (e) =>
                _statutsConnus[e.key] != null &&
                _statutsConnus[e.key] != e.value,
          );

      setState(() {
        missions = result;
        loading = false;
        _statutsConnus = nouveauxStatuts;
      });

      if (aChange) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chauffeurDashMissionsUpdatedByTransporteur),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  Color _statutCouleur(String statut) => couleurStatut(statut);

  Future<void> _deconnecter() async {
    await StorageService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.chauffeurDashTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: LanguageSwitcher(light: true)),
          ),
          const ThemeSwitcher(light: true),
          IconButton(
            onPressed: _loadMissions,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _deconnecter,
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.profilTLogout,
          ),
        ],
      ),
      body: BoundedContent(
        child: RefreshIndicator(
          onRefresh: _loadMissions,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_bleuNuit, _bleuAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarPicker(
                      photoUrl: _chauffeur['photo']?.toString(),
                      initiales:
                          (_chauffeur['nom']?.toString().isNotEmpty ?? false)
                          ? _chauffeur['nom'].toString()[0].toUpperCase()
                          : 'C',
                      loading: _photoEnCours,
                      onImageSelectionnee: _changerPhoto,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.chauffeurDashGreeting(
                              _chauffeur['nom']?.toString() ??
                                  l10n.chauffeurDashDefaultName,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.chauffeurDashReady,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                _localisationActive
                                    ? Icons.location_on
                                    : Icons.location_off,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _localisationActive
                                      ? l10n.chauffeurDashLocationActive
                                      : l10n.chauffeurDashLocationUnavailable,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_permissionRefusee) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.chauffeurDashLocationPermissionDenied,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              children: [
                                TextButton(
                                  onPressed: _demarrerEnvoiPosition,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    l10n.chauffeurDashLocationRetry,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: Geolocator.openAppSettings,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    l10n.chauffeurDashLocationOpenSettings,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(errorMessage!),
                )
              else if (missions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(l10n.chauffeurDashNoMissions),
                )
              else
                ...missions.map((mission) {
                  final map = mission as Map<String, dynamic>;
                  final statut = map['statut']?.toString() ?? 'Inconnu';
                  final couleur = _statutCouleur(statut);

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final chauffeurId = int.tryParse(
                        widget.chauffeur['id'].toString(),
                      );
                      if (chauffeurId == null || map['mission_id'] == null) {
                        return;
                      }
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChauffeurMissionDetailScreen(
                            chauffeurId: chauffeurId,
                            codeAcces: _codeAcces,
                            mission: map,
                          ),
                        ),
                      );
                      if (mounted) _loadMissions(signalerChangements: false);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _bleuAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: _bleuAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  map['camion']?.toString() ??
                                      l10n.chauffeurDashMissionFallback,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  map['trajet']?.toString() ??
                                      l10n.chauffeurDashNoDetails,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
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
                              color: couleur.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statut,
                              style: TextStyle(
                                color: couleur,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
