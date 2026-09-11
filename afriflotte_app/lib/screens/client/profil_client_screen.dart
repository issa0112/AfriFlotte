import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/dashboard_client_model.dart';
import '../../services/dashboard_service.dart';
import '../../services/profil_service.dart';
import '../../services/storage_service.dart';
import '../../utils/telephone.dart';
import '../../widgets/avatar_picker.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_switcher.dart';
import '../auth/auth_screen.dart';
import '../dashboard_client.dart' show ClientTab;
import '../transporteur/profil/modifier_profil_screen.dart';
import 'historique_client_screen.dart';
import 'missions_client_screen.dart';

class ProfilClientScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;
  final ValueChanged<Map<String, dynamic>> onUtilisateurMisAJour;

  // Rempli uniquement quand l'écran est affiché comme onglet du dashboard
  // (cf. dashboard_client.dart) : permet aux cartes "Activité" de basculer
  // vers l'onglet Missions/Historique plutôt que d'empiler un nouvel écran.
  // Null quand poussé en plein écran (ex. depuis compte_client_screen.dart) :
  // les cartes poussent alors directement l'écran correspondant.
  final void Function(int tab, {String? filtre})? onNavigate;

  const ProfilClientScreen({
    super.key,
    required this.user,
    required this.token,
    required this.onUtilisateurMisAJour,
    this.onNavigate,
  });

  @override
  State<ProfilClientScreen> createState() => _ProfilClientScreenState();
}

class _ProfilClientScreenState extends State<ProfilClientScreen> {
  bool _photoEnCours = false;
  DashboardClientModel? _dashboard;

  @override
  void initState() {
    super.initState();
    _chargerDashboard();
  }

  Future<void> _chargerDashboard() async {
    try {
      final result = await DashboardService.getClientDashboard(widget.token);
      if (mounted) setState(() => _dashboard = result);
    } catch (e) {
      // Silencieux : les cartes retombent sur '—', le reste du profil
      // (infos, actions rapides) reste utilisable sans stats.
    }
  }

  void _ouvrirDemandes() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(ClientTab.historique);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoriqueClientScreen(token: widget.token),
      ),
    );
  }

  void _ouvrirMissions() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(ClientTab.missions);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MissionsClientScreen(token: widget.token),
      ),
    );
  }

  Future<void> _changerPhoto(XFile fichier) async {
    setState(() => _photoEnCours = true);

    try {
      final utilisateurMisAJour = await ProfilService.mettreAJourPhotoProfil(
        token: widget.token,
        photo: fichier,
      );

      widget.onUtilisateurMisAJour(utilisateurMisAJour);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _photoEnCours = false);
    }
  }

  void _ouvrirSelecteurLangue(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
    final user = widget.user;
    final name = (user['nom_entreprise'] ?? user['username'] ?? 'Client').toString();
    final phone = formaterLocal(user['telephone']?.toString(), user['pays']?.toString())
        ?? l10n.profilTNotSet;
    final adresse = (user['adresse'] ?? l10n.profilClientAdresseNotSet).toString();
    final email = (user['email'] ?? l10n.profilTNotSet).toString();
    final role = (user['role'] ?? l10n.profilClientDefaultRole).toString();
    final photoUrl = user['photo_profil']?.toString();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.profilClientTitle),
        centerTitle: true,
        actions: const [ThemeSwitcher(light: true)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF102C5C), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AvatarPicker(
                    photoUrl: photoUrl,
                    initiales: name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    radius: 30,
                    loading: _photoEnCours,
                    onImageSelectionnee: _changerPhoto,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l10n.profilClientVerifiedBadge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProfileCard(
              title: l10n.profilClientMainInfo,
              children: [
                _ProfileItem(icon: Icons.business_outlined, label: l10n.profilClientNom, value: name),
                _ProfileItem(icon: Icons.phone_outlined, label: l10n.profilTPhone, value: phone),
                _ProfileItem(icon: Icons.email_outlined, label: l10n.profilTEmail, value: email),
                _ProfileItem(icon: Icons.location_on_outlined, label: l10n.profilTAddress, value: adresse),
                _ProfileItem(icon: Icons.verified_user_outlined, label: l10n.profilClientType, value: (user['type_compte'] ?? 'ENTREPRISE').toString()),
                _ProfileItem(icon: Icons.badge_outlined, label: l10n.profilClientRole, value: role),
              ],
            ),
            const SizedBox(height: 14),
            _ProfileCard(
              title: l10n.profilClientActivity,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: l10n.profilClientDemandes,
                        value: '${_dashboard?.demandesTotal ?? '—'}',
                        icon: Icons.assignment_rounded,
                        color: const Color(0xFF38BDF8),
                        onTap: _ouvrirDemandes,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        label: l10n.profilClientMissions,
                        value: '${_dashboard?.missionsTotal ?? '—'}',
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFF34D399),
                        onTap: _ouvrirMissions,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ProfileCard(
              title: l10n.profilClientQuickActions,
              children: [
                _ActionTile(
                  icon: Icons.edit_outlined,
                  title: l10n.profilClientEditProfile,
                  subtitle: l10n.profilClientEditProfileSubtitle,
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ModifierProfilScreen(
                          user: user,
                          token: widget.token,
                          onUtilisateurMisAJour: widget.onUtilisateurMisAJour,
                        ),
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
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF102C5C)),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ),
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
        // `Material` explicite : voir `_ActionTile` de profil_transporteur.dart
        // pour la raison (perte d'ancêtre Material immédiat sous
        // `Scaffold(extendBody: true)`).
        Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 19),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTap,
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}
