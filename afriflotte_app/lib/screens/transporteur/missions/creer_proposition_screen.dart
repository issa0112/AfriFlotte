import 'package:flutter/material.dart';

import '../../../constants/pays_cedeao.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/camion.dart';
import '../../../models/chauffeur.dart';
import '../../../models/demande_transport.dart';
import '../../../models/proposition.dart';
import '../../../services/camion_service.dart';
import '../../../services/chauffeur_service.dart';
import '../../../services/proposition_service.dart';

class _LigneCamion {
  int? camionId;
  int? chauffeurId;
}

/// Répond à une [DemandeTransport] ouverte en proposant un ou plusieurs
/// camions (avec chauffeur optionnel), un prix et un message.
class CreerPropositionScreen extends StatefulWidget {
  final String token;
  final DemandeTransport demande;

  const CreerPropositionScreen({
    super.key,
    required this.token,
    required this.demande,
  });

  @override
  State<CreerPropositionScreen> createState() =>
      _CreerPropositionScreenState();
}

class _CreerPropositionScreenState extends State<CreerPropositionScreen> {
  final _prixController = TextEditingController();
  final _messageController = TextEditingController();

  DateTime? _delaiDepart;
  bool _envoi = false;

  late Future<(List<Camion>, List<Chauffeur>)> _futureDonnees;
  late final List<_LigneCamion> _lignes;

  @override
  void initState() {
    super.initState();
    _futureDonnees = _chargerDonnees();
    // Une proposition doit couvrir tous les camions demandés (validé côté
    // serveur dans `PropositionSerializer.validate`) : on pré-remplit une
    // ligne par camion requis plutôt que de laisser l'utilisateur en
    // ajouter un par un jusqu'à découvrir l'erreur à l'envoi.
    _lignes = List.generate(
      widget.demande.nombreCamions.clamp(1, 100),
      (_) => _LigneCamion(),
    );
  }

  Future<(List<Camion>, List<Chauffeur>)> _chargerDonnees() async {
    final resultats = await Future.wait([
      CamionService.getCamions(widget.token),
      ChauffeurService.getChauffeurs(widget.token),
    ]);
    return (resultats[0] as List<Camion>, resultats[1] as List<Chauffeur>);
  }

  @override
  void dispose() {
    _prixController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _delaiDepartLabel(AppLocalizations l10n) {
    final date = _delaiDepart;
    if (date == null) return l10n.propositionDepartureDateNotSet;
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year}';
  }

  Future<void> _choisirDelaiDepart() async {
    final maintenant = DateTime.now();
    final l10n = AppLocalizations.of(context);

    final choix = await showDatePicker(
      context: context,
      initialDate: _delaiDepart ?? maintenant,
      firstDate: maintenant,
      lastDate: maintenant.add(const Duration(days: 365)),
      helpText: l10n.propositionDepartureDate,
    );

    if (choix != null) {
      setState(() => _delaiDepart = choix);
    }
  }

