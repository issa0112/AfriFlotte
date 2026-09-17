import 'package:flutter/material.dart';

import '../constants/pays_cedeao.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'client/missions_client_screen.dart';
import 'client/propositions_recues_screen.dart';
import 'transporteur/missions/demandes_disponibles.dart';
import 'transporteur/missions/mes_missions_screen.dart';
import 'transporteur/missions/mes_propositions_screen.dart';

const _typeIcones = {
  'NOUVELLE_DEMANDE': Icons.campaign_outlined,
  'NOUVELLE_PROPOSITION': Icons.local_offer_outlined,
  'PROPOSITION_ACCEPTEE': Icons.check_circle_outline,
  'PROPOSITION_REFUSEE': Icons.cancel_outlined,
  'MISSION_CREEE': Icons.assignment_outlined,
  'MISSION_DEMARREE': Icons.local_shipping_outlined,
  'MISSION_TERMINEE': Icons.flag_outlined,
  'MISSION_ANNULEE': Icons.event_busy_outlined,
};

// Types dont le texte (`message`, figé à la création) décrit une Proposition
// — cf. `Notification.proposition` côté Django : ce lien vivant permet de
// vérifier que le prix affiché correspond encore à la réalité, ou de savoir
// que la proposition a depuis été supprimée.
const _typesProposition = {
  'NOUVELLE_PROPOSITION',
  'PROPOSITION_ACCEPTEE',
  'PROPOSITION_REFUSEE',
};

/// Horodatage relatif d'une notification ("à l'instant", "il y a 5 min"...),
/// ou une date courte au-delà d'une semaine. `createdAt` vient de Django en
/// UTC (`USE_TZ=True`) ; `DateTime.difference` reste correct qu'on compare
/// à un `DateTime.now()` local ou non, puisqu'il opère sur l'instant absolu
/// sous-jacent, pas sur la représentation locale/UTC.
String _tempsRelatif(AppLocalizations l10n, DateTime? createdAt) {
  if (createdAt == null) return '';

  final ecart = DateTime.now().difference(createdAt);

  if (ecart.inMinutes < 1) return l10n.notifTimeJustNow;
  if (ecart.inHours < 1) return l10n.notifTimeMinutes(ecart.inMinutes);
  if (ecart.inDays < 1) return l10n.notifTimeHours(ecart.inHours);
  if (ecart.inDays < 7) return l10n.notifTimeDays(ecart.inDays);

  final jour = createdAt.day.toString().padLeft(2, '0');
  final mois = createdAt.month.toString().padLeft(2, '0');
  return '$jour/$mois/${createdAt.year}';
}

/// Écran de notifications internes, partagé transporteur/client — le
/// contenu (type/message) vient déjà formaté du backend.
class NotificationsScreen extends StatefulWidget {
  final String token;

  /// Rôle de l'utilisateur connecté (pas déductible du seul `type` de la
  /// notification, cf. `_ouvrir` : MISSION_DEMARREE/MISSION_TERMINEE sont
  /// envoyées au transporteur EN PLUS du client quand c'est le chauffeur qui
  /// démarre/termine — core/views.py `chauffeur_demarrer_mission`/
  /// `chauffeur_terminer_mission`).
  final bool estTransporteur;

  const NotificationsScreen({
    super.key,
    required this.token,
    this.estTransporteur = false,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _futureNotifications;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureNotifications = NotificationService.getNotifications(widget.token);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _rafraichir() async {
    final future = NotificationService.getNotifications(widget.token);
    // Bloc, pas flèche : voir liste_chauffeurs.dart._rafraichir pour le
    // pourquoi (setState() planterait, le callback "retournerait" le Future).
    setState(() {
      _futureNotifications = future;
    });
    await future.catchError((_) => <AppNotification>[]);
  }

  // NOUVELLE_PROPOSITION va toujours à `demande.client`, PROPOSITION_ACCEPTEE/
  // REFUSEE et NOUVELLE_DEMANDE vont toujours au transporteur (cf.
  // core/services.py) : le type seul suffit pour ces cas-là. Les MISSION_*
  // en revanche ne suffisent PAS à eux seuls : MISSION_DEMARREE/TERMINEE sont
  // envoyées à `mission.client` quand l'acteur est le transporteur, mais
  // AUSSI à `mission.transporteur` quand l'acteur est le chauffeur
  // (core/views.py `chauffeur_demarrer_mission`/`chauffeur_terminer_mission`)
  // — d'où `widget.estTransporteur` pour choisir le bon écran de missions.
  Future<void> _ouvrir(AppNotification notification) async {
    if (!notification.lue) {
      try {
        await NotificationService.marquerLue(widget.token, notification.id);
        await _rafraichir();
      } catch (_) {
        // Un échec de marquage n'empêche pas de continuer à consulter.
      }
    }

    if (!mounted) return;

    switch (notification.type) {
      case 'NOUVELLE_PROPOSITION':
        // Reçu par l'entreprise : la proposition attend une décision.
        await _ouvrirEcranProposition(
          notification,
          (highlightId) => PropositionsRecuesScreen(
            token: widget.token,
            highlightId: highlightId,
          ),
        );
        break;

      case 'PROPOSITION_REFUSEE':
        // Reçu par le transporteur : suivi en lecture seule de sa
        // proposition envoyée (rien à décider ici, contrairement à
        // NOUVELLE_PROPOSITION côté entreprise).
        await _ouvrirEcranProposition(
          notification,
          (highlightId) => MesPropositionsScreen(
            token: widget.token,
            highlightId: highlightId,
          ),
        );
        break;

      case 'NOUVELLE_DEMANDE':
        if (notification.propositionId != null) {
          // Camion le mieux noté : une proposition a déjà été envoyée
          // automatiquement pour ce transporteur (cf. core/services.py
          // proposer_camions_pour_demande).
          await _ouvrirEcranProposition(
            notification,
            (highlightId) => MesPropositionsScreen(
              token: widget.token,
              highlightId: highlightId,
            ),
          );
        } else {
          // Un autre transporteur a eu le meilleur score : celui-ci a
          // seulement été prévenu qu'un camion à lui correspond, sans
          // proposition auto-créée — direction la liste où il peut
          // répondre lui-même.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DemandesDisponibles(token: widget.token),
            ),
          );
        }
        break;

      case 'PROPOSITION_ACCEPTEE':
        // La proposition acceptée est devenue une Mission : c'est là qu'il
        // y a quelque chose à voir/faire (démarrer, terminer...).
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MesMissionsScreen(token: widget.token),
          ),
        );
        break;

