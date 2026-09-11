import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../constants/statut_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/api_service.dart';
import '../../utils/telephone.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Détail d'une mission côté chauffeur, avec les actions de cycle de vie
/// (démarrer/terminer) qu'aucun écran chauffeur n'exposait jusqu'ici — seul
/// le transporteur pouvait faire transiter `Mission.statut` (voir
/// `mes_missions_screen.dart`). Ouvert par `chauffeurId` sans JWT, comme le
/// reste des endpoints chauffeur : `chauffeur_demarrer_mission`/
/// `chauffeur_terminer_mission` côté Django vérifient l'appartenance à la
/// mission plutôt qu'un token.
class ChauffeurMissionDetailScreen extends StatefulWidget {
  final int chauffeurId;
  final Map<String, dynamic> mission;

  const ChauffeurMissionDetailScreen({
    super.key,
    required this.chauffeurId,
    required this.mission,
  });

  @override
  State<ChauffeurMissionDetailScreen> createState() =>
      _ChauffeurMissionDetailScreenState();
}

class _ChauffeurMissionDetailScreenState
    extends State<ChauffeurMissionDetailScreen> {
  late Map<String, dynamic> _mission;
  bool _actionEnCours = false;

  @override
  void initState() {
    super.initState();
    _mission = widget.mission;
  }

  String? _texte(String cle) => _mission[cle]?.toString();

  DateTime? _date(String cle) {
    final valeur = _mission[cle];
    if (valeur == null) return null;
    return DateTime.tryParse(valeur.toString());
  }

  String _formaterDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year} à $heure:$minute';
  }

  Future<void> _executer(
    Future<void> Function() action,
    String statutMissionApres,
    String messageSucces,
  ) async {
    setState(() => _actionEnCours = true);

    try {
      await action();

      if (!mounted) return;
      setState(() {
        _mission = {..._mission, 'mission_statut': statutMissionApres};
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messageSucces)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  Future<void> _demarrer() async {
    final missionId = _mission['mission_id'] as int;
    await _executer(
      () => ApiService.demarrerMissionChauffeur(
        chauffeurId: widget.chauffeurId,
        missionId: missionId,
      ),
      'EN_COURS',
      AppLocalizations.of(context).missionsStarted,
    );
  }

  Future<void> _terminer() async {
    final missionId = _mission['mission_id'] as int;
    await _executer(
      () => ApiService.terminerMissionChauffeur(
        chauffeurId: widget.chauffeurId,
        missionId: missionId,
      ),
      'TERMINEE',
      AppLocalizations.of(context).missionsFinished,
    );
  }

  Widget _ligne(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(valeur, style: const TextStyle(fontSize: 13.5))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final missionStatut = _texte('mission_statut') ?? 'PLANIFIEE';
    final couleur = couleurStatut(missionStatut);

    final dateDepart = _date('date_depart');
    final dateArrivee = _date('date_arrivee');

    final prixFinal = _mission['prix_final'];
    final devise = _texte('devise');

    final observations = _texte('observations');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.chauffeurMissionDetailTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
      ),
      body: ListView(
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _texte('trajet') ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        missionStatut,
                        style: TextStyle(
                          color: couleur,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _texte('camion') ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ligne(
                  l10n.chauffeurMissionDetailClient,
                  _texte('client_nom') ?? '',
                ),
                if ((_texte('client_telephone') ?? '').isNotEmpty)
                  _ligne(
                    l10n.chauffeurMissionDetailPhone,
                    formaterLocal(_texte('client_telephone'), _texte('client_pays'))!,
                  ),
                if ((_texte('description') ?? '').isNotEmpty)
                  _ligne(
                    l10n.chauffeurMissionDetailDescription,
                    _texte('description')!,
                  ),
                if (_mission['quantite'] != null)
                  _ligne(
                    l10n.chauffeurMissionDetailQuantite,
                    '${_mission['quantite']}',
                  ),
                if (prixFinal != null)
                  _ligne(
                    l10n.chauffeurMissionDetailPrix,
                    formatMontant(double.tryParse('$prixFinal'), devise ?? ''),
                  ),
                _ligne(
                  l10n.chauffeurMissionDetailDepart,
                  dateDepart != null
                      ? _formaterDate(dateDepart)
                      : l10n.chauffeurMissionDetailNotStarted,
                ),
                _ligne(
                  l10n.chauffeurMissionDetailArrivee,
                  dateArrivee != null
                      ? _formaterDate(dateArrivee)
                      : l10n.chauffeurMissionDetailNotArrived,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chauffeurMissionDetailObservations,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  (observations ?? '').isNotEmpty
                      ? observations!
                      : l10n.chauffeurMissionDetailNoObservations,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_actionEnCours)
            const Center(child: CircularProgressIndicator())
          else if (missionStatut == 'PLANIFIEE')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _demarrer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bleuNuit,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  l10n.missionsStart,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          else if (missionStatut == 'EN_COURS')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _terminer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  l10n.missionsFinish,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
