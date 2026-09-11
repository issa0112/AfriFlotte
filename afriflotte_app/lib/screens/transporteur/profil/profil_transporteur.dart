import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/pays_cedeao.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/profil_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/telephone.dart';
import '../../../widgets/avatar_picker.dart';
import '../../../widgets/language_switcher.dart';
import '../../../widgets/theme_switcher.dart';
import '../../auth/auth_screen.dart';
import 'modifier_profil_screen.dart';
import 'securite_compte_screen.dart';

class ProfilTransporteur extends StatelessWidget {
  final Map<String, dynamic> user;
  final String token;
  final ValueChanged<Map<String, dynamic>>? onProfilMisAJour;

  const ProfilTransporteur({
    super.key,
    required this.user,
    required this.token,
    this.onProfilMisAJour,
  });

  String _safeText(BuildContext context, dynamic value) {
    final fallback = AppLocalizations.of(context).profilTNotSet;
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _libelleTypeCompte(BuildContext context, dynamic typeCompte) {
    final l10n = AppLocalizations.of(context);
    switch (typeCompte) {
      case 'TRANSPORTEUR':
        return l10n.profilTRoleTransporteur;
      case 'ENTREPRISE':
        return l10n.profilTRoleEntreprise;
      case 'ADMIN':
        return l10n.profilTRoleAdmin;
      default:
        return l10n.profilTRoleDefault;
    }
  }

  void _ouvrirSelecteurLangue(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.profilTLanguage,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.profilTLanguageSubtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Center(child: LanguageSwitcher()),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Les clés lues ici doivent correspondre à ce que renvoie réellement
    // TelephoneTokenObtainPairSerializer côté Django (id/username/telephone/
    // type_compte/nom_entreprise/email/adresse/pays) — avant ce correctif
    // l'écran lisait prenom/nom/nom_utilisateur/ville/role, des clés qui
    // n'ont jamais existé, donc tout affichait systématiquement le repli.
    final nomEntreprise = user["nom_entreprise"]?.toString().trim();
    final username = _safeText(context, user["username"]);
    final nomAffiche = (nomEntreprise != null && nomEntreprise.isNotEmpty)
        ? nomEntreprise
        : username;
    final telephone = _safeText(
      context,
      formaterLocal(user["telephone"]?.toString(), user["pays"]?.toString()),
    );
    final email = _safeText(context, user["email"]);
    final adresse = _safeText(context, user["adresse"]);
    final pays = nomParPays(user["pays"]?.toString()) ?? l10n.profilTNotSet;
    final role = _libelleTypeCompte(context, user["type_compte"]);
    final photoUrl = user["photo_profil"]?.toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.profilTTitle),
        centerTitle: true,
        actions: const [ThemeSwitcher(light: true)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            _ProfileHeader(
              nomAffiche: nomAffiche,
              role: role,
              telephone: telephone,
              photoUrl: photoUrl,
              token: token,
              onPhotoMiseAJour: onProfilMisAJour,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: l10n.modifierProfilInfoSection,
              icon: Icons.badge_outlined,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: l10n.profilTUsername,
                    value: username,
                  ),
                  if (nomEntreprise != null && nomEntreprise.isNotEmpty)
                    _InfoRow(
                      icon: Icons.apartment_outlined,
                      label: l10n.profilTCompany,
                      value: nomEntreprise,
                    ),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: l10n.profilTPhone,
                    value: telephone,
                  ),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: l10n.profilTEmail,
                    value: email,
                  ),
                  _InfoRow(
                    icon: Icons.home_outlined,
                    label: l10n.profilTAddress,
                    value: adresse,
                  ),
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    label: l10n.profilTCountry,
                    value: pays,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: l10n.profilTActionsSection,
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.edit_outlined,
                    title: l10n.profilTEditProfile,
                    subtitle: l10n.profilTEditProfileSubtitle,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ModifierProfilScreen(
                            user: user,
                            token: token,
                            onUtilisateurMisAJour: (u) => onProfilMisAJour?.call(u),
                          ),
                        ),
                      );
                    },
                  ),
                  _ActionTile(
                    icon: Icons.lock_outline_rounded,
                    title: l10n.profilTSecurity,
                    subtitle: l10n.profilTSecuritySubtitle,
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SecuriteCompteScreen(token: token),
                        ),
                      );
                    },
                  ),
                  _ActionTile(
                    icon: Icons.translate_rounded,
                    title: l10n.profilTLanguage,
                    subtitle: l10n.profilTLanguageSubtitle,
                    color: Colors.teal,
                    onTap: () => _ouvrirSelecteurLangue(context),
                  ),
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    title: l10n.profilTLogout,
                    subtitle: l10n.profilTLogoutSubtitle,
                    color: Colors.redAccent,
                    showDivider: false,
                    onTap: () async {
                      // `popUntil(isFirst)` ne déconnectait pas réellement :
                      // le dashboard EST déjà la première route (posée par
                      // naviguerApresConnexion avec pushAndRemoveUntil), donc
                      // ce bouton ne faisait rien. Il faut vider les tokens
                      // stockés et remplacer toute la pile par l'écran de
                      // connexion.
                      await StorageService.clear();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  final String nomAffiche;
  final String role;
  final String telephone;
  final String? photoUrl;
  final String token;
  final ValueChanged<Map<String, dynamic>>? onPhotoMiseAJour;

  const _ProfileHeader({
    required this.nomAffiche,
    required this.role,
    required this.telephone,
    required this.photoUrl,
    required this.token,
    required this.onPhotoMiseAJour,
  });

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _uploadEnCours = false;

  Future<void> _changerPhoto(XFile fichier) async {
    setState(() => _uploadEnCours = true);

    try {
      final utilisateurMisAJour = await ProfilService.mettreAJourPhotoProfil(
        token: widget.token,
        photo: fichier,
      );

      widget.onPhotoMiseAJour?.call(utilisateurMisAJour);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _uploadEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102C5C),
            Color(0xFF2563EB),
          ],
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
            photoUrl: widget.photoUrl,
            initiales: widget.nomAffiche.isNotEmpty
                ? widget.nomAffiche[0].toUpperCase()
                : "T",
            loading: _uploadEnCours,
            onImageSelectionnee: _changerPhoto,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nomAffiche,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.role,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.telephone,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool showDivider;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // `Material` explicite : sans lui, le `ListTile` sous `Scaffold(
        // extendBody: true)` perd son ancêtre Material immédiat (le corps
        // flotte désormais au-dessus de la barre plutôt que dans le flux
        // normal), et Flutter avertit que le fond/l'effet tactile risque de
        // ne pas s'afficher.
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 19),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTap,
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}