      case 'MISSION_CREEE':
      case 'MISSION_DEMARREE':
      case 'MISSION_TERMINEE':
      case 'MISSION_ANNULEE':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => widget.estTransporteur
                ? MesMissionsScreen(token: widget.token)
                : MissionsClientScreen(token: widget.token),
          ),
        );
        break;
    }
  }

  /// Factorise le garde-fou "propositionId == null" (proposition supprimée
  /// depuis l'envoi de la notification) entre les deux écrans possibles
  /// (`PropositionsRecuesScreen` côté entreprise, `MesPropositionsScreen`
  /// côté transporteur) — seul le widget de destination change.
  Future<void> _ouvrirEcranProposition(
    AppNotification notification,
    Widget Function(int highlightId) construireEcran,
  ) async {
    final l10n = AppLocalizations.of(context);
    final propositionId = notification.propositionId;

    if (propositionId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.notifPropositionDeleted)));
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => construireEcran(propositionId)));
  }

  Future<void> _toutMarquerLu() async {
    try {
      await NotificationService.marquerToutesLues(widget.token);
      await _rafraichir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.notifTitle),
        backgroundColor: const Color(0xFF102C5C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: l10n.notifMarkAllRead,
            onPressed: _toutMarquerLu,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildSearchField(),
          ),
          Expanded(
            child: FutureBuilder<List<AppNotification>>(
              future: _futureNotifications,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${snapshot.error}'.replaceFirst('Exception: ', ''),
                    ),
                  );
                }

                final notifications =
                    snapshot.data ?? const <AppNotification>[];
                final query = _searchController.text.trim().toLowerCase();
                final visibles = query.isEmpty
                    ? notifications
                    : notifications
                          .where(
                            (n) =>
                                n.message.toLowerCase().contains(query) ||
                                n.typeLibelle.toLowerCase().contains(query),
                          )
                          .toList();

                if (visibles.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _rafraichir,
                    child: ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            notifications.isEmpty
                                ? l10n.notifEmpty
                                : 'Aucun résultat trouvé',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _rafraichir,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: visibles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = visibles[index];

                      return Card(
                        elevation: 0,
                        color: notification.lue
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          onTap: () => _ouvrir(notification),
                          leading: Icon(
                            _typeIcones[notification.type] ??
                                Icons.notifications_outlined,
                            color: const Color(0xFF102C5C),
                          ),
                          title: Text(
                            notification.message,
                            style: TextStyle(
                              fontWeight: notification.lue
                                  ? FontWeight.normal
                                  : FontWeight.w700,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${notification.typeLibelle} · ${_tempsRelatif(l10n, notification.createdAt)}',
                              ),
                              if (_typesProposition.contains(
                                notification.type,
                              ))
                                _StatutProposition(notification: notification),
                            ],
                          ),
                          isThreeLine: _typesProposition.contains(
                            notification.type,
                          ),
                          trailing: notification.lue
                              ? null
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF102C5C),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Prix actuel de la proposition liée à une notification, sourcé du backend
/// en direct (`proposition_prix`/`proposition_devise`) — jamais reparsé
/// depuis `message`, qui est figé et peut diverger si la proposition a
/// changé de statut ou a été supprimée depuis l'envoi de la notification.
class _StatutProposition extends StatelessWidget {
  final AppNotification notification;

  const _StatutProposition({required this.notification});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (notification.propositionId == null) {
      return Text(
        l10n.notifPropositionDeleted,
        style: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Text(
      formatMontant(
        notification.propositionPrix,
        notification.propositionDevise,
      ),
      style: const TextStyle(
        color: Color(0xFF2563EB),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
