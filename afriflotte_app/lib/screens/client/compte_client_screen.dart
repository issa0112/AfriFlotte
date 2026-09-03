import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../utils/telephone.dart';
import '../transporteur/profil/securite_compte_screen.dart';
import 'historique_client_screen.dart';
import 'missions_client_screen.dart';
import 'nouvelle_demande_screen.dart';
import 'profil_client_screen.dart';

class CompteClientScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final String token;
  final ValueChanged<Map<String, dynamic>> onUtilisateurMisAJour;

  const CompteClientScreen({
    super.key,
    required this.user,
    required this.token,
    required this.onUtilisateurMisAJour,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = (user['nom_entreprise'] ?? user['username'] ?? 'Client')
        .toString();
    final phone = formaterLocal(user['telephone']?.toString(), user['pays']?.toString())
        ?? l10n.compteClientNotSet;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071A3A), Color(0xFF102C5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.compteClientTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.compteClientSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfilClientScreen(
                              user: user,
                              token: token,
                              onUtilisateurMisAJour: onUtilisateurMisAJour,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: Color(0xFF102C5C),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              phone,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.compteClientActiveBadge,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
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
                _QuickActionsCard(token: token),
                const SizedBox(height: 16),
                _InfoSection(user: user),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final String token;

  const _QuickActionsCard({required this.token});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final actions = [
      _ActionTile(
        title: l10n.compteClientNewRequestTitle,
        subtitle: l10n.compteClientNewRequestSubtitle,
        icon: Icons.add_circle_outline,
        color: const Color(0xFF38BDF8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NouvelleDemandeScreen(token: token),
            ),
          );
        },
      ),
      _ActionTile(
        title: l10n.compteClientMissionsTitle,
        subtitle: l10n.compteClientMissionsSubtitle,
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF34D399),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MissionsClientScreen(token: token),
            ),
          );
        },
      ),
      _ActionTile(
        title: l10n.compteClientHistoryTitle,
        subtitle: l10n.compteClientHistorySubtitle,
        icon: Icons.history_outlined,
        color: const Color(0xFFF59E0B),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistoriqueClientScreen(token: token),
            ),
          );
        },
      ),
      _ActionTile(
        title: l10n.compteClientSecurityTitle,
        subtitle: l10n.compteClientSecuritySubtitle,
        icon: Icons.lock_outline,
        color: const Color(0xFFA78BFA),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SecuriteCompteScreen(token: token),
            ),
          );
        },
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.compteClientQuickActions,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...actions,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Map<String, dynamic> user;

  const _InfoSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.compteClientAccountInfo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: l10n.compteClientName,
            value: (user['nom_entreprise'] ?? user['username'] ?? 'N/A')
                .toString(),
          ),
          _InfoRow(
            title: l10n.compteClientPhone,
            value: formaterLocal(user['telephone']?.toString(), user['pays']?.toString())
                ?? l10n.compteClientNotSet,
          ),
          _InfoRow(
            title: l10n.compteClientAccountType,
            value: (user['type_compte'] ?? 'ENTREPRISE').toString(),
          ),
          _InfoRow(title: l10n.compteClientStatus, value: l10n.compteClientStatusValue),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
