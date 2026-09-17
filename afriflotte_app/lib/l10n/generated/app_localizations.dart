import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// No description provided for @commonRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir'**
  String get commonRefresh;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @commonRequiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get commonRequiredField;

  /// No description provided for @commonSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get commonSend;

  /// No description provided for @commonUnexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur inattendue'**
  String get commonUnexpectedError;

  /// No description provided for @langSwitchLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get langSwitchLabel;

  /// No description provided for @langFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get langFrench;

  /// No description provided for @langEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @splashTagline.
  ///
  /// In fr, this message translates to:
  /// **'La plateforme du transport africain'**
  String get splashTagline;

  /// No description provided for @authBrand.
  ///
  /// In fr, this message translates to:
  /// **'AfriFlotte'**
  String get authBrand;

  /// No description provided for @authWelcomeBackEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'BON RETOUR'**
  String get authWelcomeBackEyebrow;

  /// No description provided for @authLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entre tes identifiants pour accéder à ton espace.'**
  String get authLoginSubtitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone est obligatoire'**
  String get authPhoneRequired;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide'**
  String get authPhoneInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est obligatoire'**
  String get authPasswordRequired;

  /// No description provided for @authForgotPasswordLink.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get authForgotPasswordLink;

  /// No description provided for @authLoginButton.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get authLoginButton;

  /// No description provided for @authNewHereEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU ICI'**
  String get authNewHereEyebrow;

  /// No description provided for @authSignupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authSignupTitle;

  /// No description provided for @authSignupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques infos et tu es prêt·e à démarrer.'**
  String get authSignupSubtitle;

  /// No description provided for @authAccountTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Je suis...'**
  String get authAccountTypeLabel;

  /// No description provided for @authAccountTypeTransporteur.
  ///
  /// In fr, this message translates to:
  /// **'Transporteur'**
  String get authAccountTypeTransporteur;

  /// No description provided for @authAccountTypeEntreprise.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get authAccountTypeEntreprise;

  /// No description provided for @authCompanyNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'entreprise / société (optionnel)'**
  String get authCompanyNameLabel;

  /// No description provided for @authEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHelper.
  ///
  /// In fr, this message translates to:
  /// **'Sert à réinitialiser votre mot de passe en cas d\'oubli'**
  String get authEmailHelper;

  /// No description provided for @authEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est obligatoire'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 6 caractères'**
  String get authPasswordMinLength;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get authPasswordMismatch;

  /// No description provided for @authSignupButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get authSignupButton;

  /// No description provided for @authSwitchToSignupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get authSwitchToSignupTitle;

  /// No description provided for @authSwitchToSignupText.
  ///
  /// In fr, this message translates to:
  /// **'Crée un compte en quelques secondes et retrouve tout ce que tu avais laissé.'**
  String get authSwitchToSignupText;

  /// No description provided for @authSwitchToSignupButton.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get authSwitchToSignupButton;

  /// No description provided for @authSwitchToLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déjà inscrit·e ?'**
  String get authSwitchToLoginTitle;

  /// No description provided for @authSwitchToLoginText.
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi pour retrouver ton compte et continuer où tu t\'étais arrêté·e.'**
  String get authSwitchToLoginText;

  /// No description provided for @authSwitchToLoginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSwitchToLoginButton;

  /// No description provided for @authUserNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur introuvable'**
  String get authUserNotFound;

  /// No description provided for @authIncorrectCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone ou mot de passe incorrect'**
  String get authIncorrectCredentials;

  /// No description provided for @authSignupFailedGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer le compte.'**
  String get authSignupFailedGeneric;

  /// No description provided for @authAccountCreatedPleaseLogin.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé. Connectez-vous pour continuer.'**
  String get authAccountCreatedPleaseLogin;

  /// No description provided for @forgotStep1Of2.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE 1/2'**
  String get forgotStep1Of2;

  /// No description provided for @forgotStep2Of2.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE 2/2'**
  String get forgotStep2Of2;

  /// No description provided for @forgotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le numéro associé à votre compte : nous vous enverrons un code de réinitialisation par email.'**
  String get forgotSubtitle;

  /// No description provided for @forgotSendCodeButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le code'**
  String get forgotSendCodeButton;

  /// No description provided for @forgotVerificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get forgotVerificationTitle;

  /// No description provided for @forgotVerificationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code reçu par email et choisissez un nouveau mot de passe.'**
  String get forgotVerificationSubtitle;

  /// No description provided for @forgotCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code à 6 chiffres'**
  String get forgotCodeLabel;

  /// No description provided for @forgotCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le code doit contenir 6 chiffres'**
  String get forgotCodeInvalid;

  /// No description provided for @forgotResendCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get forgotResendCode;

  /// No description provided for @forgotResendCodeInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Envoi...'**
  String get forgotResendCodeInProgress;

  /// No description provided for @forgotNewCodeGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code envoyé par email.'**
  String get forgotNewCodeGenerated;

  /// No description provided for @forgotNewPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get forgotNewPasswordLabel;

  /// No description provided for @forgotNewPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nouveau mot de passe est requis'**
  String get forgotNewPasswordRequired;

  /// No description provided for @forgotResetButton.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get forgotResetButton;

  /// No description provided for @forgotSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour'**
  String get forgotSuccessTitle;

  /// No description provided for @forgotSuccessSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez désormais vous connecter avec votre nouveau mot de passe.'**
  String get forgotSuccessSubtitle;

  /// No description provided for @forgotBackToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get forgotBackToLogin;

  /// No description provided for @avatarTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get avatarTakePhoto;

  /// No description provided for @avatarChooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir depuis la galerie'**
  String get avatarChooseFromGallery;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navCamions.
  ///
  /// In fr, this message translates to:
  /// **'Camions'**
  String get navCamions;

  /// No description provided for @navChauffeurs.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeurs'**
  String get navChauffeurs;

  /// No description provided for @navMissions.
  ///
  /// In fr, this message translates to:
  /// **'Missions'**
  String get navMissions;

  /// No description provided for @navGps.
  ///
  /// In fr, this message translates to:
  /// **'GPS'**
  String get navGps;

  /// No description provided for @navProfil.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfil;

  /// No description provided for @navDemande.
  ///
  /// In fr, this message translates to:
  /// **'Demande'**
  String get navDemande;

  /// No description provided for @navHistorique.
  ///
  /// In fr, this message translates to:
  /// **'Mes demandes'**
  String get navHistorique;

  /// No description provided for @dashTTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashTTitle;

  /// No description provided for @dashTGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {nom}'**
  String dashTGreeting(String nom);

  /// No description provided for @dashTTodaySummary.
  ///
  /// In fr, this message translates to:
  /// **'Voici l\'état de votre activité aujourd\'hui'**
  String get dashTTodaySummary;

  /// No description provided for @dashTFleetSection.
  ///
  /// In fr, this message translates to:
  /// **'Votre flotte'**
  String get dashTFleetSection;

  /// No description provided for @dashTCamions.
  ///
  /// In fr, this message translates to:
  /// **'Camions'**
  String get dashTCamions;

  /// No description provided for @dashTAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponibles'**
  String get dashTAvailable;

  /// No description provided for @dashTChauffeurs.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeurs'**
  String get dashTChauffeurs;

  /// No description provided for @dashTPropositions.
  ///
  /// In fr, this message translates to:
  /// **'Propositions'**
  String get dashTPropositions;

  /// No description provided for @dashTTotalRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus totaux'**
  String get dashTTotalRevenue;

  /// No description provided for @dashTRevenueThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois-ci : {montant}'**
  String dashTRevenueThisMonth(String montant);

  /// No description provided for @dashTAvailableRequests.
  ///
  /// In fr, this message translates to:
  /// **'Voir les demandes disponibles et proposer un camion'**
  String get dashTAvailableRequests;

  /// No description provided for @dashTMyPropositions.
  ///
  /// In fr, this message translates to:
  /// **'Suivre mes propositions envoyées'**
  String get dashTMyPropositions;

  /// No description provided for @dashTMissionsSection.
  ///
  /// In fr, this message translates to:
  /// **'Missions'**
  String get dashTMissionsSection;

  /// No description provided for @dashTPlanifiees.
  ///
  /// In fr, this message translates to:
  /// **'Planifiées'**
  String get dashTPlanifiees;

  /// No description provided for @dashTEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get dashTEnCours;

  /// No description provided for @dashTTerminees.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get dashTTerminees;

  /// No description provided for @dashTAnnulees.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get dashTAnnulees;

  /// No description provided for @camionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes camions'**
  String get camionsTitle;

  /// No description provided for @camionsErrorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Aucun camion enregistré'**
  String get camionsErrorLoad;

  /// No description provided for @camionsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun camion enregistré'**
  String get camionsEmptyTitle;

  /// No description provided for @camionsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre premier camion avec le bouton +'**
  String get camionsEmptySubtitle;

  /// No description provided for @camionsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get camionsAvailable;

  /// No description provided for @camionsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get camionsUnavailable;

  /// No description provided for @camionsEditInfo.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les informations'**
  String get camionsEditInfo;

  /// No description provided for @camionsManagePhotos.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les photos'**
  String get camionsManagePhotos;

  /// No description provided for @typeCamionCiterne.
  ///
  /// In fr, this message translates to:
  /// **'Camion citerne'**
  String get typeCamionCiterne;

  /// No description provided for @typeCamionBenne.
  ///
  /// In fr, this message translates to:
  /// **'Camion benne'**
  String get typeCamionBenne;

  /// No description provided for @typeCamionPlateau.
  ///
  /// In fr, this message translates to:
  /// **'Camion plateau'**
  String get typeCamionPlateau;

  /// No description provided for @typeCamionConteneur.
  ///
  /// In fr, this message translates to:
  /// **'Porte-conteneur'**
  String get typeCamionConteneur;

  /// No description provided for @typeCamionPorteEngin.
  ///
  /// In fr, this message translates to:
  /// **'Porte-engin'**
  String get typeCamionPorteEngin;

  /// No description provided for @formatCamionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get formatCamionLabel;

  /// No description provided for @formatCamion20Pieds.
  ///
  /// In fr, this message translates to:
  /// **'20 pieds'**
  String get formatCamion20Pieds;

  /// No description provided for @formatCamion40Pieds.
  ///
  /// In fr, this message translates to:
  /// **'40 pieds'**
  String get formatCamion40Pieds;

  /// No description provided for @formatCamion2040Pieds.
  ///
  /// In fr, this message translates to:
  /// **'20/40 pieds'**
  String get formatCamion2040Pieds;

  /// No description provided for @formatCamion45Pieds.
  ///
  /// In fr, this message translates to:
  /// **'45 pieds'**
  String get formatCamion45Pieds;

  /// No description provided for @formatCamionCiterne10000L.
  ///
  /// In fr, this message translates to:
  /// **'10 000 L'**
  String get formatCamionCiterne10000L;

  /// No description provided for @formatCamionCiterne15000L.
  ///
  /// In fr, this message translates to:
  /// **'15 000 L'**
  String get formatCamionCiterne15000L;

  /// No description provided for @formatCamionCiterne20000L.
  ///
  /// In fr, this message translates to:
  /// **'20 000 L'**
  String get formatCamionCiterne20000L;

  /// No description provided for @formatCamionCiterne25000L.
  ///
  /// In fr, this message translates to:
  /// **'25 000 L'**
  String get formatCamionCiterne25000L;

  /// No description provided for @formatCamionCiterne30000L.
  ///
  /// In fr, this message translates to:
  /// **'30 000 L'**
  String get formatCamionCiterne30000L;

  /// No description provided for @formatCamionCiterne35000L.
  ///
  /// In fr, this message translates to:
  /// **'35 000 L'**
  String get formatCamionCiterne35000L;

  /// No description provided for @formatCamionCiterne40000L.
  ///
  /// In fr, this message translates to:
  /// **'40 000 L'**
  String get formatCamionCiterne40000L;

  /// No description provided for @formatCamionCiterne43000L.
  ///
  /// In fr, this message translates to:
  /// **'43 000 L'**
  String get formatCamionCiterne43000L;

  /// No description provided for @formatCamionCiterne45000L.
  ///
  /// In fr, this message translates to:
  /// **'45 000 L'**
  String get formatCamionCiterne45000L;

  /// No description provided for @formatCamionCiterne50000L.
  ///
  /// In fr, this message translates to:
  /// **'50 000 L'**
  String get formatCamionCiterne50000L;

  /// No description provided for @formatCamionBenne4x2.
  ///
  /// In fr, this message translates to:
  /// **'4×2 — 6 roues'**
  String get formatCamionBenne4x2;

  /// No description provided for @formatCamionBenne6x4.
  ///
  /// In fr, this message translates to:
  /// **'6×4 — 10 roues'**
  String get formatCamionBenne6x4;

  /// No description provided for @formatCamionBenne8x4.
  ///
  /// In fr, this message translates to:
  /// **'8×4 — 12 roues'**
  String get formatCamionBenne8x4;

  /// No description provided for @formatCamionAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get formatCamionAutre;

  /// No description provided for @formatCamionAutrePrecision.
  ///
  /// In fr, this message translates to:
  /// **'Précisez le format'**
  String get formatCamionAutrePrecision;

  /// No description provided for @essieuxLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'essieux'**
  String get essieuxLabel;

  /// No description provided for @addCamionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un camion'**
  String get addCamionTitle;

  /// No description provided for @addCamionType.
  ///
  /// In fr, this message translates to:
  /// **'Type de camion'**
  String get addCamionType;

  /// No description provided for @addCamionRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Immatriculation'**
  String get addCamionRegistration;

  /// No description provided for @addCamionRegistrationRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'immatriculation est obligatoire'**
  String get addCamionRegistrationRequired;

  /// No description provided for @addCamionMarque.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get addCamionMarque;

  /// No description provided for @addCamionModele.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get addCamionModele;

  /// No description provided for @addCamionCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Capacité'**
  String get addCamionCapacity;

  /// No description provided for @addCamionCapacityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 43500'**
  String get addCamionCapacityHint;

  /// No description provided for @addCamionCapacityRequired.
  ///
  /// In fr, this message translates to:
  /// **'La capacité est obligatoire'**
  String get addCamionCapacityRequired;

  /// No description provided for @addCamionVille.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get addCamionVille;

  /// No description provided for @addCamionVilleHint.
  ///
  /// In fr, this message translates to:
  /// **'Bamako'**
  String get addCamionVilleHint;

  /// No description provided for @addCamionPays.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get addCamionPays;

  /// No description provided for @addCamionPhotosLabel.
  ///
  /// In fr, this message translates to:
  /// **'Photos (optionnel, max 4)'**
  String get addCamionPhotosLabel;

  /// No description provided for @addCamionChoosePhotos.
  ///
  /// In fr, this message translates to:
  /// **'Choisir des photos'**
  String get addCamionChoosePhotos;

  /// No description provided for @addCamionSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get addCamionSave;

  /// No description provided for @addCamionSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Camion enregistré avec succès'**
  String get addCamionSuccess;

  /// No description provided for @editCamionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le camion'**
  String get editCamionTitle;

  /// No description provided for @editCamionSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Camion modifié avec succès'**
  String get editCamionSuccess;

  /// No description provided for @photosCamionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Photos — {immatriculation}'**
  String photosCamionTitle(String immatriculation);

  /// No description provided for @photosCamionEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo pour ce camion.'**
  String get photosCamionEmpty;

  /// No description provided for @photosCamionMax.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 4 photos par camion.'**
  String get photosCamionMax;

  /// No description provided for @photosCamionPrincipale.
  ///
  /// In fr, this message translates to:
  /// **'Principale'**
  String get photosCamionPrincipale;

  /// No description provided for @photosCamionDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette photo ?'**
  String get photosCamionDeleteTitle;

  /// No description provided for @photosCamionDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive.'**
  String get photosCamionDeleteBody;

  /// No description provided for @chauffeursTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes chauffeurs'**
  String get chauffeursTitle;

  /// No description provided for @chauffeursEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chauffeur enregistré'**
  String get chauffeursEmpty;

  /// No description provided for @chauffeursActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get chauffeursActive;

  /// No description provided for @chauffeursInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get chauffeursInactive;

  /// No description provided for @chauffeursNoCamion.
  ///
  /// In fr, this message translates to:
  /// **'Aucun camion assigné'**
  String get chauffeursNoCamion;

  /// No description provided for @chauffeursRelease.
  ///
  /// In fr, this message translates to:
  /// **'Libérer'**
  String get chauffeursRelease;

  /// No description provided for @chauffeursAssignCamion.
  ///
  /// In fr, this message translates to:
  /// **'Assigner un camion'**
  String get chauffeursAssignCamion;

  /// No description provided for @chauffeursReleasedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'{nom} : camion libéré'**
  String chauffeursReleasedSuccess(String nom);

  /// No description provided for @chauffeursNoActiveAssignment.
  ///
  /// In fr, this message translates to:
  /// **'Aucune affectation active pour ce chauffeur'**
  String get chauffeursNoActiveAssignment;

  /// No description provided for @addChauffeurTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un chauffeur'**
  String get addChauffeurTitle;

  /// No description provided for @addChauffeurPhotoOptional.
  ///
  /// In fr, this message translates to:
  /// **'Photo (optionnel)'**
  String get addChauffeurPhotoOptional;

  /// No description provided for @addChauffeurFullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get addChauffeurFullName;

  /// No description provided for @addChauffeurNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire'**
  String get addChauffeurNameRequired;

  /// No description provided for @addChauffeurPays.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get addChauffeurPays;

  /// No description provided for @addChauffeurPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get addChauffeurPhone;

  /// No description provided for @addChauffeurPhoneHelper.
  ///
  /// In fr, this message translates to:
  /// **'Numéro local, sans l\'indicatif'**
  String get addChauffeurPhoneHelper;

  /// No description provided for @addChauffeurPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone est obligatoire'**
  String get addChauffeurPhoneRequired;

  /// No description provided for @addChauffeurPermisNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de permis'**
  String get addChauffeurPermisNumber;

  /// No description provided for @addChauffeurPermisRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de permis est obligatoire'**
  String get addChauffeurPermisRequired;

  /// No description provided for @addChauffeurPermisExpiration.
  ///
  /// In fr, this message translates to:
  /// **'Expiration du permis (optionnel)'**
  String get addChauffeurPermisExpiration;

  /// No description provided for @addChauffeurPermisNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non renseignée'**
  String get addChauffeurPermisNotSet;

  /// No description provided for @addChauffeurAccessCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'accès (connexion chauffeur)'**
  String get addChauffeurAccessCode;

  /// No description provided for @addChauffeurAccessCodeHelper.
  ///
  /// In fr, this message translates to:
  /// **'Sert au chauffeur pour se connecter à l\'app avec son téléphone'**
  String get addChauffeurAccessCodeHelper;

  /// No description provided for @addChauffeurSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get addChauffeurSave;

  /// No description provided for @addChauffeurSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeur enregistré avec succès'**
  String get addChauffeurSuccess;

  /// No description provided for @assignCamionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Camion pour {nom}'**
  String assignCamionTitle(String nom);

  /// No description provided for @assignCamionEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun camion enregistré. Ajoutez-en un d\'abord.'**
  String get assignCamionEmpty;

  /// No description provided for @assignCamionButton.
  ///
  /// In fr, this message translates to:
  /// **'Assigner ce camion'**
  String get assignCamionButton;

  /// No description provided for @missionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes missions'**
  String get missionsTitle;

  /// No description provided for @missionsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mission pour le moment.'**
  String get missionsEmpty;

  /// No description provided for @missionsStarted.
  ///
  /// In fr, this message translates to:
  /// **'Mission démarrée'**
  String get missionsStarted;

  /// No description provided for @missionsFinished.
  ///
  /// In fr, this message translates to:
  /// **'Mission terminée'**
  String get missionsFinished;

  /// No description provided for @missionsCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Mission annulée'**
  String get missionsCancelled;

  /// No description provided for @missionsCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get missionsCancel;

  /// No description provided for @missionsStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get missionsStart;

  /// No description provided for @missionsFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get missionsFinish;

  /// No description provided for @demandesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demandes disponibles'**
  String get demandesTitle;

  /// No description provided for @demandesTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get demandesTotal;

  /// No description provided for @demandesOuvertes.
  ///
  /// In fr, this message translates to:
  /// **'Ouvertes'**
  String get demandesOuvertes;

  /// No description provided for @demandesEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get demandesEnCours;

  /// No description provided for @demandesFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'TOUS'**
  String get demandesFilterAll;

  /// No description provided for @demandesSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher (départ, destination, produit)'**
  String get demandesSearchHint;

  /// No description provided for @demandesLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les demandes.'**
  String get demandesLoadError;

  /// No description provided for @demandesNoneFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande trouvée.'**
  String get demandesNoneFound;

  /// No description provided for @demandesStatusOuverte.
  ///
  /// In fr, this message translates to:
  /// **'Ouverte'**
  String get demandesStatusOuverte;

  /// No description provided for @demandesStatusEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get demandesStatusEnCours;

  /// No description provided for @demandesStatusTerminee.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get demandesStatusTerminee;

  /// No description provided for @demandesStatusAnnulee.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get demandesStatusAnnulee;

  /// No description provided for @demandesCamionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} camion(s)'**
  String demandesCamionCount(int count);

  /// No description provided for @demandesProposeButton.
  ///
  /// In fr, this message translates to:
  /// **'Proposer'**
  String get demandesProposeButton;

  /// No description provided for @propositionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une proposition'**
  String get propositionTitle;

  /// No description provided for @propositionPriceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un prix valide.'**
  String get propositionPriceRequired;

  /// No description provided for @propositionCamionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins un camion.'**
  String get propositionCamionRequired;

  /// No description provided for @propositionCamionCountMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Cette demande requiert {requis} camion(s) : votre proposition doit tous les inclure ({actuel} pour l\'instant).'**
  String propositionCamionCountMismatch(int requis, int actuel);

  /// No description provided for @propositionSentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Proposition envoyée avec succès'**
  String get propositionSentSuccess;

  /// No description provided for @propositionAlreadySent.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà une proposition en attente pour cette demande.'**
  String get propositionAlreadySent;

  /// No description provided for @propositionNeedCamionFirst.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d\'abord un camion pour pouvoir proposer.'**
  String get propositionNeedCamionFirst;

  /// No description provided for @propositionNoMatchingCamionType.
  ///
  /// In fr, this message translates to:
  /// **'Cette demande nécessite un camion de type {type}, et vous n\'en avez aucun de ce type. Ajoutez-en un pour pouvoir proposer.'**
  String propositionNoMatchingCamionType(String type);

  /// No description provided for @propositionCamionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Camion(s) proposé(s)'**
  String get propositionCamionsLabel;

  /// No description provided for @propositionAddCamion.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un camion'**
  String get propositionAddCamion;

  /// No description provided for @propositionPriceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix proposé ({devise})'**
  String propositionPriceLabel(String devise);

  /// No description provided for @propositionDepartureDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de départ prévue (optionnel)'**
  String get propositionDepartureDate;

  /// No description provided for @propositionDepartureDateNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non précisé'**
  String get propositionDepartureDateNotSet;

  /// No description provided for @propositionMessageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message (optionnel)'**
  String get propositionMessageLabel;

  /// No description provided for @propositionSendButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer la proposition'**
  String get propositionSendButton;

  /// No description provided for @propositionCamionFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Camion'**
  String get propositionCamionFieldLabel;

  /// No description provided for @propositionChauffeurFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeur (optionnel)'**
  String get propositionChauffeurFieldLabel;

  /// No description provided for @propositionChauffeurNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non précisé'**
  String get propositionChauffeurNotSet;

  /// No description provided for @propositionChauffeurEnMission.
  ///
  /// In fr, this message translates to:
  /// **'en mission'**
  String get propositionChauffeurEnMission;

  /// No description provided for @fraicheurTresFiable.
  ///
  /// In fr, this message translates to:
  /// **'Position très fiable'**
  String get fraicheurTresFiable;

  /// No description provided for @fraicheurFiable.
  ///
  /// In fr, this message translates to:
  /// **'Position fiable'**
  String get fraicheurFiable;

  /// No description provided for @fraicheurAVerifier.
  ///
  /// In fr, this message translates to:
  /// **'Position à vérifier'**
  String get fraicheurAVerifier;

  /// No description provided for @fraicheurAncienne.
  ///
  /// In fr, this message translates to:
  /// **'Position ancienne'**
  String get fraicheurAncienne;

  /// No description provided for @fraicheurInconnue.
  ///
  /// In fr, this message translates to:
  /// **'Position inconnue'**
  String get fraicheurInconnue;

  /// No description provided for @gpsFleetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ma flotte'**
  String get gpsFleetTitle;

  /// No description provided for @gpsFleetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Localisation de vos camions et chauffeurs en temps réel'**
  String get gpsFleetSubtitle;

  /// No description provided for @gpsNoChauffeurAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chauffeur assigné'**
  String get gpsNoChauffeurAssigned;

  /// No description provided for @gpsNoPositionReported.
  ///
  /// In fr, this message translates to:
  /// **'Aucune position rapportée pour l\'instant'**
  String get gpsNoPositionReported;

  /// No description provided for @gpsJustNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get gpsJustNow;

  /// No description provided for @gpsAgoMinutes.
  ///
  /// In fr, this message translates to:
  /// **'il y a {minutes} min'**
  String gpsAgoMinutes(int minutes);

  /// No description provided for @gpsAgoHoursMinutes.
  ///
  /// In fr, this message translates to:
  /// **'il y a {heures}h{minutes}'**
  String gpsAgoHoursMinutes(int heures, String minutes);

  /// No description provided for @gpsAgoDays.
  ///
  /// In fr, this message translates to:
  /// **'il y a {jours} j'**
  String gpsAgoDays(int jours);

  /// No description provided for @gpsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivi GPS'**
  String get gpsTitle;

  /// No description provided for @gpsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun camion enregistré. Ajoutez-en un pour suivre sa position ici.'**
  String get gpsEmptyTitle;

  /// No description provided for @gpsHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique · {immatriculation}'**
  String gpsHistoryTitle(String immatriculation);

  /// No description provided for @gpsHistoryEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune position enregistrée'**
  String get gpsHistoryEmptyTitle;

  /// No description provided for @gpsHistoryEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Démarrez le suivi GPS pour commencer à enregistrer le trajet.'**
  String get gpsHistoryEmptySubtitle;

  /// No description provided for @gpsSpeedUnit.
  ///
  /// In fr, this message translates to:
  /// **'{vitesse} km/h'**
  String gpsSpeedUnit(String vitesse);

  /// No description provided for @gpsMapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivi · {immatriculation}'**
  String gpsMapTitle(String immatriculation);

  /// No description provided for @gpsMapNoPositionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune position disponible'**
  String get gpsMapNoPositionTitle;

  /// No description provided for @gpsMapNoPositionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce camion n\'a encore transmis aucune position GPS.'**
  String get gpsMapNoPositionSubtitle;

  /// No description provided for @gpsMapFollowing.
  ///
  /// In fr, this message translates to:
  /// **'Suivi en direct'**
  String get gpsMapFollowing;

  /// No description provided for @gpsMapPaused.
  ///
  /// In fr, this message translates to:
  /// **'Suivi en pause'**
  String get gpsMapPaused;

  /// No description provided for @gpsMapRecenter.
  ///
  /// In fr, this message translates to:
  /// **'Recentrer'**
  String get gpsMapRecenter;

  /// No description provided for @gpsMapSource.
  ///
  /// In fr, this message translates to:
  /// **'Source : {source}'**
  String gpsMapSource(String source);

  /// No description provided for @profilTTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get profilTTitle;

  /// No description provided for @profilTUsername.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get profilTUsername;

  /// No description provided for @profilTCompany.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get profilTCompany;

  /// No description provided for @profilTPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get profilTPhone;

  /// No description provided for @profilTEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get profilTEmail;

  /// No description provided for @profilTAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get profilTAddress;

  /// No description provided for @profilTCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get profilTCountry;

  /// No description provided for @profilTActionsSection.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get profilTActionsSection;

  /// No description provided for @profilTEditProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get profilTEditProfile;

  /// No description provided for @profilTEditProfileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour vos informations personnelles'**
  String get profilTEditProfileSubtitle;

  /// No description provided for @profilTSecurity.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité du compte'**
  String get profilTSecurity;

  /// No description provided for @profilTSecuritySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe, sessions et accès'**
  String get profilTSecuritySubtitle;

  /// No description provided for @profilTLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profilTLanguage;

  /// No description provided for @profilTLanguageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue de l\'application'**
  String get profilTLanguageSubtitle;

  /// No description provided for @profilTLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get profilTLogout;

  /// No description provided for @profilTLogoutSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter de cette session'**
  String get profilTLogoutSubtitle;

  /// No description provided for @profilTRoleTransporteur.
  ///
  /// In fr, this message translates to:
  /// **'Transporteur'**
  String get profilTRoleTransporteur;

  /// No description provided for @profilTRoleEntreprise.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get profilTRoleEntreprise;

  /// No description provided for @profilTRoleAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get profilTRoleAdmin;

  /// No description provided for @profilTRoleDefault.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profilTRoleDefault;

  /// No description provided for @profilTNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get profilTNotSet;

  /// No description provided for @modifierProfilTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier mon profil'**
  String get modifierProfilTitle;

  /// No description provided for @modifierProfilLoginId.
  ///
  /// In fr, this message translates to:
  /// **'{telephone} · identifiant de connexion'**
  String modifierProfilLoginId(String telephone);

  /// No description provided for @modifierProfilInfoSection.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get modifierProfilInfoSection;

  /// No description provided for @modifierProfilCompanyName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'entreprise'**
  String get modifierProfilCompanyName;

  /// No description provided for @modifierProfilCompanyNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Transports Diallo'**
  String get modifierProfilCompanyNameHint;

  /// No description provided for @modifierProfilEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get modifierProfilEmail;

  /// No description provided for @modifierProfilEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'exemple@mail.com'**
  String get modifierProfilEmailHint;

  /// No description provided for @modifierProfilEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide'**
  String get modifierProfilEmailInvalid;

  /// No description provided for @modifierProfilAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get modifierProfilAddress;

  /// No description provided for @modifierProfilAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'Quartier, ville'**
  String get modifierProfilAddressHint;

  /// No description provided for @modifierProfilCountry.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get modifierProfilCountry;

  /// No description provided for @modifierProfilSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get modifierProfilSaveButton;

  /// No description provided for @modifierProfilSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès'**
  String get modifierProfilSuccess;

  /// No description provided for @securiteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité du compte'**
  String get securiteTitle;

  /// No description provided for @securiteIntro.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un mot de passe robuste que vous n\'utilisez sur aucun autre service.'**
  String get securiteIntro;

  /// No description provided for @securiteChangePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get securiteChangePassword;

  /// No description provided for @securiteCurrentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get securiteCurrentPassword;

  /// No description provided for @securiteCurrentPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe actuel est requis'**
  String get securiteCurrentPasswordRequired;

  /// No description provided for @securiteNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get securiteNewPassword;

  /// No description provided for @securiteNewPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nouveau mot de passe est requis'**
  String get securiteNewPasswordRequired;

  /// No description provided for @securitePasswordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 6 caractères'**
  String get securitePasswordMinLength;

  /// No description provided for @securiteStrengthWeak.
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get securiteStrengthWeak;

  /// No description provided for @securiteStrengthMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get securiteStrengthMedium;

  /// No description provided for @securiteStrengthStrong.
  ///
  /// In fr, this message translates to:
  /// **'Fort'**
  String get securiteStrengthStrong;

  /// No description provided for @securiteConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get securiteConfirmPassword;

  /// No description provided for @securitePasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get securitePasswordMismatch;

  /// No description provided for @securiteUpdateButton.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le mot de passe'**
  String get securiteUpdateButton;

  /// No description provided for @securiteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour avec succès'**
  String get securiteSuccess;

  /// No description provided for @clientHomeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, {nom}'**
  String clientHomeGreeting(String nom);

  /// No description provided for @clientHomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre espace entreprise pour piloter vos transports, demandes et missions'**
  String get clientHomeSubtitle;

  /// No description provided for @clientHomeOpenRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes ouvertes'**
  String get clientHomeOpenRequests;

  /// No description provided for @clientHomeMissionsEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Missions en cours'**
  String get clientHomeMissionsEnCours;

  /// No description provided for @clientHomeMissionsTerminees.
  ///
  /// In fr, this message translates to:
  /// **'Missions terminées'**
  String get clientHomeMissionsTerminees;

  /// No description provided for @clientHomePropositionsReceived.
  ///
  /// In fr, this message translates to:
  /// **'Propositions reçues'**
  String get clientHomePropositionsReceived;

  /// No description provided for @clientHomePropositionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Acceptez ou refusez les offres des transporteurs'**
  String get clientHomePropositionsSubtitle;

  /// No description provided for @clientHomeTotalExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses totales'**
  String get clientHomeTotalExpenses;

  /// No description provided for @clientHomeExpensesThisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois-ci : {montant}'**
  String clientHomeExpensesThisMonth(String montant);

  /// No description provided for @clientHomeNewRequestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande'**
  String get clientHomeNewRequestTitle;

  /// No description provided for @clientHomeNewRequestSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une nouvelle demande de transport'**
  String get clientHomeNewRequestSubtitle;

  /// No description provided for @clientHomeMissionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes missions'**
  String get clientHomeMissionsTitle;

  /// No description provided for @clientHomeMissionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivre les transports confiés à un transporteur'**
  String get clientHomeMissionsSubtitle;

  /// No description provided for @clientHomeHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes demandes'**
  String get clientHomeHistoryTitle;

  /// No description provided for @clientHomeHistorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Consulter toutes vos demandes de transport'**
  String get clientHomeHistorySubtitle;

  /// No description provided for @clientHomeNearbyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Camions à proximité'**
  String get clientHomeNearbyTitle;

  /// No description provided for @clientHomeNearbySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouver un camion disponible près de vous'**
  String get clientHomeNearbySubtitle;

  /// No description provided for @clientHomeCompanySpaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace entreprise'**
  String get clientHomeCompanySpaceTitle;

  /// No description provided for @clientHomeCompanySpaceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations et actions rapides du compte'**
  String get clientHomeCompanySpaceSubtitle;

  /// No description provided for @compteClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Compte entreprise'**
  String get compteClientTitle;

  /// No description provided for @compteClientSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre flotte et vos opérations logistiques en toute simplicité'**
  String get compteClientSubtitle;

  /// No description provided for @compteClientActiveBadge.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise active'**
  String get compteClientActiveBadge;

  /// No description provided for @compteClientQuickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get compteClientQuickActions;

  /// No description provided for @compteClientNewRequestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande'**
  String get compteClientNewRequestTitle;

  /// No description provided for @compteClientNewRequestSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer une nouvelle demande de transport'**
  String get compteClientNewRequestSubtitle;

  /// No description provided for @compteClientMissionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes missions'**
  String get compteClientMissionsTitle;

  /// No description provided for @compteClientMissionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivre les transports en cours'**
  String get compteClientMissionsSubtitle;

  /// No description provided for @compteClientHistoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get compteClientHistoryTitle;

  /// No description provided for @compteClientHistorySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Consulter vos demandes précédentes'**
  String get compteClientHistorySubtitle;

  /// No description provided for @compteClientSecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get compteClientSecurityTitle;

  /// No description provided for @compteClientSecuritySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe et sécurité du compte'**
  String get compteClientSecuritySubtitle;

  /// No description provided for @compteClientAccountInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get compteClientAccountInfo;

  /// No description provided for @compteClientName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get compteClientName;

  /// No description provided for @compteClientPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get compteClientPhone;

  /// No description provided for @compteClientAccountType.
  ///
  /// In fr, this message translates to:
  /// **'Type de compte'**
  String get compteClientAccountType;

  /// No description provided for @compteClientStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get compteClientStatus;

  /// No description provided for @compteClientStatusValue.
  ///
  /// In fr, this message translates to:
  /// **'Premium / actif'**
  String get compteClientStatusValue;

  /// No description provided for @compteClientNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get compteClientNotSet;

  /// No description provided for @profilClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil entreprise'**
  String get profilClientTitle;

  /// No description provided for @profilClientVerifiedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Compte entreprise vérifié'**
  String get profilClientVerifiedBadge;

  /// No description provided for @profilClientMainInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations principales'**
  String get profilClientMainInfo;

  /// No description provided for @profilClientNom.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get profilClientNom;

  /// No description provided for @profilClientType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get profilClientType;

  /// No description provided for @profilClientRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get profilClientRole;

  /// No description provided for @profilClientDefaultRole.
  ///
  /// In fr, this message translates to:
  /// **'Client entreprise'**
  String get profilClientDefaultRole;

  /// No description provided for @profilClientAdresseNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Non renseignée'**
  String get profilClientAdresseNotSet;

  /// No description provided for @profilClientActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get profilClientActivity;

  /// No description provided for @profilClientDemandes.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get profilClientDemandes;

  /// No description provided for @profilClientMissions.
  ///
  /// In fr, this message translates to:
  /// **'Missions'**
  String get profilClientMissions;

  /// No description provided for @profilClientQuickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get profilClientQuickActions;

  /// No description provided for @profilClientEditProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get profilClientEditProfile;

  /// No description provided for @profilClientEditProfileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour les informations de votre entreprise'**
  String get profilClientEditProfileSubtitle;

  /// No description provided for @nouvelleDemandeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande transport'**
  String get nouvelleDemandeTitle;

  /// No description provided for @nouvelleDemandeVilleDepart.
  ///
  /// In fr, this message translates to:
  /// **'Ville de départ'**
  String get nouvelleDemandeVilleDepart;

  /// No description provided for @nouvelleDemandePaysDepart.
  ///
  /// In fr, this message translates to:
  /// **'Pays de départ'**
  String get nouvelleDemandePaysDepart;

  /// No description provided for @nouvelleDemandeVilleArrivee.
  ///
  /// In fr, this message translates to:
  /// **'Ville d\'arrivée'**
  String get nouvelleDemandeVilleArrivee;

  /// No description provided for @nouvelleDemandePaysArrivee.
  ///
  /// In fr, this message translates to:
  /// **'Pays d\'arrivée'**
  String get nouvelleDemandePaysArrivee;

  /// No description provided for @nouvelleDemandeTypeCamion.
  ///
  /// In fr, this message translates to:
  /// **'Type de camion'**
  String get nouvelleDemandeTypeCamion;

  /// No description provided for @nouvelleDemandeQuantite.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get nouvelleDemandeQuantite;

  /// No description provided for @nouvelleDemandeQuantiteInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Quantité invalide'**
  String get nouvelleDemandeQuantiteInvalid;

  /// No description provided for @nouvelleDemandeUnite.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get nouvelleDemandeUnite;

  /// No description provided for @nouvelleDemandeUniteLitres.
  ///
  /// In fr, this message translates to:
  /// **'Litres'**
  String get nouvelleDemandeUniteLitres;

  /// No description provided for @nouvelleDemandeUniteTonnes.
  ///
  /// In fr, this message translates to:
  /// **'Tonnes'**
  String get nouvelleDemandeUniteTonnes;

  /// No description provided for @nouvelleDemandeUniteKg.
  ///
  /// In fr, this message translates to:
  /// **'Kg'**
  String get nouvelleDemandeUniteKg;

  /// No description provided for @nouvelleDemandeDateChargement.
  ///
  /// In fr, this message translates to:
  /// **'Date de chargement'**
  String get nouvelleDemandeDateChargement;

  /// No description provided for @nouvelleDemandePrixPropose.
  ///
  /// In fr, this message translates to:
  /// **'Prix proposé (optionnel)'**
  String get nouvelleDemandePrixPropose;

  /// No description provided for @nouvelleDemandePrixInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Prix invalide'**
  String get nouvelleDemandePrixInvalid;

  /// No description provided for @nouvelleDemandeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Marchandise à transporter'**
  String get nouvelleDemandeDescription;

  /// No description provided for @nouvelleDemandeDescriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 20 tonnes de ciment en sacs'**
  String get nouvelleDemandeDescriptionHint;

  /// No description provided for @nouvelleDemandeDescriptionRequired.
  ///
  /// In fr, this message translates to:
  /// **'La marchandise à transporter est obligatoire'**
  String get nouvelleDemandeDescriptionRequired;

  /// No description provided for @nouvelleDemandeDescriptionTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Précisez la marchandise (au moins 3 caractères)'**
  String get nouvelleDemandeDescriptionTooShort;

  /// No description provided for @nouvelleDemandeNombreCamions.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de camions :'**
  String get nouvelleDemandeNombreCamions;

  /// No description provided for @nouvelleDemandeSubmitting.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours...'**
  String get nouvelleDemandeSubmitting;

  /// No description provided for @nouvelleDemandeSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer la demande'**
  String get nouvelleDemandeSubmitButton;

  /// No description provided for @nouvelleDemandeSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Demande de transport créée avec succès.'**
  String get nouvelleDemandeSuccess;

  /// No description provided for @nouvelleDemandeEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la demande'**
  String get nouvelleDemandeEditTitle;

  /// No description provided for @nouvelleDemandeUpdateButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get nouvelleDemandeUpdateButton;

  /// No description provided for @nouvelleDemandeUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Demande modifiée avec succès.'**
  String get nouvelleDemandeUpdateSuccess;

  /// No description provided for @nouvelleDemandeGenericError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {erreur}'**
  String nouvelleDemandeGenericError(String erreur);

  /// No description provided for @missionsClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes missions'**
  String get missionsClientTitle;

  /// No description provided for @missionsClientFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get missionsClientFilterAll;

  /// No description provided for @missionsClientFilterPlanifiee.
  ///
  /// In fr, this message translates to:
  /// **'Planifiées'**
  String get missionsClientFilterPlanifiee;

  /// No description provided for @missionsClientFilterEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get missionsClientFilterEnCours;

  /// No description provided for @missionsClientFilterTerminee.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get missionsClientFilterTerminee;

  /// No description provided for @missionsClientEmptyFiltered.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mission dans ce statut'**
  String get missionsClientEmptyFiltered;

  /// No description provided for @missionsClientEmptyNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mission pour le moment'**
  String get missionsClientEmptyNone;

  /// No description provided for @missionsClientChangeFilter.
  ///
  /// In fr, this message translates to:
  /// **'Changez de filtre pour voir vos autres missions.'**
  String get missionsClientChangeFilter;

  /// No description provided for @missionsClientEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Vos missions apparaîtront ici dès qu\'un transporteur aura accepté une de vos demandes.'**
  String get missionsClientEmptyHint;

  /// No description provided for @missionsClientPaysLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get missionsClientPaysLabel;

  /// No description provided for @missionsClientTransporteurLabel.
  ///
  /// In fr, this message translates to:
  /// **'Transporteur'**
  String get missionsClientTransporteurLabel;

  /// No description provided for @missionsClientMarchandiseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Marchandise'**
  String get missionsClientMarchandiseLabel;

  /// No description provided for @missionsClientCamionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Camions'**
  String get missionsClientCamionsLabel;

  /// No description provided for @missionsClientCamionsValue.
  ///
  /// In fr, this message translates to:
  /// **'{count} camion(s) · {type}'**
  String missionsClientCamionsValue(int count, String type);

  /// No description provided for @missionsClientChargementLabel.
  ///
  /// In fr, this message translates to:
  /// **'Chargement'**
  String get missionsClientChargementLabel;

  /// No description provided for @missionsClientPrixLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix final'**
  String get missionsClientPrixLabel;

  /// No description provided for @missionsClientPrixNonConfirme.
  ///
  /// In fr, this message translates to:
  /// **'Prix à confirmer'**
  String get missionsClientPrixNonConfirme;

  /// No description provided for @missionsClientDepart.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get missionsClientDepart;

  /// No description provided for @missionsClientArrivee.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get missionsClientArrivee;

  /// No description provided for @propositionsRecuesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Propositions reçues'**
  String get propositionsRecuesTitle;

  /// No description provided for @propositionsRecuesFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get propositionsRecuesFilterAll;

  /// No description provided for @propositionsRecuesFilterEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get propositionsRecuesFilterEnAttente;

  /// No description provided for @propositionsRecuesFilterAcceptee.
  ///
  /// In fr, this message translates to:
  /// **'Acceptées'**
  String get propositionsRecuesFilterAcceptee;

  /// No description provided for @propositionsRecuesFilterRefusee.
  ///
  /// In fr, this message translates to:
  /// **'Refusées'**
  String get propositionsRecuesFilterRefusee;

  /// No description provided for @propositionsRecuesEmptyFiltered.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition dans ce statut'**
  String get propositionsRecuesEmptyFiltered;

  /// No description provided for @propositionsRecuesEmptyNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition reçue pour le moment'**
  String get propositionsRecuesEmptyNone;

  /// No description provided for @propositionsRecuesChangeFilter.
  ///
  /// In fr, this message translates to:
  /// **'Changez de filtre pour voir vos autres propositions.'**
  String get propositionsRecuesChangeFilter;

  /// No description provided for @propositionsRecuesEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Les propositions envoyées par les transporteurs pour vos demandes apparaîtront ici.'**
  String get propositionsRecuesEmptyHint;

  /// No description provided for @propositionsRecuesTransporteurLabel.
  ///
  /// In fr, this message translates to:
  /// **'Transporteur'**
  String get propositionsRecuesTransporteurLabel;

  /// No description provided for @propositionsRecuesPrixLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix proposé'**
  String get propositionsRecuesPrixLabel;

  /// No description provided for @propositionsRecuesCamionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Camions'**
  String get propositionsRecuesCamionsLabel;

  /// No description provided for @propositionsRecuesCamionsValue.
  ///
  /// In fr, this message translates to:
  /// **'{count} camion(s) · {type}'**
  String propositionsRecuesCamionsValue(int count, String type);

  /// No description provided for @propositionsRecuesMessageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message du transporteur'**
  String get propositionsRecuesMessageLabel;

  /// No description provided for @propositionsRecuesAccepterButton.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get propositionsRecuesAccepterButton;

  /// No description provided for @propositionsRecuesRefuserButton.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get propositionsRecuesRefuserButton;

  /// No description provided for @propositionsRecuesConfirmerAccepterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accepter cette proposition ?'**
  String get propositionsRecuesConfirmerAccepterTitle;

  /// No description provided for @propositionsRecuesConfirmerAccepterMessage.
  ///
  /// In fr, this message translates to:
  /// **'Une mission sera créée avec ce transporteur, et les autres propositions reçues pour cette demande seront automatiquement refusées.'**
  String get propositionsRecuesConfirmerAccepterMessage;

  /// No description provided for @propositionsRecuesConfirmerRefuserTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser cette proposition ?'**
  String get propositionsRecuesConfirmerRefuserTitle;

  /// No description provided for @propositionsRecuesConfirmerRefuserMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le transporteur sera notifié que sa proposition n\'a pas été retenue.'**
  String get propositionsRecuesConfirmerRefuserMessage;

  /// No description provided for @propositionsRecuesAccepteeSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Proposition acceptée : la mission a été créée.'**
  String get propositionsRecuesAccepteeSuccess;

  /// No description provided for @propositionsRecuesRefuseeSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Proposition refusée.'**
  String get propositionsRecuesRefuseeSuccess;

  /// No description provided for @propositionsRecuesHighlightNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette proposition n\'est plus disponible.'**
  String get propositionsRecuesHighlightNotFound;

  /// No description provided for @mesPropositionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes propositions'**
  String get mesPropositionsTitle;

  /// No description provided for @mesPropositionsEmptyNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune proposition envoyée pour le moment'**
  String get mesPropositionsEmptyNone;

  /// No description provided for @mesPropositionsEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Les propositions que vous envoyez (manuellement ou via le matching automatique) apparaîtront ici.'**
  String get mesPropositionsEmptyHint;

  /// No description provided for @historiqueClientTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes demandes'**
  String get historiqueClientTitle;

  /// No description provided for @historiqueClientFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get historiqueClientFilterAll;

  /// No description provided for @historiqueClientFilterOuverte.
  ///
  /// In fr, this message translates to:
  /// **'Ouvertes'**
  String get historiqueClientFilterOuverte;

  /// No description provided for @historiqueClientFilterEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get historiqueClientFilterEnCours;

  /// No description provided for @historiqueClientFilterTerminee.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get historiqueClientFilterTerminee;

  /// No description provided for @historiqueClientEmptyFiltered.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande dans ce statut'**
  String get historiqueClientEmptyFiltered;

  /// No description provided for @historiqueClientEmptyNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande enregistrée'**
  String get historiqueClientEmptyNone;

  /// No description provided for @historiqueClientChangeFilter.
  ///
  /// In fr, this message translates to:
  /// **'Changez de filtre pour voir vos autres demandes.'**
  String get historiqueClientChangeFilter;

  /// No description provided for @historiqueClientEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez une demande de transport depuis l\'onglet « Demande » : elle apparaîtra ici.'**
  String get historiqueClientEmptyHint;

  /// No description provided for @historiqueClientCreeeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Créée le {date}'**
  String historiqueClientCreeeLabel(String date);

  /// No description provided for @historiqueClientCamionsValue.
  ///
  /// In fr, this message translates to:
  /// **'{count} camion(s)'**
  String historiqueClientCamionsValue(int count);

  /// No description provided for @historiqueClientQuantiteNonPrecisee.
  ///
  /// In fr, this message translates to:
  /// **'Quantité non précisée'**
  String get historiqueClientQuantiteNonPrecisee;

  /// No description provided for @historiqueClientChargementLabel.
  ///
  /// In fr, this message translates to:
  /// **'Chargement {date}'**
  String historiqueClientChargementLabel(String date);

  /// No description provided for @historiqueClientModifier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get historiqueClientModifier;

  /// No description provided for @historiqueClientSupprimer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get historiqueClientSupprimer;

  /// No description provided for @historiqueClientSupprimerConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette demande ?'**
  String get historiqueClientSupprimerConfirmTitle;

  /// No description provided for @historiqueClientSupprimerConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette demande sera annulée et retirée du marché. Cette action est irréversible.'**
  String get historiqueClientSupprimerConfirmMessage;

  /// No description provided for @historiqueClientSupprimerSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Demande supprimée.'**
  String get historiqueClientSupprimerSuccess;

  /// No description provided for @rechercheCamionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Camions à proximité'**
  String get rechercheCamionTitle;

  /// No description provided for @rechercheCamionTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de camion'**
  String get rechercheCamionTypeLabel;

  /// No description provided for @rechercheCamionCapaciteMin.
  ///
  /// In fr, this message translates to:
  /// **'Capacité minimale (optionnel)'**
  String get rechercheCamionCapaciteMin;

  /// No description provided for @rechercheCamionPositionDefined.
  ///
  /// In fr, this message translates to:
  /// **'Position : {latitude}, {longitude}'**
  String rechercheCamionPositionDefined(String latitude, String longitude);

  /// No description provided for @rechercheCamionPositionUndefined.
  ///
  /// In fr, this message translates to:
  /// **'Position non définie — le tri se fera sur la fraîcheur GPS uniquement.'**
  String get rechercheCamionPositionUndefined;

  /// No description provided for @rechercheCamionMyPosition.
  ///
  /// In fr, this message translates to:
  /// **'Ma position'**
  String get rechercheCamionMyPosition;

  /// No description provided for @rechercheCamionSearching.
  ///
  /// In fr, this message translates to:
  /// **'Recherche...'**
  String get rechercheCamionSearching;

  /// No description provided for @rechercheCamionSearchButton.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get rechercheCamionSearchButton;

  /// No description provided for @rechercheCamionEnableLocation.
  ///
  /// In fr, this message translates to:
  /// **'Activez la localisation pour l\'utiliser ici.'**
  String get rechercheCamionEnableLocation;

  /// No description provided for @rechercheCamionPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission de localisation refusée.'**
  String get rechercheCamionPermissionDenied;

  /// No description provided for @rechercheCamionChooseType.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un type de camion et lancez la recherche.'**
  String get rechercheCamionChooseType;

  /// No description provided for @rechercheCamionNoneFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun camion disponible pour ces critères.'**
  String get rechercheCamionNoneFound;

  /// No description provided for @chauffeurDashTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord chauffeur'**
  String get chauffeurDashTitle;

  /// No description provided for @chauffeurDashGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {nom}'**
  String chauffeurDashGreeting(String nom);

  /// No description provided for @chauffeurDashDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'chauffeur'**
  String get chauffeurDashDefaultName;

  /// No description provided for @chauffeurDashReady.
  ///
  /// In fr, this message translates to:
  /// **'Votre espace de suivi est prêt.'**
  String get chauffeurDashReady;

  /// No description provided for @chauffeurDashLocationActive.
  ///
  /// In fr, this message translates to:
  /// **'Localisation active'**
  String get chauffeurDashLocationActive;

  /// No description provided for @chauffeurDashLocationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Localisation indisponible'**
  String get chauffeurDashLocationUnavailable;

  /// No description provided for @chauffeurDashNoMissions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mission assignée pour le moment.'**
  String get chauffeurDashNoMissions;

  /// No description provided for @chauffeurDashMissionFallback.
  ///
  /// In fr, this message translates to:
  /// **'Mission'**
  String get chauffeurDashMissionFallback;

  /// No description provided for @chauffeurDashNoDetails.
  ///
  /// In fr, this message translates to:
  /// **'Aucun détail disponible'**
  String get chauffeurDashNoDetails;

  /// No description provided for @chauffeurDashIdNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant chauffeur introuvable'**
  String get chauffeurDashIdNotFound;

  /// No description provided for @chauffeurDashLocationPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Localisation refusée : le camion ne sera pas visible dans les recherches clients.'**
  String get chauffeurDashLocationPermissionDenied;

  /// No description provided for @chauffeurDashLocationOpenSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages'**
  String get chauffeurDashLocationOpenSettings;

  /// No description provided for @chauffeurDashLocationRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get chauffeurDashLocationRetry;

  /// No description provided for @chauffeurDashMissionsUpdatedByTransporteur.
  ///
  /// In fr, this message translates to:
  /// **'Le transporteur a mis à jour une ou plusieurs missions.'**
  String get chauffeurDashMissionsUpdatedByTransporteur;

  /// No description provided for @chauffeurMissionDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail mission'**
  String get chauffeurMissionDetailTitle;

  /// No description provided for @chauffeurMissionDetailClient.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get chauffeurMissionDetailClient;

  /// No description provided for @chauffeurMissionDetailPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get chauffeurMissionDetailPhone;

  /// No description provided for @chauffeurMissionDetailDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get chauffeurMissionDetailDescription;

  /// No description provided for @chauffeurMissionDetailQuantite.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get chauffeurMissionDetailQuantite;

  /// No description provided for @chauffeurMissionDetailPrix.
  ///
  /// In fr, this message translates to:
  /// **'Prix convenu'**
  String get chauffeurMissionDetailPrix;

  /// No description provided for @chauffeurMissionDetailDepart.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get chauffeurMissionDetailDepart;

  /// No description provided for @chauffeurMissionDetailArrivee.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get chauffeurMissionDetailArrivee;

  /// No description provided for @chauffeurMissionDetailObservations.
  ///
  /// In fr, this message translates to:
  /// **'Observations'**
  String get chauffeurMissionDetailObservations;

  /// No description provided for @chauffeurMissionDetailNoObservations.
  ///
  /// In fr, this message translates to:
  /// **'Aucune observation.'**
  String get chauffeurMissionDetailNoObservations;

  /// No description provided for @chauffeurMissionDetailNotStarted.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore démarrée'**
  String get chauffeurMissionDetailNotStarted;

  /// No description provided for @chauffeurMissionDetailNotArrived.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore arrivée'**
  String get chauffeurMissionDetailNotArrived;

  /// No description provided for @notifTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get notifMarkAllRead;

  /// No description provided for @notifEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour le moment.'**
  String get notifEmpty;

  /// No description provided for @notifPropositionDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Cette proposition n\'existe plus.'**
  String get notifPropositionDeleted;

  /// No description provided for @notifTimeJustNow.
  ///
  /// In fr, this message translates to:
  /// **'À l\'instant'**
  String get notifTimeJustNow;

  /// No description provided for @notifTimeMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {n} min'**
  String notifTimeMinutes(int n);

  /// No description provided for @notifTimeHours.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {n} h'**
  String notifTimeHours(int n);

  /// No description provided for @notifTimeDays.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {n} j'**
  String notifTimeDays(int n);

  /// No description provided for @adminTitle.
  ///
  /// In fr, this message translates to:
  /// **'Administration AfriFlotte'**
  String get adminTitle;

  /// No description provided for @adminDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get adminDefaultName;

  /// No description provided for @adminGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, {nom}'**
  String adminGreeting(String nom);

  /// No description provided for @adminOverview.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble de la plateforme AfriFlotte'**
  String get adminOverview;

  /// No description provided for @adminAccountsSection.
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get adminAccountsSection;

  /// No description provided for @adminTransporteurs.
  ///
  /// In fr, this message translates to:
  /// **'Transporteurs'**
  String get adminTransporteurs;

  /// No description provided for @adminEntreprises.
  ///
  /// In fr, this message translates to:
  /// **'Entreprises'**
  String get adminEntreprises;

  /// No description provided for @adminChauffeurs.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeurs'**
  String get adminChauffeurs;

  /// No description provided for @adminFleetSection.
  ///
  /// In fr, this message translates to:
  /// **'Flotte'**
  String get adminFleetSection;

  /// No description provided for @adminCamions.
  ///
  /// In fr, this message translates to:
  /// **'Camions'**
  String get adminCamions;

  /// No description provided for @adminAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponibles'**
  String get adminAvailable;

  /// No description provided for @adminMissionsSection.
  ///
  /// In fr, this message translates to:
  /// **'Missions'**
  String get adminMissionsSection;

  /// No description provided for @adminTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get adminTotal;

  /// No description provided for @adminEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get adminEnCours;

  /// No description provided for @adminTerminees.
  ///
  /// In fr, this message translates to:
  /// **'Terminées'**
  String get adminTerminees;

  /// No description provided for @adminMarketSection.
  ///
  /// In fr, this message translates to:
  /// **'Marché'**
  String get adminMarketSection;

  /// No description provided for @adminOpenRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes ouvertes'**
  String get adminOpenRequests;

  /// No description provided for @adminRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get adminRevenue;

  /// No description provided for @adminOtherCurrency.
  ///
  /// In fr, this message translates to:
  /// **'+1 autre devise'**
  String get adminOtherCurrency;

  /// No description provided for @adminOtherCurrencies.
  ///
  /// In fr, this message translates to:
  /// **'+{count} autres devises'**
  String adminOtherCurrencies(int count);

  /// No description provided for @paiementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get paiementTitle;

  /// No description provided for @paiementChooseModeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment souhaitez-vous payer ?'**
  String get paiementChooseModeTitle;

  /// No description provided for @paiementModeCarte.
  ///
  /// In fr, this message translates to:
  /// **'Carte bancaire'**
  String get paiementModeCarte;

  /// No description provided for @paiementModeCarteDesc.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en ligne sécurisé'**
  String get paiementModeCarteDesc;

  /// No description provided for @paiementModeManuel.
  ///
  /// In fr, this message translates to:
  /// **'Espèces (main à main)'**
  String get paiementModeManuel;

  /// No description provided for @paiementModeManuelDesc.
  ///
  /// In fr, this message translates to:
  /// **'Un agent AfriFlotte viendra encaisser le paiement'**
  String get paiementModeManuelDesc;

  /// No description provided for @paiementMontantTotal.
  ///
  /// In fr, this message translates to:
  /// **'Montant total'**
  String get paiementMontantTotal;

  /// No description provided for @paiementCommission.
  ///
  /// In fr, this message translates to:
  /// **'Commission AfriFlotte ({taux}%)'**
  String paiementCommission(String taux);

  /// No description provided for @paiementNetTransporteur.
  ///
  /// In fr, this message translates to:
  /// **'Versé au transporteur'**
  String get paiementNetTransporteur;

  /// No description provided for @paiementValider.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get paiementValider;

  /// No description provided for @paiementEnAttenteConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'En attente de confirmation du paiement…'**
  String get paiementEnAttenteConfirmation;

  /// No description provided for @paiementVerifierStatut.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le statut'**
  String get paiementVerifierStatut;

  /// No description provided for @paiementSucces.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé avec succès.'**
  String get paiementSucces;

  /// No description provided for @paiementEchecTitre.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement a échoué'**
  String get paiementEchecTitre;

  /// No description provided for @paiementReessayer.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get paiementReessayer;

  /// No description provided for @paiementBouton.
  ///
  /// In fr, this message translates to:
  /// **'Payer'**
  String get paiementBouton;

  /// No description provided for @paiementCarteMontantAPayer.
  ///
  /// In fr, this message translates to:
  /// **'Montant à payer'**
  String get paiementCarteMontantAPayer;

  /// No description provided for @paiementCarteNumeroLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de carte'**
  String get paiementCarteNumeroLabel;

  /// No description provided for @paiementCarteNomLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du titulaire'**
  String get paiementCarteNomLabel;

  /// No description provided for @paiementCarteExpirationLabel.
  ///
  /// In fr, this message translates to:
  /// **'MM/AA'**
  String get paiementCarteExpirationLabel;

  /// No description provided for @paiementCarteCvvLabel.
  ///
  /// In fr, this message translates to:
  /// **'CVV'**
  String get paiementCarteCvvLabel;

  /// No description provided for @paiementCarteSecuriteNote.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé. Votre numéro de carte et votre CVV ne sont jamais enregistrés.'**
  String get paiementCarteSecuriteNote;

  /// No description provided for @paiementCarteTraitementEnCours.
  ///
  /// In fr, this message translates to:
  /// **'Traitement du paiement…'**
  String get paiementCarteTraitementEnCours;

  /// No description provided for @paiementAnnuleParClient.
  ///
  /// In fr, this message translates to:
  /// **'Paiement annulé'**
  String get paiementAnnuleParClient;

  /// No description provided for @paiementVerificationDelaiDepasse.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement met plus de temps que prévu à se confirmer. Vérifiez plus tard dans \"Mes paiements\".'**
  String get paiementVerificationDelaiDepasse;

  /// No description provided for @paiementHistoriqueTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes paiements'**
  String get paiementHistoriqueTitle;

  /// No description provided for @paiementHistoriqueSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos paiements et leur statut'**
  String get paiementHistoriqueSubtitle;

  /// No description provided for @paiementHistoriqueEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement pour l\'instant'**
  String get paiementHistoriqueEmpty;

  /// No description provided for @paiementDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail du paiement'**
  String get paiementDetailTitle;

  /// No description provided for @paiementOuvrirLitige.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get paiementOuvrirLitige;

  /// No description provided for @paiementMotifLitige.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez le problème'**
  String get paiementMotifLitige;

  /// No description provided for @paiementEnvoyer.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get paiementEnvoyer;

  /// No description provided for @paiementLitigeEnvoye.
  ///
  /// In fr, this message translates to:
  /// **'Litige envoyé, un administrateur va l\'examiner.'**
  String get paiementLitigeEnvoye;

  /// No description provided for @paiementSource.
  ///
  /// In fr, this message translates to:
  /// **'Référence : {reference}'**
  String paiementSource(String reference);

  /// No description provided for @tableColonneNom.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get tableColonneNom;

  /// No description provided for @tableColonneTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get tableColonneTelephone;

  /// No description provided for @tableColonnePays.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get tableColonnePays;

  /// No description provided for @tableColonneTransporteur.
  ///
  /// In fr, this message translates to:
  /// **'Transporteur'**
  String get tableColonneTransporteur;

  /// No description provided for @tableColonneStatut.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get tableColonneStatut;

  /// No description provided for @tableColonneImmatriculation.
  ///
  /// In fr, this message translates to:
  /// **'Immatriculation'**
  String get tableColonneImmatriculation;

  /// No description provided for @tableColonneType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get tableColonneType;

  /// No description provided for @tableColonneVille.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get tableColonneVille;

  /// No description provided for @tableColonneVehicule.
  ///
  /// In fr, this message translates to:
  /// **'Véhicule'**
  String get tableColonneVehicule;

  /// No description provided for @tableColonneTrajet.
  ///
  /// In fr, this message translates to:
  /// **'Trajet'**
  String get tableColonneTrajet;

  /// No description provided for @tableColonneClient.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get tableColonneClient;

  /// No description provided for @tableColonneMontant.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get tableColonneMontant;

  /// No description provided for @tableColonneProduit.
  ///
  /// In fr, this message translates to:
  /// **'Marchandise'**
  String get tableColonneProduit;

  /// No description provided for @tableColonneAction.
  ///
  /// In fr, this message translates to:
  /// **'Action'**
  String get tableColonneAction;

  /// No description provided for @tableColonneCapacite.
  ///
  /// In fr, this message translates to:
  /// **'Capacité'**
  String get tableColonneCapacite;

  /// No description provided for @agentAccueilTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encaissements à collecter'**
  String get agentAccueilTitle;

  /// No description provided for @agentAucunPaiement.
  ///
  /// In fr, this message translates to:
  /// **'Aucun encaissement en attente'**
  String get agentAucunPaiement;

  /// No description provided for @agentEncaisserButton.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser'**
  String get agentEncaisserButton;

  /// No description provided for @agentReferenceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence / numéro de reçu'**
  String get agentReferenceLabel;

  /// No description provided for @agentAjouterPreuve.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une preuve (photo)'**
  String get agentAjouterPreuve;

  /// No description provided for @agentPreuveAjoutee.
  ///
  /// In fr, this message translates to:
  /// **'Photo ajoutée'**
  String get agentPreuveAjoutee;

  /// No description provided for @agentEncaissementConfirme.
  ///
  /// In fr, this message translates to:
  /// **'Encaissement enregistré, en attente de validation admin.'**
  String get agentEncaissementConfirme;

  /// No description provided for @adminPaiementsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiements à traiter'**
  String get adminPaiementsTitle;

  /// No description provided for @adminPaiementsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Rien à traiter pour l\'instant'**
  String get adminPaiementsEmpty;

  /// No description provided for @adminValiderButton.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get adminValiderButton;

  /// No description provided for @adminVerserButton.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme versé'**
  String get adminVerserButton;

  /// No description provided for @adminRembourserButton.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser'**
  String get adminRembourserButton;

  /// No description provided for @adminLitigesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Litiges'**
  String get adminLitigesTitle;

  /// No description provided for @adminLitigesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun litige en cours'**
  String get adminLitigesEmpty;

  /// No description provided for @adminResoudreButton.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre'**
  String get adminResoudreButton;

  /// No description provided for @adminResolutionClient.
  ///
  /// In fr, this message translates to:
  /// **'En faveur du client (rembourser)'**
  String get adminResolutionClient;

  /// No description provided for @adminResolutionTransporteur.
  ///
  /// In fr, this message translates to:
  /// **'En faveur du transporteur (libérer)'**
  String get adminResolutionTransporteur;

  /// No description provided for @adminResolutionRejete.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter le litige'**
  String get adminResolutionRejete;

  /// No description provided for @adminCommentaireLabel.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire'**
  String get adminCommentaireLabel;

  /// No description provided for @adminMotifLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get adminMotifLabel;

  /// No description provided for @adminSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher…'**
  String get adminSearchHint;

  /// No description provided for @adminNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get adminNoResults;

  /// No description provided for @adminUtilisateursTitleTransporteurs.
  ///
  /// In fr, this message translates to:
  /// **'Transporteurs'**
  String get adminUtilisateursTitleTransporteurs;

  /// No description provided for @adminUtilisateursTitleEntreprises.
  ///
  /// In fr, this message translates to:
  /// **'Entreprises'**
  String get adminUtilisateursTitleEntreprises;

  /// No description provided for @adminUtilisateursEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte pour l\'instant'**
  String get adminUtilisateursEmpty;

  /// No description provided for @adminChauffeursTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chauffeurs'**
  String get adminChauffeursTitle;

  /// No description provided for @adminChauffeursEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chauffeur pour l\'instant'**
  String get adminChauffeursEmpty;

  /// No description provided for @adminCamionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Camions'**
  String get adminCamionsTitle;

  /// No description provided for @adminCamionsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get adminCamionsFilterAll;

  /// No description provided for @adminCamionsFilterDispo.
  ///
  /// In fr, this message translates to:
  /// **'Disponibles'**
  String get adminCamionsFilterDispo;

  /// No description provided for @adminCamionsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun camion pour l\'instant'**
  String get adminCamionsEmpty;

  /// No description provided for @adminMissionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Missions'**
  String get adminMissionsTitle;

  /// No description provided for @adminMissionsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mission pour l\'instant'**
  String get adminMissionsEmpty;

  /// No description provided for @adminDemandesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get adminDemandesTitle;

  /// No description provided for @adminDemandesFilterOuverte.
  ///
  /// In fr, this message translates to:
  /// **'Ouvertes'**
  String get adminDemandesFilterOuverte;

  /// No description provided for @adminDemandesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande pour l\'instant'**
  String get adminDemandesEmpty;

  /// No description provided for @missionsClientFilterAnnulee.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get missionsClientFilterAnnulee;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
