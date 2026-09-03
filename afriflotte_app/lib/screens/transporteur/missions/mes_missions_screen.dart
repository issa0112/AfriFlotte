import 'package:flutter/material.dart';

import '../../../constants/pays_cedeao.dart';
import '../../../constants/statut_style.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/mission.dart';
import '../../../services/mission_service.dart';

/// Missions réelles du transporteur (`Mission`/`MissionService`), avec les
/// actions de cycle de vie : démarrer, terminer, annuler.
class MesMissionsScreen extends StatefulWidget {
  final String token;

  const MesMissionsScreen({super.key, required this.token});

  @override
  State<MesMissionsScreen> createState() => _MesMissionsScreenState();
}

class _MesMissionsScreenState extends State<MesMissionsScreen> {
  late Future<List<Mission>> _futureMissions;
  int? _actionEnCoursPourId;

  @override
  void initState() {
    super.initState();
    _futureMissions = MissionService.getMissions(widget.token);
  }

  Future<void> _rafraichir() async {
    final future = MissionService.getMissions(widget.token);
    // Bloc, pas flèche : voir liste_chauffeurs.dart._rafraichir pour le
    // pourquoi (setState() planterait, le callback "retournerait" le Future).
    setState(() {
      _futureMissions = future;
    });
    await future.catchError((_) => <Mission>[]);
  }

  Future<void> _executer(
    Mission mission,
    Future<void> Function(String, int) action,
    String messageSucces,
  ) async {
    setState(() => _actionEnCoursPourId = mission.id);

    try {
      await action(widget.token, mission.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messageSucces)));

      await _rafraichir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actionEnCoursPourId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.missionsTitle),
        backgroundColor: const Color(0xFF102C5C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            onPressed: _rafraichir,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Mission>>(
        future: _futureMissions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'.replaceFirst('Exception: ', '')),
            );
          }

          final missions = snapshot.data ?? const <Mission>[];

          if (missions.isEmpty) {
            return RefreshIndicator(
              onRefresh: _rafraichir,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(l10n.missionsEmpty)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _rafraichir,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: missions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _MissionCard(
                mission: missions[index],
                actionEnCours: _actionEnCoursPourId == missions[index].id,
                onDemarrer: () => _executer(
                  missions[index],
                  MissionService.accepterMission,
                  l10n.missionsStarted,
                ),
                onTerminer: () => _executer(
                  missions[index],
                  MissionService.terminerMission,
                  l10n.missionsFinished,
                ),
                onAnnuler: () => _executer(
                  missions[index],
                  MissionService.refuserMission,
                  l10n.missionsCancelled,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;
  final bool actionEnCours;
  final VoidCallback onDemarrer;
  final VoidCallback onTerminer;
  final VoidCallback onAnnuler;

  const _MissionCard({
    required this.mission,
    required this.actionEnCours,
    required this.onDemarrer,
    required this.onTerminer,
    required this.onAnnuler,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final couleur = couleurStatut(mission.statut);

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
                Expanded(
                  child: Text(
                    mission.trajet,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mission.statutLibelle,
                    style: TextStyle(
                      color: couleur,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${nomParPays(mission.paysDepart) ?? mission.paysDepart} → ${nomParPays(mission.paysArrivee) ?? mission.paysArrivee}',
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
            const SizedBox(height: 4),
            Text(
              '${mission.produit} · ${mission.typeCamion} · ${mission.nombreCamions} camion(s)',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            if (mission.prixFinal != null) ...[
              const SizedBox(height: 4),
              Text(
                formatMontant(mission.prixFinal, mission.devise),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (mission.statut == 'PLANIFIEE' ||
                mission.statut == 'EN_COURS') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: actionEnCours
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: onAnnuler,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                            child: Text(l10n.missionsCancel),
                          ),
                          if (mission.statut == 'PLANIFIEE')
                            ElevatedButton(
                              onPressed: onDemarrer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF102C5C),
                              ),
                              child: Text(
                                l10n.missionsStart,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          if (mission.statut == 'EN_COURS')
                            ElevatedButton(
                              onPressed: onTerminer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                              child: Text(
                                l10n.missionsFinish,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
