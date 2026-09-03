import 'package:flutter/material.dart';

import '../../constants/pays_cedeao.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/utilisateur_admin.dart';
import '../../services/admin_service.dart';
import '../../utils/telephone.dart';
import '../../widgets/responsive_entity_list.dart';

const _bleuFonce = Color(0xFF071A3A);
const _bleuNuit = Color(0xFF102C5C);
const _bleuAccent = Color(0xFF2563EB);

/// Vue admin plateforme des comptes TRANSPORTEUR ou ENTREPRISE — ouverte
/// depuis les cartes "Transporteurs"/"Entreprises" du tableau de bord admin
/// (`GET /admin/utilisateurs/?type_compte=...`, non scopé à request.user).
class AdminUtilisateursScreen extends StatefulWidget {
  final String token;
  final String typeCompte;

  const AdminUtilisateursScreen({
    super.key,
    required this.token,
    required this.typeCompte,
  });

  @override
  State<AdminUtilisateursScreen> createState() =>
      _AdminUtilisateursScreenState();
}

class _AdminUtilisateursScreenState extends State<AdminUtilisateursScreen> {
  late Future<List<UtilisateurAdmin>> _future;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _future = AdminService.getUtilisateurs(
      token: widget.token,
      typeCompte: widget.typeCompte,
    );
  }

  Future<void> _rafraichir() async {
    final future = AdminService.getUtilisateurs(
      token: widget.token,
      typeCompte: widget.typeCompte,
    );
    setState(() => _future = future);
    await future.catchError((_) => <UtilisateurAdmin>[]);
  }

  List<UtilisateurAdmin> _filtrer(List<UtilisateurAdmin> liste) {
    final terme = _recherche.trim().toLowerCase();
    if (terme.isEmpty) return liste;
    return liste
        .where(
          (u) =>
              u.nomAffiche.toLowerCase().contains(terme) ||
              u.telephone.contains(terme) ||
              (u.email ?? '').toLowerCase().contains(terme),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titre = widget.typeCompte == 'TRANSPORTEUR'
        ? l10n.adminUtilisateursTitleTransporteurs
        : l10n.adminUtilisateursTitleEntreprises;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bleuFonce, _bleuNuit],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          titre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _BarreRecherche(
                      hint: l10n.adminSearchHint,
                      onChanged: (v) => setState(() => _recherche = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UtilisateurAdmin>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _EtatErreur(
                    message: '${snapshot.error}'.replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    onRetry: _rafraichir,
                  );
                }

                final utilisateurs = _filtrer(snapshot.data ?? const []);

                if (utilisateurs.isEmpty) {
                  return _EtatVide(
                    message: l10n.adminUtilisateursEmpty,
                    rechercheActive: _recherche.isNotEmpty,
                    l10n: l10n,
                  );
                }

                return ResponsiveEntityList<UtilisateurAdmin>(
                  items: utilisateurs,
                  onRefresh: _rafraichir,
                  mobileCardBuilder: (context, utilisateur) =>
                      _CarteUtilisateur(utilisateur: utilisateur),
                  columns: [
                    TableColumn<UtilisateurAdmin>(
                      label: l10n.tableColonneNom,
                      sortBy: (a, b) => a.nomAffiche.compareTo(b.nomAffiche),
                      cell: (u) => DataCell(Text(u.nomAffiche)),
                    ),
                    TableColumn<UtilisateurAdmin>(
                      label: l10n.tableColonneTelephone,
                      cell: (u) => DataCell(
                        Text(formaterLocal(u.telephone, u.pays) ?? ''),
                      ),
                    ),
                    TableColumn<UtilisateurAdmin>(
                      label: l10n.tableColonnePays,
                      sortBy: (a, b) => (nomParPays(a.pays) ?? a.pays)
                          .compareTo(nomParPays(b.pays) ?? b.pays),
                      cell: (u) => DataCell(Text(nomParPays(u.pays) ?? u.pays)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarreRecherche extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _BarreRecherche({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _EtatErreur extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _EtatErreur({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context).commonRetry),
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
}

class _EtatVide extends StatelessWidget {
  final String message;
  final bool rechercheActive;
  final AppLocalizations l10n;

  const _EtatVide({
    required this.message,
    required this.rechercheActive,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              rechercheActive ? Icons.search_off_rounded : Icons.inbox_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              rechercheActive ? l10n.adminNoResults : message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteUtilisateur extends StatelessWidget {
  final UtilisateurAdmin utilisateur;

  const _CarteUtilisateur({required this.utilisateur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _bleuAccent.withValues(alpha: 0.12),
            child: Text(
              utilisateur.nomAffiche.isNotEmpty
                  ? utilisateur.nomAffiche[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: _bleuAccent,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  utilisateur.nomAffiche,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formaterLocal(utilisateur.telephone, utilisateur.pays) ??
                          '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.public_outlined,
                      size: 13,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nomParPays(utilisateur.pays) ?? utilisateur.pays,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
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
