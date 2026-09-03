import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/format_camion.dart';
import '../../../constants/type_camion.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/camion.dart';
import '../../../services/camion_service.dart';
import '../../../widgets/pays_dropdown.dart';

const _bleuNuit = Color(0xFF102C5C);

class AjouterCamion extends StatefulWidget {
  final String token;

  /// Non-null : formulaire en mode édition, pré-rempli avec ce camion et
  /// enregistré via PATCH plutôt que POST. La gestion des photos reste sur
  /// son propre écran ([GererPhotosCamion]) — inutile de la dupliquer ici.
  final Camion? camion;

  const AjouterCamion({super.key, required this.token, this.camion});

  @override
  State<AjouterCamion> createState() => _AjouterCamionState();
}

class _AjouterCamionState extends State<AjouterCamion> {
  final _formKey = GlobalKey<FormState>();
  final immatriculationController = TextEditingController();
  final marqueController = TextEditingController();
  final modeleController = TextEditingController();
  final capaciteController = TextEditingController();
  final villeController = TextEditingController();
  final formatAutreController = TextEditingController();
  final essieuxController = TextEditingController();

  String typeCamion = "CITERNE";
  String formatCamion = "";
  String pays = "ML";
  bool loading = false;
  final ImagePicker _picker = ImagePicker();

  bool get _modeEdition => widget.camion != null;

  // (fichier, octets déjà lus) : les octets sont lus une fois au moment du
  // choix pour permettre l'aperçu via Image.memory, seul mode qui fonctionne
  // à la fois sur mobile/desktop ET sur le web (Image.file n'existe pas sur
  // Flutter Web, il n'y a pas de vrai système de fichiers dans le navigateur).
  final List<(XFile, Uint8List)> _selectedImages = [];

  final types = typesCamion;

  @override
  void initState() {
    super.initState();

    final camion = widget.camion;
    if (camion != null) {
      typeCamion = camion.typeCamion;
      formatCamion = camion.formatCamion;
      pays = camion.pays;
      immatriculationController.text = camion.immatriculation;
      marqueController.text = camion.marque;
      modeleController.text = camion.modele;
      capaciteController.text = camion.capacite.toStringAsFixed(0);
      villeController.text = camion.ville;
      formatAutreController.text = camion.formatAutre;
      essieuxController.text = camion.essieux?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    immatriculationController.dispose();
    marqueController.dispose();
    modeleController.dispose();
    capaciteController.dispose();
    villeController.dispose();
    formatAutreController.dispose();
    essieuxController.dispose();
    super.dispose();
  }

  void _changerTypeCamion(String value) {
    setState(() {
      typeCamion = value;
      // Un format choisi pour l'ancien type peut ne plus être valide pour
      // le nouveau (ex. "40 pieds" n'a pas de sens pour une citerne) : on
      // le réinitialise plutôt que de laisser une valeur incohérente que le
      // serveur rejettera de toute façon.
      if (!formatsPourType(typeCamion).contains(formatCamion)) {
        // Si Capacité/Essieux étaient verrouillés par ce format (ex.
        // citerne "43 000 L"), leur valeur n'a plus de sens pour le nouveau
        // type : on les vide plutôt que de laisser un nombre périmé traîner
        // dans un champ qui redevient éditable.
        if (capacitePourFormatCiterne.containsKey(formatCamion)) {
          capaciteController.clear();
        }
        if (essieuxPourFormatBenne.containsKey(formatCamion)) {
          essieuxController.clear();
        }
        formatCamion = "";
      }
    });
  }

  /// Le format peut imposer `capacite` (citerne) ou `essieux` (benne) — le
  /// serveur écrase ces champs de toute façon (`CamionSerializer.validate`),
  /// donc on les pré-remplit/verrouille ici plutôt que de laisser saisir une
  /// valeur qui serait silencieusement ignorée à l'enregistrement.
  void _changerFormatCamion(String value) {
    setState(() {
      formatCamion = value;

      final capaciteImposee = capacitePourFormatCiterne[value];
      if (capaciteImposee != null) {
        capaciteController.text = capaciteImposee.toString();
      }

      final essieuxImposes = essieuxPourFormatBenne[value];
      if (essieuxImposes != null) {
        essieuxController.text = essieuxImposes.toString();
      }
    });
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();

    if (images.isEmpty) return;

    final selection = <(XFile, Uint8List)>[];
    for (final xFile in images.take(4)) {
      selection.add((xFile, await xFile.readAsBytes()));
    }

    if (!mounted) return;
    setState(() {
      _selectedImages
        ..clear()
        ..addAll(selection);
    });
  }

  Future<void> enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() => loading = true);

