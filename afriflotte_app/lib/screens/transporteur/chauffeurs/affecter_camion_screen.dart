import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/camion.dart';
import '../../../models/chauffeur.dart';
import '../../../services/camion_service.dart';
import '../../../services/chauffeur_service.dart';

/// Choix d'un camion à assigner à [chauffeur]. Django clôture automatiquement
/// l'affectation précédente du camion et celle du chauffeur : réassigner un
/// camion déjà pris à quelqu'un d'autre est volontairement autorisé.
class AffecterCamionScreen extends StatefulWidget {
  final String token;
  final Chauffeur chauffeur;

  const AffecterCamionScreen({
    super.key,
    required this.token,
    required this.chauffeur,
  });

  @override
  State<AffecterCamionScreen> createState() => _AffecterCamionScreenState();
}

class _AffecterCamionScreenState extends State<AffecterCamionScreen> {
  late Future<List<Camion>> _futureCamions;
  int? _camionSelectionneId;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _camionSelectionneId = widget.chauffeur.camionActuel?.id;
    _futureCamions = CamionService.getCamions(widget.token);
  }

  Future<void> _confirmer() async {
    final camionId = _camionSelectionneId;
    if (camionId == null) return;

    setState(() => _envoi = true);

    try {
      await ChauffeurService.assignerCamion(
        token: widget.token,
        chauffeurId: widget.chauffeur.id,
        camionId: camionId,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.assignCamionTitle(widget.chauffeur.nom)),
        backgroundColor: const Color(0xFF102C5C),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Camion>>(
        future: _futureCamions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${snapshot.error}'.replaceFirst('Exception: ', ''),
              ),
            );
          }

          final camions = snapshot.data ?? const <Camion>[];

          if (camions.isEmpty) {
            return Center(
              child: Text(l10n.assignCamionEmpty),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: camions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final camion = camions[index];
              final selectionne = _camionSelectionneId == camion.id;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selectionne
                        ? const Color(0xFF102C5C)
                        : Colors.grey.shade300,
                    width: selectionne ? 2 : 1,
                  ),
                ),
                child: RadioListTile<int>(
                  value: camion.id,
                  groupValue: _camionSelectionneId,
                  onChanged: (value) =>
                      setState(() => _camionSelectionneId = value),
                  title: Text(camion.immatriculation),
                  subtitle: Text(
                    '${camion.marque} ${camion.modele} · ${camion.typeCamion}',
                  ),
                  secondary: Icon(
                    Icons.local_shipping,
                    color: camion.disponible ? Colors.green : Colors.orange,
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_camionSelectionneId == null || _envoi)
                  ? null
                  : _confirmer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF102C5C),
              ),
              child: _envoi
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.assignCamionButton),
            ),
          ),
        ),
      ),
    );
  }
}
