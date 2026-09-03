import 'package:flutter/material.dart';

/// Palette de statut unique pour toute l'app : demandes, propositions et
/// missions partagent la même sémantique de couleur, quel que soit l'écran
/// ou le rôle (transporteur/entreprise) qui la consulte — ambre = en
/// attente/à venir, bleu = en cours, vert = terminé/accepté, rouge =
/// annulé/refusé. Avant ce fichier, chaque écran définissait sa propre
/// palette locale et elles avaient fini par diverger (ex. PLANIFIEE/
/// EN_COURS littéralement inversées entre l'écran missions du transporteur
/// et celui du client).
const Color statutCouleurAttente = Color(0xFFF59E0B);
const Color statutCouleurEnCours = Color(0xFF38BDF8);
const Color statutCouleurTermine = Color(0xFF34D399);
const Color statutCouleurAnnule = Color(0xFFEF4444);
const Color statutCouleurNeutre = Color(0xFF64748B);

/// Couleur associée à un statut (`DemandeTransport.statut`, `Proposition.
/// statut`, `Mission.statut` ou `MissionCamion.statut`) — insensible à la
/// casse, retombe sur [statutCouleurNeutre] pour toute valeur inconnue
/// plutôt que de planter.
Color couleurStatut(String statut) {
  switch (statut.toUpperCase()) {
    case 'OUVERTE':
    case 'EN_ATTENTE':
    case 'PLANIFIEE':
    case 'PREVU':
      return statutCouleurAttente;
    case 'EN_COURS':
    case 'AU_CHARGEMENT':
    case 'CHARGE':
    case 'EN_ROUTE':
    case 'ARRIVE':
      return statutCouleurEnCours;
    case 'TERMINEE':
    case 'ACCEPTEE':
    case 'LIVRE':
      return statutCouleurTermine;
    case 'ANNULEE':
    case 'ANNULE':
    case 'REFUSEE':
    case 'PANNE':
      return statutCouleurAnnule;
    default:
      return statutCouleurNeutre;
  }
}
