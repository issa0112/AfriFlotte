import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/contrat.dart';
import '../../services/contrat_service.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

const _moisFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];
const _moisEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "2026-09-18" -> "18 septembre 2026" (ou l'équivalent anglais) — évite une
/// dépendance à `intl`/`DateFormat` (et à l'initialisation des données de
/// locale qu'elle implique) pour un simple format de date affiché une fois.
String formaterDateVersion(String iso, String langue) {
  final parties = iso.split('-');
  if (parties.length != 3) return iso;
  final annee = parties[0];
  final mois = int.tryParse(parties[1]);
  final jour = int.tryParse(parties[2]);
  if (mois == null || jour == null || mois < 1 || mois > 12) return iso;
  final noms = langue == 'en' ? _moisEn : _moisFr;
  return '$jour ${noms[mois - 1]} $annee';
}

enum ContratType { paiement, transporteur }

/// Aperçu en ligne d'un contrat légal (paiement ou transporteur), avec
/// téléchargement PDF — même contenu que `core/contrats.py`, seule source de
/// vérité côté serveur. Purement consultatif ici (pas de case à cocher) ;
/// [ContratTransporteurGateScreen] réutilise ce rendu pour l'écran de
/// blocage transporteur qui, lui, exige une acceptation.
class ContratScreen extends StatefulWidget {
  final ContratType type;

  const ContratScreen({super.key, required this.type});

  @override
  State<ContratScreen> createState() => _ContratScreenState();
}

class _ContratScreenState extends State<ContratScreen> {
  Contrat? _contrat;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      final contrat = widget.type == ContratType.paiement
          ? await ContratService.getContratPaiement()
          : await ContratService.getContratTransporteur();
      if (mounted) setState(() => _contrat = contrat);
    } catch (_) {
      if (mounted) {
        setState(
          () => _erreur = AppLocalizations.of(context).contratChargementErreur,
        );
      }
    }
  }

  Future<void> _telechargerPdf() async {
    final url = widget.type == ContratType.paiement
        ? ContratService.urlPdfContratPaiement
        : ContratService.urlPdfContratTransporteur;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titre = widget.type == ContratType.paiement
        ? l10n.contratPaiementTitre
        : l10n.contratTransporteurTitre;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(titre),
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
        actions: [
          if (_contrat != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: l10n.contratTelechargerPdf,
              onPressed: _telechargerPdf,
            ),
        ],
      ),
      body: _corps(l10n),
    );
  }

  Widget _corps(AppLocalizations l10n) {
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.redAccent),
              const SizedBox(height: 14),
              Text(_erreur!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _charger,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bleuNuit,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final contrat = _contrat;
    if (contrat == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ContratListe(contrat: contrat);
  }
}

/// Corps défilable d'un contrat (bandeau titre/version + sections) — extrait
/// de [ContratScreen] pour être réutilisé tel quel par
/// [ContratTransporteurGateScreen], qui l'entoure d'une barre d'action
/// persistante (case à cocher + bouton d'acceptation) au lieu de l'ouvrir en
/// simple consultation.
class ContratListe extends StatelessWidget {
  final Contrat contrat;
  final EdgeInsetsGeometry padding;

  const ContratListe({
    super.key,
    required this.contrat,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 32),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final langue = Localizations.localeOf(context).languageCode;

    return ListView(
      padding: padding,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_bleuNuit, _bleuAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      contrat.titre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.contratVersionLabel(
                  formaterDateVersion(contrat.version, langue),
                ),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...contrat.sections.map((section) => _CarteSection(section: section)),
      ],
    );
  }
}

class _CarteSection extends StatelessWidget {
  final ContratSection section;

  const _CarteSection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.titre,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: _bleuAccent,
            ),
          ),
          const SizedBox(height: 10),
          ...section.blocs.map((bloc) {
            if (bloc is ContratBlocParagraphe) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  bloc.texte,
                  style: TextStyle(
                    height: 1.5,
                    fontSize: 13.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.justify,
                ),
              );
            }
            if (bloc is ContratBlocListe) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bloc.items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 5, right: 8),
                                child: Icon(
                                  Icons.circle,
                                  size: 5,
                                  color: _bleuAccent,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    height: 1.5,
                                    fontSize: 13.5,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
