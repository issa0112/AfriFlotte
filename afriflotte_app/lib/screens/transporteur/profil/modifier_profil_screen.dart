import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/profil_service.dart';
import '../../../widgets/avatar_picker.dart';
import '../../../widgets/pays_dropdown.dart';

const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

final RegExp _emailValide = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Formulaire de modification des informations personnelles (transporteur ET
/// client, qui partagent le même modèle `User`). Ne touche ni `username` ni
/// `telephone` : ce sont les identifiants de connexion, les changer
/// mériterait un flux de vérification à part (hors périmètre ici). La photo
/// se met à jour immédiatement au choix (upload séparé, pas soumis avec le
/// reste du formulaire) ; chaque changement — photo ou "Enregistrer" —
/// prévient l'appelant via [onUtilisateurMisAJour] pour que le reste de
/// l'app reflète l'état à jour sans reconnexion, même si l'utilisateur
/// ressort de l'écran sans jamais toucher "Enregistrer".
class ModifierProfilScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;
  final ValueChanged<Map<String, dynamic>> onUtilisateurMisAJour;

  const ModifierProfilScreen({
    super.key,
    required this.user,
    required this.token,
    required this.onUtilisateurMisAJour,
  });

  @override
  State<ModifierProfilScreen> createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomEntrepriseController;
  late final TextEditingController _emailController;
  late final TextEditingController _adresseController;
  late String _pays;
  String? _photoUrl;

  bool _loading = false;
  bool _photoEnCours = false;

  @override
  void initState() {
    super.initState();
    _nomEntrepriseController = TextEditingController(
      text: widget.user['nom_entreprise']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.user['email']?.toString() ?? '',
    );
    _adresseController = TextEditingController(
      text: widget.user['adresse']?.toString() ?? '',
    );
    _pays = widget.user['pays']?.toString() ?? 'ML';
    _photoUrl = widget.user['photo_profil']?.toString();
  }

  @override
  void dispose() {
    _nomEntrepriseController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _changerPhoto(XFile fichier) async {
    setState(() => _photoEnCours = true);

    try {
      final utilisateurMisAJour = await ProfilService.mettreAJourPhotoProfil(
        token: widget.token,
        photo: fichier,
      );

      widget.onUtilisateurMisAJour(utilisateurMisAJour);

      if (!mounted) return;
      setState(() => _photoUrl = utilisateurMisAJour['photo_profil']?.toString());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _photoEnCours = false);
    }
  }

  Future<void> _enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);

    try {
      final utilisateurMisAJour = await ProfilService.mettreAJourProfil(
        token: widget.token,
        data: {
          "nom_entreprise": _nomEntrepriseController.text.trim(),
          "email": _emailController.text.trim(),
          "adresse": _adresseController.text.trim(),
          "pays": _pays,
        },
      );

      widget.onUtilisateurMisAJour(utilisateurMisAJour);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.modifierProfilSuccess)),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final username = widget.user['username']?.toString() ?? '';
    final telephone = widget.user['telephone']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.modifierProfilTitle),
        centerTitle: true,
        backgroundColor: _bleuNuit,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [_bleuNuit, _bleuAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AvatarPicker(
                      photoUrl: _photoUrl,
                      initiales: username.isNotEmpty ? username[0].toUpperCase() : "T",
                      radius: 28,
                      loading: _photoEnCours,
                      onImageSelectionnee: _changerPhoto,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 13, color: Colors.white70),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  l10n.modifierProfilLoginId(telephone),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 18, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          l10n.modifierProfilInfoSection,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nomEntrepriseController,
                      decoration: _decoration(
                        l10n.modifierProfilCompanyName,
                        Icons.apartment_outlined,
                        hint: l10n.modifierProfilCompanyNameHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration(l10n.modifierProfilEmail, Icons.email_outlined, hint: l10n.modifierProfilEmailHint),
                      validator: (value) {
                        final texte = value?.trim() ?? '';
                        if (texte.isEmpty) return null;
                        return _emailValide.hasMatch(texte) ? null : l10n.modifierProfilEmailInvalid;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adresseController,
                      decoration: _decoration(l10n.modifierProfilAddress, Icons.home_outlined, hint: l10n.modifierProfilAddressHint),
                    ),
                    const SizedBox(height: 16),
                    PaysDropdown(
                      value: _pays,
                      label: l10n.modifierProfilCountry,
                      onChanged: (value) => setState(() => _pays = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _enregistrer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bleuNuit,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Text(
                          l10n.modifierProfilSaveButton,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
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
