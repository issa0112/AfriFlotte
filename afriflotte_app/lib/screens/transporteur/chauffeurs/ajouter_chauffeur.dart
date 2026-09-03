import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/pays_cedeao.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/chauffeur_service.dart';
import '../../../utils/telephone.dart';
import '../../../widgets/avatar_picker.dart';
import '../../../widgets/pays_dropdown.dart';

class AjouterChauffeur extends StatefulWidget {
  final String token;

  const AjouterChauffeur({super.key, required this.token});

  @override
  State<AjouterChauffeur> createState() => _AjouterChauffeurState();
}

class _AjouterChauffeurState extends State<AjouterChauffeur> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _permisController = TextEditingController();
  final _codeAccesController = TextEditingController();
  DateTime? _dateExpirationPermis;
  String _pays = 'ML';
  bool _loading = false;
  XFile? _photoSelectionnee;
  Uint8List? _photoApercu;

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _permisController.dispose();
    _codeAccesController.dispose();
    super.dispose();
  }

  String _dateExpirationLabel(AppLocalizations l10n) {
    final date = _dateExpirationPermis;
    if (date == null) return l10n.addChauffeurPermisNotSet;
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year}';
  }

  Future<void> _choisirDateExpiration() async {
    final maintenant = DateTime.now();
    final l10n = AppLocalizations.of(context);

    final choix = await showDatePicker(
      context: context,
      initialDate: _dateExpirationPermis ?? maintenant,
      firstDate: maintenant,
      lastDate: DateTime(maintenant.year + 20),
      helpText: l10n.addChauffeurPermisExpiration,
    );

    if (choix != null) {
      setState(() => _dateExpirationPermis = choix);
    }
  }

  Future<void> _choisirPhoto(XFile fichier) async {
    final octets = await fichier.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoSelectionnee = fichier;
      _photoApercu = octets;
    });
  }

  Future<void> _enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);

    try {
      final chauffeur = await ChauffeurService.createChauffeur(
        token: widget.token,
        data: {
          'nom': _nomController.text.trim(),
          'telephone': normaliserTelephone(_pays, _telephoneController.text.trim()),
          'numero_permis': _permisController.text.trim(),
          if (_dateExpirationPermis != null)
            'date_expiration_permis': _dateExpirationPermis!
                .toIso8601String()
                .split('T')
                .first,
          'code_acces': _codeAccesController.text.trim(),
          'pays': _pays,
        },
      );

      // Photo optionnelle, envoyée séparément : `/chauffeurs/` accepte le
      // JSON ci-dessus, mais le chauffeur doit déjà exister pour recevoir
      // un fichier via `/chauffeurs/<id>/` (même logique que
      // `ajouter_camion.dart`, qui crée puis uploade les images).
      if (_photoSelectionnee != null) {
        await ChauffeurService.uploaderPhotoChauffeur(
          token: widget.token,
          chauffeurId: chauffeur.id,
          photo: _photoSelectionnee!,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addChauffeurSuccess)),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.addChauffeurTitle),
        backgroundColor: const Color(0xFF102C5C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: AvatarPicker(
                    photoUrl: null,
                    previewBytes: _photoApercu,
                    initiales: '+',
                    radius: 40,
                    onImageSelectionnee: _choisirPhoto,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l10n.addChauffeurPhotoOptional,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: l10n.addChauffeurFullName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.addChauffeurNameRequired
                      : null,
                ),
                const SizedBox(height: 20),
                PaysDropdown(
                  value: _pays,
                  label: l10n.addChauffeurPays,
                  onChanged: (value) => setState(() => _pays = value),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.addChauffeurPhone,
                    prefixText: '${indicatifParPays(_pays) ?? ''} ',
                    helperText: l10n.addChauffeurPhoneHelper,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.addChauffeurPhoneRequired;
                    }
                    return validerNumeroLocal(_pays, value.trim());
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _permisController,
                  decoration: InputDecoration(
                    labelText: l10n.addChauffeurPermisNumber,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.addChauffeurPermisRequired
                      : null,
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _choisirDateExpiration,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.addChauffeurPermisExpiration,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(_dateExpirationLabel(l10n)),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _codeAccesController,
                  decoration: InputDecoration(
                    labelText: l10n.addChauffeurAccessCode,
                    helperText: l10n.addChauffeurAccessCodeHelper,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _enregistrer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF102C5C),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(l10n.addChauffeurSave),
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
