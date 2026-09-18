import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/paiement_service.dart';
import '../../utils/telephone.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Formulaire Mobile Money intégré à l'app (opérateur + numéro à débiter) —
/// pendant de `PaiementCarteScreen` pour le mode MOBILE quand la passerelle
/// active n'a pas de page hébergée à ouvrir (simulateur ; PayDunya, lui,
/// fournit un `checkout_url` géré ailleurs via une WebView).
///
/// Le numéro est revalidé côté serveur (`valider_et_normaliser` selon
/// [pays], même règles qu'à l'inscription) et l'opérateur doit être l'un de
/// [operateurs] — la validation ici n'est qu'un confort de saisie.
class PaiementMobileScreen extends StatefulWidget {
  final String token;
  final int paiementId;
  final double montant;
  final String devise;
  final String trajet;
  final String pays;
  final List<String> operateurs;

  const PaiementMobileScreen({
    super.key,
    required this.token,
    required this.paiementId,
    required this.montant,
    required this.devise,
    required this.trajet,
    required this.pays,
    required this.operateurs,
  });

  @override
  State<PaiementMobileScreen> createState() => _PaiementMobileScreenState();
}

class _PaiementMobileScreenState extends State<PaiementMobileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();

  late String _operateur;
  bool _envoi = false;
  bool _succes = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _operateur = widget.operateurs.isNotEmpty ? widget.operateurs.first : '';
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _payer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      final paiement = await PaiementService.confirmerPaiementMobile(
        token: widget.token,
        paiementId: widget.paiementId,
        operateur: _operateur,
        numero: _numeroController.text.trim(),
      );

      if (!mounted) return;

      if (paiement.statut == 'SECURISE') {
        setState(() => _succes = true);
      } else {
        setState(() => _erreur = l10n.paiementEchecTitre);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _bleuNuit,
      appBar: AppBar(
        title: Text(l10n.paiementTitle),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _succes ? _succesVue(l10n) : _formulaire(l10n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _succesVue(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 64),
        const SizedBox(height: 18),
        Text(
          l10n.paiementSucces,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: _bleuAccent, foregroundColor: Colors.white),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _formulaire(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.trajet,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.paiementCarteMontantAPayer,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  '${widget.montant.toStringAsFixed(0)} ${widget.devise}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _operateur.isEmpty ? null : _operateur,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.paiementMobileOperateurLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone_android_rounded),
              ),
              items: widget.operateurs
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (valeur) => setState(() => _operateur = valeur ?? ''),
              validator: (valeur) =>
                  valeur == null || valeur.isEmpty ? l10n.commonRequiredField : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.paiementMobileNumeroLabel,
                border: const OutlineInputBorder(),
                prefixText: '${indicatifParPays(widget.pays) ?? ''} ',
              ),
              validator: (valeur) {
                if (valeur == null || valeur.trim().isEmpty) {
                  return l10n.commonRequiredField;
                }
                return validerNumeroLocal(widget.pays, valeur.trim());
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.paiementMobileNote,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Text(_erreur!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _envoi ? null : _payer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bleuAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _envoi
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text(l10n.paiementCarteTraitementEnCours),
                        ],
                      )
                    : Text(
                        '${l10n.paiementBouton} ${widget.montant.toStringAsFixed(0)} ${widget.devise}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
