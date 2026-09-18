import 'dart:convert';

import 'package:flutter/material.dart';

import '../../constants/format_camion.dart';
import '../../constants/type_camion.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/demande_transport.dart';
import '../../services/api_service.dart';
import '../../services/authenticated_http.dart';
import '../../services/demande_transport_service.dart';
import '../../widgets/pays_dropdown.dart';
import '../../widgets/ville_autocomplete_field.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);
const _fondChamp = Color(0xFFF1F5F9);

/// Création — ou modification — d'une demande de transport.
/// En mode onglet (embedded), on ne peut pas faire `Navigator.pop` après
/// succès — cela fermerait le dashboard entier : on notifie via [onCreated].
/// [demande] non-null bascule l'écran en édition (PATCH au lieu de POST),
/// uniquement pertinent pour une demande encore OUVERTE côté serveur.
class NouvelleDemandeScreen extends StatefulWidget {
  final String token;
  final bool embedded;
  final VoidCallback? onCreated;
  final DemandeTransport? demande;

  const NouvelleDemandeScreen({
    super.key,
    required this.token,
    this.embedded = false,
    this.onCreated,
    this.demande,
  });

  @override
  State<NouvelleDemandeScreen> createState() => _NouvelleDemandeScreenState();
}

class _NouvelleDemandeScreenState extends State<NouvelleDemandeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _departController = TextEditingController();
  final _arriveeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _prixController = TextEditingController();
  final _formatAutreController = TextEditingController();
  String _typeCamion = 'CITERNE';
  String _formatCamion = '';
  String _unite = 'litres';
  String _paysDepart = 'ML';
  String _paysArrivee = 'ML';
  int _nombreCamions = 1;
  DateTime _dateChargement = DateTime.now();
  bool _isLoading = false;

  bool get _modeEdition => widget.demande != null;

  /// Seul un camion citerne transporte du liquide : "litres" n'a de sens
  /// que pour lui, les autres types se mesurent en tonnes/kg — même règle
  /// que côté camion (cf. constants/type_camion.dart), appliquée ici via une
  /// liste au lieu d'une valeur unique puisque "précis" reste au choix du
  /// client pour du solide (tonnes ou kg).
  List<String> get _unitesDisponibles =>
      _typeCamion == 'CITERNE' ? const ['litres'] : const ['tonnes', 'kg'];

  @override
  void initState() {
    super.initState();

    final demande = widget.demande;
    if (demande != null) {
      _typeCamion = demande.typeCamion;
      _formatCamion = demande.formatCamion;
      _formatAutreController.text = demande.formatAutre;
      _unite = demande.unite.isNotEmpty
          ? demande.unite
          : _unitesDisponibles.first;
      _paysDepart = demande.paysDepart;
      _paysArrivee = demande.paysArrivee;
      _nombreCamions = demande.nombreCamions;
      _dateChargement = demande.dateChargement ?? DateTime.now();
      _departController.text = demande.depart;
      _arriveeController.text = demande.destination;
      _descriptionController.text = demande.produit;
      if (demande.quantite != null) {
        _quantiteController.text = demande.quantite!.toStringAsFixed(
          demande.quantite == demande.quantite!.roundToDouble() ? 0 : 2,
        );
      }
      if (demande.prixPropose != null) {
        _prixController.text = demande.prixPropose!.toStringAsFixed(
          demande.prixPropose == demande.prixPropose!.roundToDouble() ? 0 : 2,
        );
      }
    }
  }

  @override
  void dispose() {
    _departController.dispose();
    _arriveeController.dispose();
    _descriptionController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    _formatAutreController.dispose();
    super.dispose();
  }

  String get _dateChargementLabel {
    final jour = _dateChargement.day.toString().padLeft(2, '0');
    final mois = _dateChargement.month.toString().padLeft(2, '0');
    return '$jour/$mois/${_dateChargement.year}';
  }

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final l10n = AppLocalizations.of(context);

    final choix = await showDatePicker(
      context: context,
      initialDate: _dateChargement.isBefore(maintenant)
          ? maintenant
          : _dateChargement,
      firstDate: DateTime(maintenant.year, maintenant.month, maintenant.day),
      lastDate: maintenant.add(const Duration(days: 365)),
      helpText: l10n.nouvelleDemandeDateChargement,
    );

    if (choix != null) {
      setState(() => _dateChargement = choix);
    }
  }

  void _changerTypeCamion(String value) {
    setState(() {
      _typeCamion = value;
      // Le type choisi peut rendre l'unité actuelle invalide (ex: on passe
      // de BENNE/tonnes à CITERNE, où seul "litres" est autorisé) : on la
      // corrige immédiatement plutôt que de laisser un état incohérent que
      // la validation du formulaire devrait ensuite détecter.
      if (!_unitesDisponibles.contains(_unite)) {
        _unite = _unitesDisponibles.first;
      }
      // Même logique pour le format : "40 pieds" n'a pas de sens pour une
      // benne, par exemple.
      if (!formatsPourType(_typeCamion).contains(_formatCamion)) {
        _formatCamion = '';
      }
    });
  }

  void _reinitialiser() {
    _formKey.currentState?.reset();
    _departController.clear();
    _arriveeController.clear();
    _descriptionController.clear();
    _quantiteController.clear();
    _prixController.clear();
    _formatAutreController.clear();

    setState(() {
      _typeCamion = 'CITERNE';
      _formatCamion = '';
      _unite = 'litres';
      _paysDepart = 'ML';
      _paysArrivee = 'ML';
      _nombreCamions = 1;
      _dateChargement = DateTime.now();
    });
  }

  String _messageErreur(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        final detail = decoded['detail'];
        if (detail != null) return detail.toString();

        // DRF renvoie {"champ": ["message"]} sur erreur de validation.
        final premier = decoded.entries.first;
        final valeur = premier.value;
        final texte = valeur is List && valeur.isNotEmpty
            ? valeur.first.toString()
            : valeur.toString();
        return '${premier.key} : $texte';
      }
    } catch (_) {
      // Corps non JSON : on retombe sur le brut tronqué.
    }

    return body.length > 180 ? '${body.substring(0, 180)}…' : body;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    final payload = {
      'type_camion': _typeCamion,
      'format_camion': _formatCamion,
      'format_autre': _formatCamion == 'AUTRE'
          ? _formatAutreController.text.trim()
          : '',
      'nombre_camions': _nombreCamions,
      'ville_depart': _departController.text.trim(),
      'ville_arrivee': _arriveeController.text.trim(),
      'pays_depart': _paysDepart,
      'pays_arrivee': _paysArrivee,
      'description': _descriptionController.text.trim(),
      'quantite': double.tryParse(_quantiteController.text.trim()) ?? 0,
      'unite': _unite,
      'date_chargement': _dateChargement.toIso8601String().split('T').first,
      if (_prixController.text.trim().isNotEmpty)
        'prix_propose': double.tryParse(_prixController.text.trim()),
      if (!_modeEdition) 'statut': 'OUVERTE',
    };

    try {
      final response = _modeEdition
          ? await DemandeTransportService.modifierDemande(
              token: widget.token,
              demandeId: widget.demande!.id,
              data: payload,
            )
          : await AuthenticatedHttp.post(
              Uri.parse('${ApiService.baseUrl}/demandes/'),
              headers: {
                'Authorization': 'Bearer ${widget.token}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(payload),
            );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _modeEdition
                  ? l10n.nouvelleDemandeUpdateSuccess
                  : l10n.nouvelleDemandeSuccess,
            ),
          ),
        );

        if (_modeEdition) {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
          return;
        }

        _reinitialiser();

        if (widget.onCreated != null) {
          widget.onCreated!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageErreur(response.body))));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.nouvelleDemandeGenericError('$e'))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _bleuNuit),
      filled: true,
    );
  }

  Widget _sectionTitle(String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        texte,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unites = _unitesDisponibles;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _modeEdition
              ? l10n.nouvelleDemandeEditTitle
              : l10n.nouvelleDemandeTitle,
        ),
        elevation: 0,
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(l10n.nouvelleDemandeVilleDepart.toUpperCase()),
              _card(
                children: [
                  PaysDropdown(
                    value: _paysDepart,
                    label: l10n.nouvelleDemandePaysDepart,
                    onChanged: (value) => setState(() => _paysDepart = value),
                  ),
                  const SizedBox(height: 12),
                  VilleAutocompleteField(
                    controller: _departController,
                    pays: _paysDepart,
                    decoration: _decoration(
                      l10n.nouvelleDemandeVilleDepart,
                      Icons.trip_origin,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.commonRequiredField
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: Theme.of(context).colorScheme.outline,
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  PaysDropdown(
                    value: _paysArrivee,
                    label: l10n.nouvelleDemandePaysArrivee,
                    onChanged: (value) => setState(() => _paysArrivee = value),
                  ),
                  const SizedBox(height: 12),
                  VilleAutocompleteField(
                    controller: _arriveeController,
                    pays: _paysArrivee,
                    decoration: _decoration(
                      l10n.nouvelleDemandeVilleArrivee,
                      Icons.flag_rounded,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.commonRequiredField
                        : null,
                  ),
                ],
              ),
              _sectionTitle(l10n.nouvelleDemandeTypeCamion.toUpperCase()),
              _card(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _typeCamion,
                    isExpanded: true,
                    decoration: _decoration(
                      l10n.nouvelleDemandeTypeCamion,
                      Icons.local_shipping_rounded,
                    ),
                    items: typesCamion
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(libelleTypeCamion(l10n, type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        _changerTypeCamion(value ?? 'CITERNE'),
                  ),
                  if (formatsPourType(_typeCamion).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('format_$_typeCamion'),
                      initialValue: _formatCamion.isEmpty
                          ? null
                          : _formatCamion,
                      isExpanded: true,
                      decoration: _decoration(
                        l10n.formatCamionLabel,
                        Icons.straighten_outlined,
                      ),
                      items: formatsPourType(_typeCamion)
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(libelleFormatCamion(l10n, f)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _formatCamion = value ?? ''),
                    ),
                    if (_formatCamion == 'AUTRE') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _formatAutreController,
                        decoration: _decoration(
                          l10n.formatCamionAutrePrecision,
                          Icons.edit_outlined,
                        ),
                        validator: (value) =>
                            _formatCamion == 'AUTRE' &&
                                (value == null || value.trim().isEmpty)
                            ? l10n.formatCamionAutrePrecision
                            : null,
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantiteController,
                          keyboardType: TextInputType.number,
                          decoration: _decoration(
                            l10n.nouvelleDemandeQuantite,
                            Icons.scale_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.commonRequiredField;
                            }
                            final quantite = double.tryParse(value.trim());
                            if (quantite == null || quantite <= 0) {
                              return l10n.nouvelleDemandeQuantiteInvalid;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // Peut ne plus être dans `unites` juste après un
                          // changement de type (ex: CITERNE -> BENNE) tant
                          // que `_changerTypeCamion` n'a pas encore corrigé
                          // `_unite` au frame suivant ; `unites.contains`
                          // évite un crash de Dropdown le temps du rebuild.
                          initialValue: unites.contains(_unite)
                              ? _unite
                              : unites.first,
                          isExpanded: true,
                          decoration: _decoration(
                            l10n.nouvelleDemandeUnite,
                            Icons.straighten_rounded,
                          ),
                          items: unites
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(switch (u) {
                                    'litres' => l10n.nouvelleDemandeUniteLitres,
                                    'tonnes' => l10n.nouvelleDemandeUniteTonnes,
                                    _ => l10n.nouvelleDemandeUniteKg,
                                  }),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _unite = value ?? unites.first),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.numbers_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.nouvelleDemandeNombreCamions,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<int>(
                          value: _nombreCamions,
                          underline: const SizedBox.shrink(),
                          items: List.generate(
                            5,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('${index + 1}'),
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => _nombreCamions = value ?? 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _sectionTitle(l10n.nouvelleDemandeDescription.toUpperCase()),
              _card(
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: _decoration(
                      l10n.nouvelleDemandeDescription,
                      Icons.inventory_2_rounded,
                      hint: l10n.nouvelleDemandeDescriptionHint,
                    ),
                    validator: (value) {
                      final texte = value?.trim() ?? '';
                      if (texte.isEmpty)
                        return l10n.nouvelleDemandeDescriptionRequired;
                      if (texte.length < 3)
                        return l10n.nouvelleDemandeDescriptionTooShort;
                      return null;
                    },
                  ),
                ],
              ),
              _sectionTitle(l10n.nouvelleDemandeDateChargement.toUpperCase()),
              _card(
                children: [
                  InkWell(
                    onTap: _choisirDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _decoration(
                        l10n.nouvelleDemandeDateChargement,
                        Icons.event_rounded,
                      ),
                      child: Text(_dateChargementLabel),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _prixController,
                    keyboardType: TextInputType.number,
                    decoration: _decoration(
                      l10n.nouvelleDemandePrixPropose,
                      Icons.payments_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final prix = double.tryParse(value.trim());
                      if (prix == null || prix < 0)
                        return l10n.nouvelleDemandePrixInvalid;
                      return null;
                    },
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _modeEdition
                              ? Icons.save_rounded
                              : Icons.send_rounded,
                        ),
                  label: Text(
                    _isLoading
                        ? l10n.nouvelleDemandeSubmitting
                        : (_modeEdition
                              ? l10n.nouvelleDemandeUpdateButton
                              : l10n.nouvelleDemandeSubmitButton),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