    final essieux = int.tryParse(essieuxController.text.trim());

    final data = {
      "type_camion": typeCamion,
      "format_camion": formatCamion,
      "format_autre": formatCamion == 'AUTRE'
          ? formatAutreController.text.trim()
          : '',
      if (essieux != null) "essieux": essieux,
      "immatriculation": immatriculationController.text.trim(),
      "marque": marqueController.text.trim(),
      "modele": modeleController.text.trim(),
      "capacite": capaciteController.text.trim(),
      "unite_capacite": uniteCapacitePourType(typeCamion),
      "ville": villeController.text.trim().isEmpty
          ? "Bamako"
          : villeController.text.trim(),
      "pays": pays,
    };

    try {
      if (_modeEdition) {
        await CamionService.modifierCamion(
          token: widget.token,
          camionId: widget.camion!.id,
          data: data,
        );
      } else {
        final camion = await CamionService.createCamion(
          token: widget.token,
          data: data,
        );

        for (final (xFile, _) in _selectedImages) {
          await CamionService.uploadImageCamion(
            token: widget.token,
            camionId: camion.id,
            imageFile: xFile,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modeEdition ? l10n.editCamionSuccess : l10n.addCamionSuccess,
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_modeEdition ? l10n.editCamionTitle : l10n.addCamionTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: typeCamion,
                  isExpanded: true,
                  decoration: _decoration(
                    l10n.addCamionType,
                    Icons.category_outlined,
                  ),
                  items: types
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(libelleTypeCamion(l10n, e)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _changerTypeCamion(value!),
                ),
                if (formatsPourType(typeCamion).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('format_$typeCamion'),
                    initialValue: formatCamion.isEmpty ? null : formatCamion,
                    isExpanded: true,
                    decoration: _decoration(
                      l10n.formatCamionLabel,
                      Icons.straighten_outlined,
                    ),
                    items: formatsPourType(typeCamion)
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(libelleFormatCamion(l10n, f)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => _changerFormatCamion(value ?? ""),
                  ),
                  if (formatCamion == 'AUTRE') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: formatAutreController,
                      decoration: _decoration(
                        l10n.formatCamionAutrePrecision,
                        Icons.edit_outlined,
                      ),
                      validator: (value) =>
                          formatCamion == 'AUTRE' &&
                              (value == null || value.trim().isEmpty)
                          ? l10n.formatCamionAutrePrecision
                          : null,
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: immatriculationController,
                  decoration: _decoration(
                    l10n.addCamionRegistration,
                    Icons.pin_outlined,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.addCamionRegistrationRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: marqueController,
                  decoration: _decoration(
                    l10n.addCamionMarque,
                    Icons.local_shipping_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: modeleController,
                  decoration: _decoration(
                    l10n.addCamionModele,
                    Icons.directions_car_filled_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capaciteController,
                  keyboardType: TextInputType.number,
                  // Verrouillé quand le format choisi impose déjà la
                  // capacité (ex. "43 000 L") : le serveur écraserait de
                  // toute façon une valeur divergente, autant ne pas laisser
                  // taper quelque chose qui sera ignoré.
                  readOnly: capacitePourFormatCiterne.containsKey(formatCamion),
                  decoration: _decoration(
                    '${l10n.addCamionCapacity} (${uniteCapacitePourType(typeCamion)})',
                    Icons.scale_outlined,
                    hint: l10n.addCamionCapacityHint,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.addCamionCapacityRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: essieuxController,
                  keyboardType: TextInputType.number,
                  readOnly: essieuxPourFormatBenne.containsKey(formatCamion),
                  decoration: _decoration(
                    l10n.essieuxLabel,
                    Icons.tune_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: villeController,
                  decoration: _decoration(
                    l10n.addCamionVille,
                    Icons.location_on_outlined,
                    hint: l10n.addCamionVilleHint,
                  ),
                ),
                const SizedBox(height: 16),
                PaysDropdown(
                  value: pays,
                  label: l10n.addCamionPays,
                  onChanged: (value) => setState(() => pays = value),
                ),
                if (!_modeEdition) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.addCamionPhotosLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_selectedImages.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedImages
                          .map(
                            (image) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                image.$2,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: loading ? null : _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.addCamionChoosePhotos),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : enregistrer,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            l10n.addCamionSave,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
