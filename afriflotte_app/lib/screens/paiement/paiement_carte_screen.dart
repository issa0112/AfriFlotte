import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/paiement_service.dart';
import '../../utils/carte_bancaire.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Formulaire de carte bancaire intégré à l'app (numéro, titulaire,
/// expiration, CVV) — plus de page externe à ouvrir dans un navigateur.
///
/// Le numéro complet et le CVV ne quittent jamais l'appareil : ils ne
/// servent qu'à la validation locale (Luhn, expiration, longueur du CVV,
/// `lib/utils/carte_bancaire.dart`). Seuls la marque, les 4 derniers
/// chiffres et l'expiration partent vers
/// `PaiementService.confirmerPaiementCarte`, qui appelle la passerelle
/// (simulateur par défaut, réussite immédiate — cf.
/// `core/gateway_paiement.py`) de façon synchrone : pas de minuteur de
/// polling, le résultat s'affiche dès la réponse du serveur.
class PaiementCarteScreen extends StatefulWidget {
  final String token;
  final int paiementId;
  final double montant;
  final String devise;
  final String trajet;

  const PaiementCarteScreen({
    super.key,
    required this.token,
    required this.paiementId,
    required this.montant,
    required this.devise,
    required this.trajet,
  });

  @override
  State<PaiementCarteScreen> createState() => _PaiementCarteScreenState();
}

class _PaiementCarteScreenState extends State<PaiementCarteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _nomController = TextEditingController();
  final _expirationController = TextEditingController();
  final _cvvController = TextEditingController();

  MarqueCarte _marque = MarqueCarte.autre;
  bool _envoi = false;
  bool _succes = false;
  String? _erreur;

  @override
  void dispose() {
    _numeroController.dispose();
    _nomController.dispose();
    _expirationController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _surChangementNumero(String valeur) {
    setState(() => _marque = detecterMarque(valeur));
  }

  Future<void> _payer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() {
      _envoi = true;
      _erreur = null;
    });

    // Les seules données qui partent vers le serveur : marque, 4 derniers
    // chiffres, expiration. `_numeroController`/`_cvvController` ne sont lus
    // qu'ici, localement, jamais transmis.
    final marque = codeMarque(_marque);
    final dernierChiffres = dernier4(_numeroController.text);
    final expiration = _expirationController.text.trim();

    try {
      final paiement = await PaiementService.confirmerPaiementCarte(
        token: widget.token,
        paiementId: widget.paiementId,
        marque: marque,
        dernier4: dernierChiffres,
        expiration: expiration,
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
              child: _succes ? _carteSucces(l10n) : _carteFormulaire(l10n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _carteSucces(AppLocalizations l10n) {
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

  Widget _carteFormulaire(AppLocalizations l10n) {
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
            TextFormField(
              controller: _numeroController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
              ],
              onChanged: _surChangementNumero,
              decoration: InputDecoration(
                labelText: l10n.paiementCarteNumeroLabel,
                border: const OutlineInputBorder(),
                suffixIcon: _marque == MarqueCarte.autre
                    ? const Icon(Icons.credit_card_rounded)
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          libelleMarque(_marque),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
              ),
              validator: (valeur) => validerNumeroCarte(valeur ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.paiementCarteNomLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (valeur) => validerNomTitulaire(valeur ?? ''),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expirationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_FormatteurExpiration()],
                    decoration: InputDecoration(
                      labelText: l10n.paiementCarteExpirationLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (valeur) => validerExpiration(valeur ?? ''),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(longueurCvvAttendue(_marque)),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.paiementCarteCvvLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (valeur) => validerCvv(valeur ?? '', _marque),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.paiementCarteSecuriteNote,
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

/// Formate la saisie de l'expiration en "MM/AA" au fil de la frappe (insère
/// automatiquement le "/" après les deux premiers chiffres).
class _FormatteurExpiration extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue ancien, TextEditingValue nouveau) {
    final tousLesChiffres = nouveau.text.replaceAll(RegExp(r'\D'), '');
    final chiffres = tousLesChiffres.length > 4
        ? tousLesChiffres.substring(0, 4)
        : tousLesChiffres;

    final formate = chiffres.length > 2
        ? '${chiffres.substring(0, 2)}/${chiffres.substring(2)}'
        : chiffres;

    return TextEditingValue(
      text: formate,
      selection: TextSelection.collapsed(offset: formate.length),
    );
  }
}
