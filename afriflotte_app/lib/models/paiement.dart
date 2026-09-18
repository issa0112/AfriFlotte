import 'litige.dart';
import 'preuve_paiement.dart';

/// Le paiement d'une mission (`PaiementSerializer` côté Django) — un seul par
/// mission, mode CARTE ou MANUEL, séquestré jusqu'à la libération des fonds
/// (livraison confirmée) puis versé au transporteur. Voir `core/models.py`
/// (`Paiement.Statut`) pour la machine à états complète.
class Paiement {
  final int id;
  final int missionId;
  final String missionTrajet;
  final String clientNom;
  final String transporteurNom;
  final String mode;
  final String modeLibelle;
  final double montantTotal;
  final String devise;
  final double commissionTaux;
  final double commissionMontant;
  final double montantTransporteur;
  final String statut;
  final String statutLibelle;
  final int? agentId;
  final String referenceExterne;
  final String carteMarque;
  final String carteDernier4;
  final String carteExpiration;
  final String mobileOperateur;
  final String mobileNumero;
  final bool litigeEnCours;
  final String? motifRemboursement;
  final DateTime? dateEncaissement;
  final DateTime? dateSecurisation;
  final DateTime? dateLiberation;
  final DateTime? dateVersement;
  final DateTime? dateRemboursement;
  final DateTime? createdAt;
  final List<PreuvePaiement> preuves;
  final List<Litige> litiges;

  const Paiement({
    required this.id,
    required this.missionId,
    required this.missionTrajet,
    required this.clientNom,
    required this.transporteurNom,
    required this.mode,
    required this.modeLibelle,
    required this.montantTotal,
    required this.devise,
    required this.commissionTaux,
    required this.commissionMontant,
    required this.montantTransporteur,
    required this.statut,
    required this.statutLibelle,
    this.agentId,
    this.referenceExterne = '',
    this.carteMarque = '',
    this.carteDernier4 = '',
    this.carteExpiration = '',
    this.mobileOperateur = '',
    this.mobileNumero = '',
    this.litigeEnCours = false,
    this.motifRemboursement,
    this.dateEncaissement,
    this.dateSecurisation,
    this.dateLiberation,
    this.dateVersement,
    this.dateRemboursement,
    this.createdAt,
    this.preuves = const [],
    this.litiges = const [],
  });

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      missionId: json['mission'] is int
          ? json['mission'] as int
          : int.parse('${json['mission']}'),
      missionTrajet: json['mission_trajet']?.toString() ?? '',
      clientNom: json['client_nom']?.toString() ?? '',
      transporteurNom: json['transporteur_nom']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'CARTE',
      modeLibelle: json['mode_libelle']?.toString() ?? '',
      montantTotal: _asDouble(json['montant_total']) ?? 0,
      devise: json['devise']?.toString() ?? '',
      commissionTaux: _asDouble(json['commission_taux']) ?? 0,
      commissionMontant: _asDouble(json['commission_montant']) ?? 0,
      montantTransporteur: _asDouble(json['montant_transporteur']) ?? 0,
      statut: json['statut']?.toString() ?? 'EN_ATTENTE',
      statutLibelle: json['statut_libelle']?.toString() ?? '',
      agentId: json['agent'] is int ? json['agent'] as int : null,
      referenceExterne: json['reference_externe']?.toString() ?? '',
      carteMarque: json['carte_marque']?.toString() ?? '',
      carteDernier4: json['carte_dernier4']?.toString() ?? '',
      carteExpiration: json['carte_expiration']?.toString() ?? '',
      mobileOperateur: json['mobile_operateur']?.toString() ?? '',
      mobileNumero: json['mobile_numero']?.toString() ?? '',
      litigeEnCours: json['litige_en_cours'] == true,
      motifRemboursement: json['motif_remboursement']?.toString(),
      dateEncaissement: _asDate(json['date_encaissement']),
      dateSecurisation: _asDate(json['date_securisation']),
      dateLiberation: _asDate(json['date_liberation']),
      dateVersement: _asDate(json['date_versement']),
      dateRemboursement: _asDate(json['date_remboursement']),
      createdAt: _asDate(json['created_at']),
      preuves: json['preuves'] is List
          ? (json['preuves'] as List)
                .whereType<Map<String, dynamic>>()
                .map(PreuvePaiement.fromJson)
                .toList()
          : const [],
      litiges: json['litiges'] is List
          ? (json['litiges'] as List)
                .whereType<Map<String, dynamic>>()
                .map(Litige.fromJson)
                .toList()
          : const [],
    );
  }

  bool get estPayable => statut == 'EN_ATTENTE';

  bool get aUnLitigeOuvert => litiges.any((l) => l.estOuvert);

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