  Future<void> _envoyer() async {
    final l10n = AppLocalizations.of(context);

    final prix = double.tryParse(
      _prixController.text.trim().replaceAll(',', '.'),
    );

    if (prix == null || prix <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propositionPriceRequired)),
      );
      return;
    }

    final camions = _lignes
        .where((ligne) => ligne.camionId != null)
        .map(
          (ligne) => PropositionCamionEntree(
            camionId: ligne.camionId!,
            chauffeurId: ligne.chauffeurId,
          ),
        )
        .toList();

    if (camions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propositionCamionRequired)),
      );
      return;
    }

    if (camions.length != widget.demande.nombreCamions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.propositionCamionCountMismatch(
              widget.demande.nombreCamions,
              camions.length,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _envoi = true);

    try {
      await PropositionService.creerProposition(
        token: widget.token,
        demandeId: widget.demande.id,
        prix: prix,
        camions: camions,
        message: _messageController.text,
        delaiDepart: _delaiDepart,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.propositionSentSuccess)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final message = '$e'.replaceFirst('Exception: ', '');

      // Un timeout/coupure réseau ne veut pas dire que l'envoi a échoué côté
      // serveur : la requête a pu aboutir sans que la réponse nous revienne.
      // Si on retente et que le serveur répond "déjà envoyée" (contrainte
      // `unique_proposition_transporteur_par_demande`), l'objectif de
      // l'utilisateur — avoir une proposition sur cette demande — est déjà
      // atteint : on ferme l'écran au lieu de le laisser bloqué sur une
      // erreur qui ressemble à un échec.
      if (message.contains('déjà envoyé une proposition')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.propositionAlreadySent)),
        );
        Navigator.pop(context, true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final demande = widget.demande;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.propositionTitle),
        backgroundColor: const Color(0xFF102C5C),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<(List<Camion>, List<Chauffeur>)>(
        future: _futureDonnees,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${snapshot.error}'.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final (camionsTous, chauffeurs) = snapshot.data!;

          if (camionsTous.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.propositionNeedCamionFirst,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Une demande de CITERNE ne doit jamais pouvoir recevoir une
          // proposition avec une BENNE : on ne propose même pas le choix
          // plutôt que de compter sur la validation serveur (défense en
          // profondeur, cf. PropositionSerializer.validate côté Django).
          final camions = camionsTous
              .where((c) => c.typeCamion == demande.typeCamion)
              .toList();

          if (camions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.propositionNoMatchingCamionType(demande.typeCamion),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DemandeSummaryCard(demande: demande),
                const SizedBox(height: 16),
                Text(
                  l10n.propositionCamionsLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _lignes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LigneCamionCard(
                      camions: camions,
                      chauffeurs: chauffeurs,
                      ligne: _lignes[i],
                      supprimable: _lignes.length > 1,
                      onChanged: () => setState(() {}),
                      onSupprimer: () => setState(() => _lignes.removeAt(i)),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _lignes.length >= demande.nombreCamions
                        ? null
                        : () => setState(() => _lignes.add(_LigneCamion())),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.propositionAddCamion),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _prixController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.propositionPriceLabel(deviseParPays(demande.paysDepart)),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _choisirDelaiDepart,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.propositionDepartureDate,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(_delaiDepartLabel(l10n)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.propositionMessageLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _envoi ? null : _envoyer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF102C5C),
                    ),
                    child: _envoi
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.propositionSendButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DemandeSummaryCard extends StatelessWidget {
  final DemandeTransport demande;

  const _DemandeSummaryCard({required this.demande});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFF102C5C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              demande.trajet,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${nomParPays(demande.paysDepart) ?? demande.paysDepart} → ${nomParPays(demande.paysArrivee) ?? demande.paysArrivee}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              '${demande.typeCamion} · ${demande.nombreCamions} camion(s) · ${demande.quantite ?? '-'} ${demande.unite}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneCamionCard extends StatelessWidget {
  final List<Camion> camions;
  final List<Chauffeur> chauffeurs;
  final _LigneCamion ligne;
  final bool supprimable;
  final VoidCallback onChanged;
  final VoidCallback onSupprimer;

  const _LigneCamionCard({
    required this.camions,
    required this.chauffeurs,
    required this.ligne,
    required this.supprimable,
    required this.onChanged,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: ligne.camionId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.propositionCamionFieldLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: camions
                        .map(
                          (camion) => DropdownMenuItem(
                            value: camion.id,
                            child: Text(
                              '${camion.immatriculation} (${camion.typeCamion})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      ligne.camionId = value;
                      onChanged();
                    },
                  ),
                ),
                if (supprimable)
                  IconButton(
                    onPressed: onSupprimer,
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              initialValue: ligne.chauffeurId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.propositionChauffeurFieldLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.propositionChauffeurNotSet)),
                ...chauffeurs.map(
                  (chauffeur) => DropdownMenuItem(
                    value: chauffeur.id,
                    child: Text(
                      chauffeur.disponible
                          ? chauffeur.nom
                          : '${chauffeur.nom} (${l10n.propositionChauffeurEnMission})',
                      overflow: TextOverflow.ellipsis,
                      style: chauffeur.disponible
                          ? null
                          : const TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                ligne.chauffeurId = value;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}
