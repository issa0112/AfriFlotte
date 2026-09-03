import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/position_gps.dart';
import '../../../services/position_service.dart';

String _formatDateHeure(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  final jour = local.day.toString().padLeft(2, '0');
  final mois = local.month.toString().padLeft(2, '0');
  final heure = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$jour/$mois à $heure:$minute';
}

/// Historique des pings GPS d'un camion de mission (bouton "Historique" du
/// suivi GPS transporteur).
class HistoriquePositionsScreen extends StatefulWidget {
  final String token;
  final int missionCamionId;
  final String immatriculation;

  const HistoriquePositionsScreen({
    super.key,
    required this.token,
    required this.missionCamionId,
    required this.immatriculation,
  });

  @override
  State<HistoriquePositionsScreen> createState() =>
      _HistoriquePositionsScreenState();
}

class _HistoriquePositionsScreenState
    extends State<HistoriquePositionsScreen> {
  late Future<List<PositionGps>> _futurePositions;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  void _charger() {
    _futurePositions = PositionService.getHistorique(
      token: widget.token,
      missionCamionId: widget.missionCamionId,
    );
  }

  Future<void> _refresh() async {
    setState(_charger);
    await _futurePositions.catchError((_) => <PositionGps>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.gpsHistoryTitle(widget.immatriculation)),
        backgroundColor: const Color(0xFF102C5C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<PositionGps>>(
        future: _futurePositions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 52,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${snapshot.error}'.replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.commonRetry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final positions = snapshot.data ?? const <PositionGps>[];

          if (positions.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.gpsHistoryEmptyTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.gpsHistoryEmptySubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              itemCount: positions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _PositionCard(position: positions[index]),
            ),
          );
        },
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final PositionGps position;

  const _PositionCard({required this.position});

  @override
  Widget build(BuildContext context) {
    final vitesse = position.vitesse;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateHeure(position.date),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          if (vitesse != null)
            Text(
              l10n.gpsSpeedUnit(vitesse.toStringAsFixed(0)),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
        ],
      ),
    );
  }
}
