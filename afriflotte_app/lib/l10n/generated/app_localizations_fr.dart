// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonRefresh => 'Rafraîchir';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonRequiredField => 'Champ requis';

  @override
  String get commonSend => 'Envoyer';

  @override
  String get commonUnexpectedError => 'Erreur inattendue';

  @override
  String get langSwitchLabel => 'Langue';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get splashTagline => 'La plateforme du transport africain';

  @override
  String get authBrand => 'AfriFlotte';

  @override
  String get authWelcomeBackEyebrow => 'BON RETOUR';

  @override
  String get authLoginTitle => 'Se connecter';

  @override
  String get authLoginSubtitle =>
      'Entre tes identifiants pour accéder à ton espace.';

  @override
  String get authPhoneLabel => 'Téléphone';

  @override
  String get authPhoneRequired => 'Le téléphone est obligatoire';

  @override
  String get authPhoneInvalid => 'Numéro de téléphone invalide';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordRequired => 'Le mot de passe est obligatoire';

  @override
  String get authForgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get authLoginButton => 'Connexion';

  @override
  String get authNewHereEyebrow => 'NOUVEAU ICI';

  @override
  String get authSignupTitle => 'Créer un compte';

  @override
  String get authSignupSubtitle => 'Quelques infos et tu es prêt·e à démarrer.';

  @override
  String get authAccountTypeLabel => 'Je suis...';

  @override
  String get authAccountTypeTransporteur => 'Transporteur';

  @override
  String get authAccountTypeEntreprise => 'Entreprise';

  @override
  String get authCompanyNameLabel =>
      'Nom de l\'entreprise / société (optionnel)';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailLabelInscription => 'Email (optionnel)';

  @override
  String get authEmailHelper =>
      'Recommandé : sert à réinitialiser votre mot de passe en cas d\'oubli';

  @override
  String get authEmailRequired => 'L\'email est obligatoire';

  @override
  String get authEmailInvalid => 'Adresse email invalide';

  @override
  String get authPasswordMinLength => 'Au moins 6 caractères';

  @override
  String get authConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get authPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get authSignupButton => 'Créer mon compte';

  @override
  String get authSwitchToSignupTitle => 'Pas encore de compte ?';

  @override
  String get authSwitchToSignupText =>
      'Crée un compte en quelques secondes et retrouve tout ce que tu avais laissé.';

  @override
  String get authSwitchToSignupButton => 'S\'inscrire';

  @override
  String get authSwitchToLoginTitle => 'Déjà inscrit·e ?';

  @override
  String get authSwitchToLoginText =>
      'Connecte-toi pour retrouver ton compte et continuer où tu t\'étais arrêté·e.';

  @override
  String get authSwitchToLoginButton => 'Se connecter';

  @override
  String get authUserNotFound => 'Utilisateur introuvable';

  @override
  String get authIncorrectCredentials => 'Téléphone ou mot de passe incorrect';

  @override
  String get authSignupFailedGeneric => 'Impossible de créer le compte.';

  @override
  String get authAccountCreatedPleaseLogin =>
      'Compte créé. Connectez-vous pour continuer.';

  @override
  String get forgotStep1Of2 => 'ÉTAPE 1/2';

  @override
  String get forgotStep2Of2 => 'ÉTAPE 2/2';

  @override
  String get forgotTitle => 'Mot de passe oublié';

  @override
  String get forgotSubtitle =>
      'Entrez l\'adresse email associée à votre compte : nous vous enverrons un code de réinitialisation.';

  @override
  String get forgotSendCodeButton => 'Envoyer le code';

  @override
  String get forgotVerificationTitle => 'Vérification';

  @override
  String get forgotVerificationSubtitle =>
      'Saisissez le code reçu par email et choisissez un nouveau mot de passe.';

  @override
  String get forgotCodeLabel => 'Code à 6 chiffres';

  @override
  String get forgotCodeInvalid => 'Le code doit contenir 6 chiffres';

  @override
  String get forgotResendCode => 'Renvoyer le code';

  @override
  String get forgotResendCodeInProgress => 'Envoi...';

  @override
  String get forgotNewCodeGenerated => 'Nouveau code envoyé par email.';

  @override
  String get forgotNewPasswordLabel => 'Nouveau mot de passe';

  @override
  String get forgotNewPasswordRequired => 'Le nouveau mot de passe est requis';

  @override
  String get forgotResetButton => 'Réinitialiser le mot de passe';

  @override
  String get forgotSuccessTitle => 'Mot de passe mis à jour';

  @override
  String get forgotSuccessSubtitle =>
      'Vous pouvez désormais vous connecter avec votre nouveau mot de passe.';

  @override
  String get forgotBackToLogin => 'Retour à la connexion';

  @override
  String get avatarTakePhoto => 'Prendre une photo';

  @override
  String get avatarChooseFromGallery => 'Choisir depuis la galerie';

  @override
  String get navHome => 'Accueil';

  @override
  String get navCamions => 'Camions';

  @override
  String get navChauffeurs => 'Chauffeurs';

  @override
  String get navMissions => 'Missions';

  @override
  String get navGps => 'GPS';

  @override
  String get navProfil => 'Profil';

  @override
  String get navDemande => 'Demande';

  @override
  String get navHistorique => 'Mes demandes';

  @override
  String get dashTTitle => 'Tableau de bord';

  @override
  String dashTGreeting(String nom) {
    return 'Bonjour, $nom';
  }

  @override
  String get dashTTodaySummary =>
      'Voici l\'état de votre activité aujourd\'hui';

  @override
  String get dashTFleetSection => 'Votre flotte';

  @override
  String get dashTCamions => 'Camions';

  @override
  String get dashTAvailable => 'Disponibles';

  @override
  String get dashTChauffeurs => 'Chauffeurs';

  @override
  String get dashTPropositions => 'Propositions';

  @override
  String get dashTTotalRevenue => 'Revenus totaux';

  @override
  String dashTRevenueThisMonth(String montant) {
    return 'Ce mois-ci : $montant';
  }

  @override
  String get dashTAvailableRequests =>
      'Voir les demandes disponibles et proposer un camion';

  @override
  String get dashTMyPropositions => 'Suivre mes propositions envoyées';

  @override
  String get dashTMissionsSection => 'Missions';

  @override
  String get dashTPlanifiees => 'Planifiées';

  @override
  String get dashTEnCours => 'En cours';

  @override
  String get dashTTerminees => 'Terminées';

  @override
  String get dashTAnnulees => 'Annulées';

  @override
  String get camionsTitle => 'Mes camions';

  @override
  String get camionsErrorLoad => 'Aucun camion enregistré';

  @override
  String get camionsEmptyTitle => 'Aucun camion enregistré';

  @override
  String get camionsEmptySubtitle =>
      'Ajoutez votre premier camion avec le bouton +';

  @override
  String get camionsAvailable => 'Disponible';

  @override
  String get camionsUnavailable => 'Indisponible';

  @override
  String get camionsEditInfo => 'Modifier les informations';

  @override
  String get camionsManagePhotos => 'Gérer les photos';

  @override
  String get typeCamionCiterne => 'Camion citerne';

  @override
  String get typeCamionBenne => 'Camion benne';

  @override
  String get typeCamionPlateau => 'Camion plateau';

  @override
  String get typeCamionConteneur => 'Porte-conteneur';

  @override
  String get typeCamionPorteEngin => 'Porte-engin';

  @override
  String get formatCamionLabel => 'Format';

  @override
  String get formatCamion20Pieds => '20 pieds';

  @override
  String get formatCamion40Pieds => '40 pieds';

  @override
  String get formatCamion2040Pieds => '20/40 pieds';

  @override
  String get formatCamion45Pieds => '45 pieds';

  @override
  String get formatCamionCiterne10000L => '10 000 L';

  @override
  String get formatCamionCiterne15000L => '15 000 L';

  @override
  String get formatCamionCiterne20000L => '20 000 L';

  @override
  String get formatCamionCiterne25000L => '25 000 L';

  @override
  String get formatCamionCiterne30000L => '30 000 L';

  @override
  String get formatCamionCiterne35000L => '35 000 L';

  @override
  String get formatCamionCiterne40000L => '40 000 L';

  @override
  String get formatCamionCiterne43000L => '43 000 L';

  @override
  String get formatCamionCiterne45000L => '45 000 L';

  @override
  String get formatCamionCiterne50000L => '50 000 L';

  @override
  String get formatCamionBenne4x2 => '4×2 — 6 roues';

  @override
  String get formatCamionBenne6x4 => '6×4 — 10 roues';

  @override
  String get formatCamionBenne8x4 => '8×4 — 12 roues';

  @override
  String get formatCamionAutre => 'Autre';

  @override
  String get formatCamionAutrePrecision => 'Précisez le format';

  @override
  String get essieuxLabel => 'Nombre d\'essieux';

  @override
  String get addCamionTitle => 'Ajouter un camion';

  @override
  String get addCamionType => 'Type de camion';

  @override
  String get addCamionRegistration => 'Immatriculation';

  @override
  String get addCamionRegistrationRequired =>
      'L\'immatriculation est obligatoire';

  @override
  String get addCamionMarque => 'Marque';

  @override
  String get addCamionModele => 'Modèle';

  @override
  String get addCamionCapacity => 'Capacité';

  @override
  String get addCamionCapacityHint => 'Ex: 43500';

  @override
  String get addCamionCapacityRequired => 'La capacité est obligatoire';

  @override
  String get addCamionVille => 'Ville';

  @override
  String get addCamionVilleHint => 'Bamako';

  @override
  String get addCamionPays => 'Pays';

  @override
  String get addCamionPhotosLabel => 'Photos (optionnel, max 4)';

  @override
  String get addCamionChoosePhotos => 'Choisir des photos';

  @override
  String get addCamionSave => 'Enregistrer';

  @override
  String get addCamionSuccess => 'Camion enregistré avec succès';

  @override
  String get editCamionTitle => 'Modifier le camion';

  @override
  String get editCamionSuccess => 'Camion modifié avec succès';

  @override
  String photosCamionTitle(String immatriculation) {
    return 'Photos — $immatriculation';
  }

  @override
  String get photosCamionEmpty => 'Aucune photo pour ce camion.';

  @override
  String get photosCamionMax => 'Maximum 4 photos par camion.';

  @override
  String get photosCamionPrincipale => 'Principale';

  @override
  String get photosCamionDeleteTitle => 'Supprimer cette photo ?';

  @override
  String get photosCamionDeleteBody => 'Cette action est définitive.';

  @override
  String get chauffeursTitle => 'Mes chauffeurs';

  @override
  String get chauffeursEmpty => 'Aucun chauffeur enregistré';

  @override
  String get chauffeursActive => 'Actif';

  @override
  String get chauffeursInactive => 'Inactif';

  @override
  String get chauffeursNoCamion => 'Aucun camion assigné';

  @override
  String get chauffeursRelease => 'Libérer';

  @override
  String get chauffeursAssignCamion => 'Assigner un camion';

  @override
  String chauffeursReleasedSuccess(String nom) {
    return '$nom : camion libéré';
  }

  @override
  String get chauffeursNoActiveAssignment =>
      'Aucune affectation active pour ce chauffeur';

  @override
  String get addChauffeurTitle => 'Ajouter un chauffeur';

  @override
  String get addChauffeurPhotoOptional => 'Photo (optionnel)';

  @override
  String get addChauffeurFullName => 'Nom complet';

  @override
  String get addChauffeurNameRequired => 'Le nom est obligatoire';

  @override
  String get addChauffeurPays => 'Pays';

  @override
  String get addChauffeurPhone => 'Téléphone';

  @override
  String get addChauffeurPhoneHelper => 'Numéro local, sans l\'indicatif';

  @override
  String get addChauffeurPhoneRequired => 'Le téléphone est obligatoire';

  @override
  String get addChauffeurPermisNumber => 'Numéro de permis';

  @override
  String get addChauffeurPermisRequired =>
      'Le numéro de permis est obligatoire';

  @override
  String get addChauffeurPermisExpiration => 'Expiration du permis (optionnel)';

  @override
  String get addChauffeurPermisNotSet => 'Non renseignée';

  @override
  String get addChauffeurAccessCode => 'Code d\'accès (connexion chauffeur)';

  @override
  String get addChauffeurAccessCodeHelper =>
      'Sert au chauffeur pour se connecter à l\'app avec son téléphone';

  @override
  String get addChauffeurSave => 'Enregistrer';

  @override
  String get addChauffeurSuccess => 'Chauffeur enregistré avec succès';

  @override
  String assignCamionTitle(String nom) {
    return 'Camion pour $nom';
  }

  @override
  String get assignCamionEmpty =>
      'Aucun camion enregistré. Ajoutez-en un d\'abord.';

  @override
  String get assignCamionButton => 'Assigner ce camion';

  @override
  String get missionsTitle => 'Mes missions';

  @override
  String get missionsEmpty => 'Aucune mission pour le moment.';

  @override
  String get missionsStarted => 'Mission démarrée';

  @override
  String get missionsFinished => 'Mission terminée';

  @override
  String get missionsCancelled => 'Mission annulée';

  @override
  String get missionsCancel => 'Annuler';

  @override
  String get missionsStart => 'Démarrer';

  @override
  String get missionsFinish => 'Terminer';

  @override
  String get demandesTitle => 'Demandes disponibles';

  @override
  String get demandesTotal => 'Total';

  @override
  String get demandesOuvertes => 'Ouvertes';

  @override
  String get demandesEnCours => 'En cours';

  @override
  String get demandesFilterAll => 'TOUS';

  @override
  String get demandesSearchHint => 'Rechercher (départ, destination, produit)';

  @override
  String get demandesLoadError => 'Impossible de charger les demandes.';

  @override
  String get demandesNoneFound => 'Aucune demande trouvée.';

  @override
  String get demandesStatusOuverte => 'Ouverte';

  @override
  String get demandesStatusEnCours => 'En cours';

  @override
  String get demandesStatusTerminee => 'Terminée';

  @override
  String get demandesStatusAnnulee => 'Annulée';

  @override
  String demandesCamionCount(int count) {
    return '$count camion(s)';
  }

  @override
  String get demandesProposeButton => 'Proposer';

  @override
  String get propositionTitle => 'Envoyer une proposition';

  @override
  String get propositionPriceRequired => 'Indiquez un prix valide.';

  @override
  String get propositionCamionRequired => 'Choisissez au moins un camion.';

  @override
  String propositionCamionCountMismatch(int requis, int actuel) {
    return 'Cette demande requiert $requis camion(s) : votre proposition doit tous les inclure ($actuel pour l\'instant).';
  }

  @override
  String get propositionSentSuccess => 'Proposition envoyée avec succès';

  @override
  String get propositionAlreadySent =>
      'Vous avez déjà une proposition en attente pour cette demande.';

  @override
  String get propositionNeedCamionFirst =>
      'Ajoutez d\'abord un camion pour pouvoir proposer.';

  @override
  String propositionNoMatchingCamionType(String type) {
    return 'Cette demande nécessite un camion de type $type, et vous n\'en avez aucun de ce type. Ajoutez-en un pour pouvoir proposer.';
  }

  @override
  String get propositionCamionsLabel => 'Camion(s) proposé(s)';

  @override
  String get propositionAddCamion => 'Ajouter un camion';

  @override
  String propositionPriceLabel(String devise) {
    return 'Prix proposé ($devise)';
  }

  @override
  String get propositionDepartureDate => 'Date de départ prévue (optionnel)';

  @override
  String get propositionDepartureDateNotSet => 'Non précisé';

  @override
  String get propositionMessageLabel => 'Message (optionnel)';

  @override
  String get propositionSendButton => 'Envoyer la proposition';

  @override
  String get propositionCamionFieldLabel => 'Camion';

  @override
  String get propositionChauffeurFieldLabel => 'Chauffeur (optionnel)';

  @override
  String get propositionChauffeurNotSet => 'Non précisé';

  @override
  String get propositionChauffeurEnMission => 'en mission';

  @override
  String get fraicheurTresFiable => 'Position très fiable';

  @override
  String get fraicheurFiable => 'Position fiable';

  @override
  String get fraicheurAVerifier => 'Position à vérifier';

  @override
  String get fraicheurAncienne => 'Position ancienne';

  @override
  String get fraicheurInconnue => 'Position inconnue';

  @override
  String get gpsFleetTitle => 'Ma flotte';

  @override
  String get gpsFleetSubtitle =>
      'Localisation de vos camions et chauffeurs en temps réel';

  @override
  String get gpsNoChauffeurAssigned => 'Aucun chauffeur assigné';

  @override
  String get gpsNoPositionReported =>
      'Aucune position rapportée pour l\'instant';

  @override
  String get gpsJustNow => 'à l\'instant';

  @override
  String gpsAgoMinutes(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String gpsAgoHoursMinutes(int heures, String minutes) {
    return 'il y a ${heures}h$minutes';
  }

  @override
  String gpsAgoDays(int jours) {
    return 'il y a $jours j';
  }

  @override
  String get gpsTitle => 'Suivi GPS';

  @override
  String get gpsEmptyTitle =>
      'Aucun camion enregistré. Ajoutez-en un pour suivre sa position ici.';

  @override
  String gpsHistoryTitle(String immatriculation) {
    return 'Historique · $immatriculation';
  }

  @override
  String get gpsHistoryEmptyTitle => 'Aucune position enregistrée';

  @override
  String get gpsHistoryEmptySubtitle =>
      'Démarrez le suivi GPS pour commencer à enregistrer le trajet.';

  @override
  String gpsSpeedUnit(String vitesse) {
    return '$vitesse km/h';
  }

  @override
  String gpsMapTitle(String immatriculation) {
    return 'Suivi · $immatriculation';
  }

  @override
  String get gpsMapNoPositionTitle => 'Aucune position disponible';

  @override
  String get gpsMapNoPositionSubtitle =>
      'Ce camion n\'a encore transmis aucune position GPS.';

  @override
  String get gpsMapFollowing => 'Suivi en direct';

  @override
  String get gpsMapPaused => 'Suivi en pause';

  @override
  String get gpsMapRecenter => 'Recentrer';

  @override
  String gpsMapSource(String source) {
    return 'Source : $source';
  }

  @override
  String get profilTTitle => 'Mon profil';

  @override
  String get profilTUsername => 'Nom d\'utilisateur';

  @override
  String get profilTCompany => 'Entreprise';

  @override
  String get profilTPhone => 'Téléphone';

  @override
  String get profilTEmail => 'Email';

  @override
  String get profilTAddress => 'Adresse';

  @override
  String get profilTCountry => 'Pays';

  @override
  String get profilTActionsSection => 'Actions';

  @override
  String get profilTEditProfile => 'Modifier mon profil';

  @override
  String get profilTEditProfileSubtitle =>
      'Mettre à jour vos informations personnelles';

  @override
  String get profilTSecurity => 'Sécurité du compte';

  @override
  String get profilTSecuritySubtitle => 'Mot de passe, sessions et accès';

  @override
  String get profilTLanguage => 'Langue';

  @override
  String get profilTLanguageSubtitle => 'Choisir la langue de l\'application';

  @override
  String get profilTLogout => 'Déconnexion';

  @override
  String get profilTLogoutSubtitle => 'Se déconnecter de cette session';

  @override
  String get profilTRoleTransporteur => 'Transporteur';

  @override
  String get profilTRoleEntreprise => 'Entreprise';

  @override
  String get profilTRoleAdmin => 'Administrateur';

  @override
  String get profilTRoleDefault => 'Compte';

  @override
  String get profilTNotSet => 'Non renseigné';

  @override
  String get modifierProfilTitle => 'Modifier mon profil';

  @override
  String modifierProfilLoginId(String telephone) {
    return '$telephone · identifiant de connexion';
  }

  @override
  String get modifierProfilInfoSection => 'Informations personnelles';

  @override
  String get modifierProfilCompanyName => 'Nom de l\'entreprise';

  @override
  String get modifierProfilCompanyNameHint => 'Ex: Transports Diallo';

  @override
  String get modifierProfilEmail => 'Email';

  @override
  String get modifierProfilEmailHint => 'exemple@mail.com';

  @override
  String get modifierProfilEmailInvalid => 'Adresse email invalide';

  @override
  String get modifierProfilAddress => 'Adresse';

  @override
  String get modifierProfilAddressHint => 'Quartier, ville';

  @override
  String get modifierProfilCountry => 'Pays';

  @override
  String get modifierProfilSaveButton => 'Enregistrer les modifications';

  @override
  String get modifierProfilSuccess => 'Profil mis à jour avec succès';

  @override
  String get securiteTitle => 'Sécurité du compte';

  @override
  String get securiteIntro =>
      'Choisissez un mot de passe robuste que vous n\'utilisez sur aucun autre service.';

  @override
  String get securiteChangePassword => 'Changer le mot de passe';

  @override
  String get securiteCurrentPassword => 'Mot de passe actuel';

  @override
  String get securiteCurrentPasswordRequired =>
      'Le mot de passe actuel est requis';

  @override
  String get securiteNewPassword => 'Nouveau mot de passe';

  @override
  String get securiteNewPasswordRequired =>
      'Le nouveau mot de passe est requis';

  @override
  String get securitePasswordMinLength => 'Au moins 6 caractères';

  @override
  String get securiteStrengthWeak => 'Faible';

  @override
  String get securiteStrengthMedium => 'Moyen';

  @override
  String get securiteStrengthStrong => 'Fort';

  @override
  String get securiteConfirmPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get securitePasswordMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get securiteUpdateButton => 'Mettre à jour le mot de passe';

  @override
  String get securiteSuccess => 'Mot de passe mis à jour avec succès';

  @override
  String clientHomeGreeting(String nom) {
    return 'Bonjour, $nom';
  }

  @override
  String get clientHomeSubtitle =>
      'Votre espace entreprise pour piloter vos transports, demandes et missions';

  @override
  String get clientHomeOpenRequests => 'Demandes ouvertes';

  @override
  String get clientHomeMissionsEnCours => 'Missions en cours';

  @override
  String get clientHomeMissionsTerminees => 'Missions terminées';

  @override
  String get clientHomePropositionsReceived => 'Propositions reçues';

  @override
  String get clientHomePropositionsSubtitle =>
      'Acceptez ou refusez les offres des transporteurs';

  @override
  String get clientHomeTotalExpenses => 'Dépenses totales';

  @override
  String clientHomeExpensesThisMonth(String montant) {
    return 'Ce mois-ci : $montant';
  }

  @override
  String get clientHomeNewRequestTitle => 'Nouvelle demande';

  @override
  String get clientHomeNewRequestSubtitle =>
      'Créer une nouvelle demande de transport';

  @override
  String get clientHomeMissionsTitle => 'Mes missions';

  @override
  String get clientHomeMissionsSubtitle =>
      'Suivre les transports confiés à un transporteur';

  @override
  String get clientHomeHistoryTitle => 'Mes demandes';

  @override
  String get clientHomeHistorySubtitle =>
      'Consulter toutes vos demandes de transport';

  @override
  String get clientHomeNearbyTitle => 'Camions à proximité';

  @override
  String get clientHomeNearbySubtitle =>
      'Trouver un camion disponible près de vous';

  @override
  String get clientHomeCompanySpaceTitle => 'Espace entreprise';

  @override
  String get clientHomeCompanySpaceSubtitle =>
      'Informations et actions rapides du compte';

  @override
  String get compteClientTitle => 'Compte entreprise';

  @override
  String get compteClientSubtitle =>
      'Gérez votre flotte et vos opérations logistiques en toute simplicité';

  @override
  String get compteClientActiveBadge => 'Entreprise active';

  @override
  String get compteClientQuickActions => 'Actions rapides';

  @override
  String get compteClientNewRequestTitle => 'Nouvelle demande';

  @override
  String get compteClientNewRequestSubtitle =>
      'Créer une nouvelle demande de transport';

  @override
  String get compteClientMissionsTitle => 'Mes missions';

  @override
  String get compteClientMissionsSubtitle => 'Suivre les transports en cours';

  @override
  String get compteClientHistoryTitle => 'Historique';

  @override
  String get compteClientHistorySubtitle =>
      'Consulter vos demandes précédentes';

  @override
  String get compteClientSecurityTitle => 'Sécurité';

  @override
  String get compteClientSecuritySubtitle =>
      'Mot de passe et sécurité du compte';

  @override
  String get compteClientAccountInfo => 'Informations du compte';

  @override
  String get compteClientName => 'Nom';

  @override
  String get compteClientPhone => 'Téléphone';

  @override
  String get compteClientAccountType => 'Type de compte';

  @override
  String get compteClientStatus => 'Statut';

  @override
  String get compteClientStatusValue => 'Premium / actif';

  @override
  String get compteClientNotSet => 'Non renseigné';

  @override
  String get profilClientTitle => 'Profil entreprise';

  @override
  String get profilClientVerifiedBadge => 'Compte entreprise vérifié';

  @override
  String get profilClientMainInfo => 'Informations principales';

  @override
  String get profilClientNom => 'Nom';

  @override
  String get profilClientType => 'Type';

  @override
  String get profilClientRole => 'Rôle';

  @override
  String get profilClientDefaultRole => 'Client entreprise';

  @override
  String get profilClientAdresseNotSet => 'Non renseignée';

  @override
  String get profilClientActivity => 'Activité';

  @override
  String get profilClientDemandes => 'Demandes';

  @override
  String get profilClientMissions => 'Missions';

  @override
  String get profilClientQuickActions => 'Actions rapides';

  @override
  String get profilClientEditProfile => 'Modifier le profil';

  @override
  String get profilClientEditProfileSubtitle =>
      'Mettre à jour les informations de votre entreprise';

  @override
  String get nouvelleDemandeTitle => 'Nouvelle demande transport';

  @override
  String get nouvelleDemandeVilleDepart => 'Ville de départ';

  @override
  String get nouvelleDemandePaysDepart => 'Pays de départ';

  @override
  String get nouvelleDemandeVilleArrivee => 'Ville d\'arrivée';

  @override
  String get nouvelleDemandePaysArrivee => 'Pays d\'arrivée';

  @override
  String get nouvelleDemandeTypeCamion => 'Type de camion';

  @override
  String get nouvelleDemandeQuantite => 'Quantité';

  @override
  String get nouvelleDemandeQuantiteInvalid => 'Quantité invalide';

  @override
  String get nouvelleDemandeUnite => 'Unité';

  @override
  String get nouvelleDemandeUniteLitres => 'Litres';

  @override
  String get nouvelleDemandeUniteTonnes => 'Tonnes';

  @override
  String get nouvelleDemandeUniteKg => 'Kg';

  @override
  String get nouvelleDemandeDateChargement => 'Date de chargement';

  @override
  String get nouvelleDemandePrixPropose => 'Prix proposé (optionnel)';

  @override
  String get nouvelleDemandePrixInvalid => 'Prix invalide';

  @override
  String get nouvelleDemandeDescription => 'Marchandise à transporter';

  @override
  String get nouvelleDemandeDescriptionHint =>
      'Ex: 20 tonnes de ciment en sacs';

  @override
  String get nouvelleDemandeDescriptionRequired =>
      'La marchandise à transporter est obligatoire';

  @override
  String get nouvelleDemandeDescriptionTooShort =>
      'Précisez la marchandise (au moins 3 caractères)';

  @override
  String get nouvelleDemandeNombreCamions => 'Nombre de camions :';

  @override
  String get nouvelleDemandeSubmitting => 'Envoi en cours...';

  @override
  String get nouvelleDemandeSubmitButton => 'Créer la demande';

  @override
  String get nouvelleDemandeSuccess =>
      'Demande de transport créée avec succès.';

  @override
  String get nouvelleDemandeEditTitle => 'Modifier la demande';

  @override
  String get nouvelleDemandeUpdateButton => 'Enregistrer les modifications';

  @override
  String get nouvelleDemandeUpdateSuccess => 'Demande modifiée avec succès.';

  @override
  String nouvelleDemandeGenericError(String erreur) {
    return 'Erreur : $erreur';
  }

  @override
  String get missionsClientTitle => 'Mes missions';

  @override
  String get missionsClientFilterAll => 'Toutes';

  @override
  String get missionsClientFilterPlanifiee => 'Planifiées';

  @override
  String get missionsClientFilterEnCours => 'En cours';

  @override
  String get missionsClientFilterTerminee => 'Terminées';

  @override
  String get missionsClientEmptyFiltered => 'Aucune mission dans ce statut';

  @override
  String get missionsClientEmptyNone => 'Aucune mission pour le moment';

  @override
  String get missionsClientChangeFilter =>
      'Changez de filtre pour voir vos autres missions.';

  @override
  String get missionsClientEmptyHint =>
      'Vos missions apparaîtront ici dès qu\'un transporteur aura accepté une de vos demandes.';

  @override
  String get missionsClientPaysLabel => 'Pays';

  @override
  String get missionsClientTransporteurLabel => 'Transporteur';

  @override
  String get missionsClientMarchandiseLabel => 'Marchandise';

  @override
  String get missionsClientCamionsLabel => 'Camions';

  @override
  String missionsClientCamionsValue(int count, String type) {
    return '$count camion(s) · $type';
  }

  @override
  String get missionsClientChargementLabel => 'Chargement';

  @override
  String get missionsClientPrixLabel => 'Prix final';

  @override
  String get missionsClientPrixNonConfirme => 'Prix à confirmer';

  @override
  String get missionsClientDepart => 'Départ';

  @override
  String get missionsClientArrivee => 'Arrivée';

  @override
  String get propositionsRecuesTitle => 'Propositions reçues';

  @override
  String get propositionsRecuesFilterAll => 'Toutes';

  @override
  String get propositionsRecuesFilterEnAttente => 'En attente';

  @override
  String get propositionsRecuesFilterAcceptee => 'Acceptées';

  @override
  String get propositionsRecuesFilterRefusee => 'Refusées';

  @override
  String get propositionsRecuesEmptyFiltered =>
      'Aucune proposition dans ce statut';

  @override
  String get propositionsRecuesEmptyNone =>
      'Aucune proposition reçue pour le moment';

  @override
  String get propositionsRecuesChangeFilter =>
      'Changez de filtre pour voir vos autres propositions.';

  @override
  String get propositionsRecuesEmptyHint =>
      'Les propositions envoyées par les transporteurs pour vos demandes apparaîtront ici.';

  @override
  String get propositionsRecuesTransporteurLabel => 'Transporteur';

  @override
  String get propositionsRecuesPrixLabel => 'Prix proposé';

  @override
  String get propositionsRecuesCamionsLabel => 'Camions';

  @override
  String propositionsRecuesCamionsValue(int count, String type) {
    return '$count camion(s) · $type';
  }

  @override
  String get propositionsRecuesMessageLabel => 'Message du transporteur';

  @override
  String get propositionsRecuesAccepterButton => 'Accepter';

  @override
  String get propositionsRecuesRefuserButton => 'Refuser';

  @override
  String get propositionsRecuesConfirmerAccepterTitle =>
      'Accepter cette proposition ?';

  @override
  String get propositionsRecuesConfirmerAccepterMessage =>
      'Une mission sera créée avec ce transporteur, et les autres propositions reçues pour cette demande seront automatiquement refusées.';

  @override
  String get propositionsRecuesConfirmerRefuserTitle =>
      'Refuser cette proposition ?';

  @override
  String get propositionsRecuesConfirmerRefuserMessage =>
      'Le transporteur sera notifié que sa proposition n\'a pas été retenue.';

  @override
  String get propositionsRecuesAccepteeSuccess =>
      'Proposition acceptée : la mission a été créée.';

  @override
  String get propositionsRecuesRefuseeSuccess => 'Proposition refusée.';

  @override
  String get propositionsRecuesHighlightNotFound =>
      'Cette proposition n\'est plus disponible.';

  @override
  String get mesPropositionsTitle => 'Mes propositions';

  @override
  String get mesPropositionsEmptyNone =>
      'Aucune proposition envoyée pour le moment';

  @override
  String get mesPropositionsEmptyHint =>
      'Les propositions que vous envoyez (manuellement ou via le matching automatique) apparaîtront ici.';

  @override
  String get historiqueClientTitle => 'Mes demandes';

  @override
  String get historiqueClientFilterAll => 'Toutes';

  @override
  String get historiqueClientFilterOuverte => 'Ouvertes';

  @override
  String get historiqueClientFilterEnCours => 'En cours';

  @override
  String get historiqueClientFilterTerminee => 'Terminées';

  @override
  String get historiqueClientEmptyFiltered => 'Aucune demande dans ce statut';

  @override
  String get historiqueClientEmptyNone => 'Aucune demande enregistrée';

  @override
  String get historiqueClientChangeFilter =>
      'Changez de filtre pour voir vos autres demandes.';

  @override
  String get historiqueClientEmptyHint =>
      'Créez une demande de transport depuis l\'onglet « Demande » : elle apparaîtra ici.';

  @override
  String historiqueClientCreeeLabel(String date) {
    return 'Créée le $date';
  }

  @override
  String historiqueClientCamionsValue(int count) {
    return '$count camion(s)';
  }

  @override
  String get historiqueClientQuantiteNonPrecisee => 'Quantité non précisée';

  @override
  String historiqueClientChargementLabel(String date) {
    return 'Chargement $date';
  }

  @override
  String get historiqueClientModifier => 'Modifier';

  @override
  String get historiqueClientSupprimer => 'Supprimer';

  @override
  String get historiqueClientSupprimerConfirmTitle =>
      'Supprimer cette demande ?';

  @override
  String get historiqueClientSupprimerConfirmMessage =>
      'Cette demande sera annulée et retirée du marché. Cette action est irréversible.';

  @override
  String get historiqueClientSupprimerSuccess => 'Demande supprimée.';

  @override
  String get rechercheCamionTitle => 'Camions à proximité';

  @override
  String get rechercheCamionTypeLabel => 'Type de camion';

  @override
  String get rechercheCamionCapaciteMin => 'Capacité minimale (optionnel)';

  @override
  String rechercheCamionPositionDefined(String latitude, String longitude) {
    return 'Position : $latitude, $longitude';
  }

  @override
  String get rechercheCamionPositionUndefined =>
      'Position non définie — le tri se fera sur la fraîcheur GPS uniquement.';

  @override
  String get rechercheCamionMyPosition => 'Ma position';

  @override
  String get rechercheCamionSearching => 'Recherche...';

  @override
  String get rechercheCamionSearchButton => 'Rechercher';

  @override
  String get rechercheCamionEnableLocation =>
      'Activez la localisation pour l\'utiliser ici.';

  @override
  String get rechercheCamionPermissionDenied =>
      'Permission de localisation refusée.';

  @override
  String get rechercheCamionChooseType =>
      'Choisissez un type de camion et lancez la recherche.';

  @override
  String get rechercheCamionNoneFound =>
      'Aucun camion disponible pour ces critères.';

  @override
  String get chauffeurDashTitle => 'Tableau de bord chauffeur';

  @override
  String chauffeurDashGreeting(String nom) {
    return 'Bonjour $nom';
  }

  @override
  String get chauffeurDashDefaultName => 'chauffeur';

  @override
  String get chauffeurDashReady => 'Votre espace de suivi est prêt.';

  @override
  String get chauffeurDashLocationActive => 'Localisation active';

  @override
  String get chauffeurDashLocationUnavailable => 'Localisation indisponible';

  @override
  String get chauffeurDashNoMissions =>
      'Aucune mission assignée pour le moment.';

  @override
  String get chauffeurDashMissionFallback => 'Mission';

  @override
  String get chauffeurDashNoDetails => 'Aucun détail disponible';

  @override
  String get chauffeurDashIdNotFound => 'Identifiant chauffeur introuvable';

  @override
  String get chauffeurDashLocationPermissionDenied =>
      'Localisation refusée : le camion ne sera pas visible dans les recherches clients.';

  @override
  String get chauffeurDashLocationOpenSettings => 'Ouvrir les réglages';

  @override
  String get chauffeurDashLocationRetry => 'Réessayer';

  @override
  String get chauffeurDashMissionsUpdatedByTransporteur =>
      'Le transporteur a mis à jour une ou plusieurs missions.';

  @override
  String get chauffeurMissionDetailTitle => 'Détail mission';

  @override
  String get chauffeurMissionDetailClient => 'Client';

  @override
  String get chauffeurMissionDetailPhone => 'Téléphone';

  @override
  String get chauffeurMissionDetailDescription => 'Description';

  @override
  String get chauffeurMissionDetailQuantite => 'Quantité';

  @override
  String get chauffeurMissionDetailPrix => 'Prix convenu';

  @override
  String get chauffeurMissionDetailDepart => 'Départ';

  @override
  String get chauffeurMissionDetailArrivee => 'Arrivée';

  @override
  String get chauffeurMissionDetailObservations => 'Observations';

  @override
  String get chauffeurMissionDetailNoObservations => 'Aucune observation.';

  @override
  String get chauffeurMissionDetailNotStarted => 'Pas encore démarrée';

  @override
  String get chauffeurMissionDetailNotArrived => 'Pas encore arrivée';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notifEmpty => 'Aucune notification pour le moment.';

  @override
  String get notifPropositionDeleted => 'Cette proposition n\'existe plus.';

  @override
  String get notifTimeJustNow => 'À l\'instant';

  @override
  String notifTimeMinutes(int n) {
    return 'Il y a $n min';
  }

  @override
  String notifTimeHours(int n) {
    return 'Il y a $n h';
  }

  @override
  String notifTimeDays(int n) {
    return 'Il y a $n j';
  }

  @override
  String get adminTitle => 'Administration AfriFlotte';

  @override
  String get adminDefaultName => 'Admin';

  @override
  String adminGreeting(String nom) {
    return 'Bienvenue, $nom';
  }

  @override
  String get adminOverview => 'Vue d\'ensemble de la plateforme AfriFlotte';

  @override
  String get adminAccountsSection => 'Comptes';

  @override
  String get adminTransporteurs => 'Transporteurs';

  @override
  String get adminEntreprises => 'Entreprises';

  @override
  String get adminChauffeurs => 'Chauffeurs';

  @override
  String get adminFleetSection => 'Flotte';

  @override
  String get adminCamions => 'Camions';

  @override
  String get adminAvailable => 'Disponibles';

  @override
  String get adminMissionsSection => 'Missions';

  @override
  String get adminTotal => 'Total';

  @override
  String get adminEnCours => 'En cours';

  @override
  String get adminTerminees => 'Terminées';

  @override
  String get adminMarketSection => 'Marché';

  @override
  String get adminOpenRequests => 'Demandes ouvertes';

  @override
  String get adminRevenue => 'Revenus';

  @override
  String get adminOtherCurrency => '+1 autre devise';

  @override
  String adminOtherCurrencies(int count) {
    return '+$count autres devises';
  }

  @override
  String get paiementTitle => 'Paiement';

  @override
  String get paiementChooseModeTitle => 'Comment souhaitez-vous payer ?';

  @override
  String get paiementModeCarte => 'Carte bancaire';

  @override
  String get paiementModeCarteDesc => 'Paiement en ligne sécurisé';

  @override
  String get paiementModeManuel => 'Espèces (main à main)';

  @override
  String get paiementModeManuelDesc =>
      'Un agent AfriFlotte viendra encaisser le paiement';

  @override
  String get paiementMontantTotal => 'Montant total';

  @override
  String paiementCommission(String taux) {
    return 'Commission AfriFlotte ($taux%)';
  }

  @override
  String get paiementNetTransporteur => 'Versé au transporteur';

  @override
  String get paiementValider => 'Valider';

  @override
  String get paiementEnAttenteConfirmation =>
      'En attente de confirmation du paiement…';

  @override
  String get paiementVerifierStatut => 'Vérifier le statut';

  @override
  String get paiementSucces => 'Paiement sécurisé avec succès.';

  @override
  String get paiementEchecTitre => 'Le paiement a échoué';

  @override
  String get paiementReessayer => 'Réessayer';

  @override
  String get paiementBouton => 'Payer';

  @override
  String get paiementCarteMontantAPayer => 'Montant à payer';

  @override
  String get paiementCarteNumeroLabel => 'Numéro de carte';

  @override
  String get paiementCarteExpirationLabel => 'MM/AA';

  @override
  String get paiementCarteCvvLabel => 'CVV';

  @override
  String get paiementCarteSecuriteNote =>
      'Paiement sécurisé. Votre numéro de carte et votre CVV ne sont jamais enregistrés.';

  @override
  String get paiementCarteTraitementEnCours => 'Traitement du paiement…';

  @override
  String get paiementMobileOperateurLabel => 'Opérateur Mobile Money';

  @override
  String get paiementMobileNumeroLabel => 'Numéro Mobile Money';

  @override
  String get paiementMobileNote =>
      'Vous recevrez une demande de confirmation du paiement sur ce numéro.';

  @override
  String get paiementAnnuleParClient => 'Paiement annulé';

  @override
  String get paiementVerificationDelaiDepasse =>
      'Le paiement met plus de temps que prévu à se confirmer. Vérifiez plus tard dans \"Mes paiements\".';

  @override
  String get paiementHistoriqueTitle => 'Mes paiements';

  @override
  String get paiementHistoriqueSubtitle =>
      'Suivez vos paiements et leur statut';

  @override
  String get paiementHistoriqueEmpty => 'Aucun paiement pour l\'instant';

  @override
  String get paiementDetailTitle => 'Détail du paiement';

  @override
  String get paiementOuvrirLitige => 'Signaler un problème';

  @override
  String get paiementMotifLitige => 'Décrivez le problème';

  @override
  String get paiementEnvoyer => 'Envoyer';

  @override
  String get paiementLitigeEnvoye =>
      'Litige envoyé, un administrateur va l\'examiner.';

  @override
  String paiementSource(String reference) {
    return 'Référence : $reference';
  }

  @override
  String get tableColonneNom => 'Nom';

  @override
  String get tableColonneTelephone => 'Téléphone';

  @override
  String get tableColonnePays => 'Pays';

  @override
  String get tableColonneTransporteur => 'Transporteur';

  @override
  String get tableColonneStatut => 'Statut';

  @override
  String get tableColonneImmatriculation => 'Immatriculation';

  @override
  String get tableColonneType => 'Type';

  @override
  String get tableColonneVille => 'Ville';

  @override
  String get tableColonneVehicule => 'Véhicule';

  @override
  String get tableColonneTrajet => 'Trajet';

  @override
  String get tableColonneClient => 'Client';

  @override
  String get tableColonneMontant => 'Montant';

  @override
  String get tableColonneProduit => 'Marchandise';

  @override
  String get tableColonneAction => 'Action';

  @override
  String get tableColonneCapacite => 'Capacité';

  @override
  String get agentAccueilTitle => 'Encaissements à collecter';

  @override
  String get agentAucunPaiement => 'Aucun encaissement en attente';

  @override
  String get agentEncaisserButton => 'Encaisser';

  @override
  String get agentReferenceLabel => 'Référence / numéro de reçu';

  @override
  String get agentAjouterPreuve => 'Ajouter une preuve (photo)';

  @override
  String get agentPreuveAjoutee => 'Photo ajoutée';

  @override
  String get agentEncaissementConfirme =>
      'Encaissement enregistré, en attente de validation admin.';

  @override
  String get paiementMobileConfirme => 'Paiement Mobile Money confirmé.';

  @override
  String get adminPaiementsTitle => 'Paiements à traiter';

  @override
  String get adminPaiementsEmpty => 'Rien à traiter pour l\'instant';

  @override
  String get adminValiderButton => 'Valider';

  @override
  String get adminVerserButton => 'Marquer comme versé';

  @override
  String get adminRembourserButton => 'Rembourser';

  @override
  String get adminLitigesTitle => 'Litiges';

  @override
  String get adminLitigesEmpty => 'Aucun litige en cours';

  @override
  String get adminResoudreButton => 'Résoudre';

  @override
  String get adminResolutionClient => 'En faveur du client (rembourser)';

  @override
  String get adminResolutionTransporteur =>
      'En faveur du transporteur (libérer)';

  @override
  String get adminResolutionRejete => 'Rejeter le litige';

  @override
  String get adminCommentaireLabel => 'Commentaire';

  @override
  String get adminMotifLabel => 'Motif';

  @override
  String get adminSearchHint => 'Rechercher…';

  @override
  String get adminNoResults => 'Aucun résultat';

  @override
  String get adminUtilisateursTitleTransporteurs => 'Transporteurs';

  @override
  String get adminUtilisateursTitleEntreprises => 'Entreprises';

  @override
  String get adminUtilisateursEmpty => 'Aucun compte pour l\'instant';

  @override
  String get adminChauffeursTitle => 'Chauffeurs';

  @override
  String get adminChauffeursEmpty => 'Aucun chauffeur pour l\'instant';

  @override
  String get adminCamionsTitle => 'Camions';

  @override
  String get adminCamionsFilterAll => 'Tous';

  @override
  String get adminCamionsFilterDispo => 'Disponibles';

  @override
  String get adminCamionsEmpty => 'Aucun camion pour l\'instant';

  @override
  String get adminMissionsTitle => 'Missions';

  @override
  String get adminMissionsEmpty => 'Aucune mission pour l\'instant';

  @override
  String get adminDemandesTitle => 'Demandes';

  @override
  String get adminDemandesFilterOuverte => 'Ouvertes';

  @override
  String get adminDemandesEmpty => 'Aucune demande pour l\'instant';

  @override
  String get missionsClientFilterAnnulee => 'Annulées';

  @override
  String get contratChargementErreur => 'Impossible de charger ce contrat.';

  @override
  String contratVersionLabel(String date) {
    return 'Version du $date';
  }

  @override
  String get contratTelechargerPdf => 'Télécharger en PDF';

  @override
  String get contratPaiementTitre => 'Conditions de paiement';

  @override
  String get contratPaiementLien => 'Consulter les conditions de paiement';

  @override
  String get contratTransporteurTitre => 'Contrat de partenariat transporteur';

  @override
  String get contratTransporteurLireLien =>
      'Lire le contrat de partenariat transporteur';

  @override
  String get contratTransporteurLegal => 'Contrat transporteur';

  @override
  String get contratTransporteurLegalSousTitre =>
      'Lire, télécharger ou consulter la date d\'acceptation';

  @override
  String contratAccepteLe(String date) {
    return 'Accepté le $date';
  }

  @override
  String get authAccepteContratPrefixe => 'J\'ai lu et j\'accepte le ';

  @override
  String get authAccepteContratLien => 'contrat de partenariat transporteur';

  @override
  String get authAccepteContratRequis =>
      'Vous devez accepter le contrat pour créer un compte transporteur';

  @override
  String get contratGateTitre => 'Avant de continuer';

  @override
  String get contratGateSousTitre =>
      'Ce contrat encadre votre partenariat avec AfriFlotte : merci de le lire avant de continuer.';

  @override
  String get contratGateCheckbox => 'J\'ai lu et j\'accepte ce contrat';

  @override
  String get contratGateAccepter => 'Accepter et continuer';

  @override
  String get contratGateDeconnexion => 'Se déconnecter';
}
