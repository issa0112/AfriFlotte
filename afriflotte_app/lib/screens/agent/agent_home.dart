import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/paiement.dart';
import '../../services/paiement_service.dart';
import '../../utils/responsive.dart';

const _bleuFonce = Color(0xFF071A3A);
const _bleuNuit = Color(0xFF102C5C);

/// Accueil du rôle AGENT (nouveau compte AfriFlotte dédié à l'encaissement
/// manuel — cf. plan paiement) : liste des paiements MANUEL en attente
/// d'encaissement (`EN_ATTENTE`), avec un formulaire d'encaissement +
/// preuve photo pour chacun. Un agent n'a accès à aucune autre fonctionnalité
/// de l'app — ce n'est pas un rôle transport (client/transporteur/chauffeur).
class AgentHome extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const AgentHome({super.key, required this.user, required this.token});

  @override
  State<AgentHome> createState() => _AgentHomeState();
}

class _AgentHomeState extends State<AgentHome> {
  late Future<List<Paiement>> _future;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    _future = PaiementService.paiementsAEncaisser(widget.token);
  }

  Future<void> _rafraichir() async {
    setState(_charger);
    await _future.catchError((_) => <Paiement>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bleuFonce, _bleuNuit],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: BoundedContent(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                  child: Text(
                    l10n.agentAccueilTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Paiement>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                          ),
                        );
                      }

                      final paiements = snapshot.data ?? const <Paiement>[];

                      if (paiements.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _rafraichir,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 52,
                                color: Colors.white38,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.agentAucunPaiement,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _rafraichir,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                          itemCount: paiements.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _CartePaiementAgent(
                            paiement: paiements[index],
                            token: widget.token,
                            onEncaisse: _rafraichir,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartePaiementAgent extends StatefulWidget {
  final Paiement paiement;
  final String token;
  final VoidCallback onEncaisse;

  const _CartePaiementAgent({
    required this.paiement,
    required this.token,
    required this.onEncaisse,
  });

  @override
  State<_CartePaiementAgent> createState() => _CartePaiementAgentState();
}

class _CartePaiementAgentState extends State<_CartePaiementAgent> {
  final _referenceController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _preuve;
  bool _envoi = false;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    final fichier = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (fichier != null) setState(() => _preuve = fichier);
  }

  Future<void> _encaisser() async {
    setState(() => _envoi = true);
    try {
      await PaiementService.encaisserManuel(
        token: widget.token,
        paiementId: widget.paiement.id,
        reference: _referenceController.text.trim(),
        preuve: _preuve,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).agentEncaissementConfirme,
            ),
          ),
        );
      }
      widget.onEncaisse();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paiement = widget.paiement;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            paiement.missionTrajet,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${paiement.clientNom} · ${paiement.montantTotal.toStringAsFixed(0)} ${paiement.devise}',
            style: const TextStyle(color: Colors.white60, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: l10n.agentReferenceLabel,
              labelStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white70),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _choisirPhoto,
            icon: Icon(
              _preuve == null
                  ? Icons.camera_alt_outlined
                  : Icons.check_circle_rounded,
              size: 18,
            ),
            label: Text(
              _preuve == null
                  ? l10n.agentAjouterPreuve
                  : l10n.agentPreuveAjoutee,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _envoi ? null : _encaisser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
              child: _envoi
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.agentEncaisserButton),
            ),
          ),
        ],
      ),
    );
  }
}
