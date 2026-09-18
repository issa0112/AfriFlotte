// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRequiredField => 'Required field';

  @override
  String get commonSend => 'Send';

  @override
  String get commonUnexpectedError => 'Unexpected error';

  @override
  String get langSwitchLabel => 'Language';

  @override
  String get langFrench => 'Français';

  @override
  String get langEnglish => 'English';

  @override
  String get splashTagline => 'Africa\'s transport platform';

  @override
  String get authBrand => 'AfriFlotte';

  @override
  String get authWelcomeBackEyebrow => 'WELCOME BACK';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLoginSubtitle =>
      'Enter your credentials to access your space.';

  @override
  String get authPhoneLabel => 'Phone';

  @override
  String get authPhoneRequired => 'Phone number is required';

  @override
  String get authPhoneInvalid => 'Invalid phone number';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String get authForgotPasswordLink => 'Forgot password?';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authNewHereEyebrow => 'NEW HERE';

  @override
  String get authSignupTitle => 'Create an account';

  @override
  String get authSignupSubtitle => 'A few details and you\'re ready to start.';

  @override
  String get authAccountTypeLabel => 'I am...';

  @override
  String get authAccountTypeTransporteur => 'Carrier';

  @override
  String get authAccountTypeEntreprise => 'Business';

  @override
  String get authCompanyNameLabel => 'Company name (optional)';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailLabelInscription => 'Email (optional)';

  @override
  String get authEmailHelper =>
      'Recommended: used to reset your password if you forget it';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Invalid email address';

  @override
  String get authPasswordMinLength => 'At least 6 characters';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authSignupButton => 'Create my account';

  @override
  String get authSwitchToSignupTitle => 'Don\'t have an account yet?';

  @override
  String get authSwitchToSignupText =>
      'Create an account in seconds and pick up right where you left off.';

  @override
  String get authSwitchToSignupButton => 'Sign up';

  @override
  String get authSwitchToLoginTitle => 'Already have an account?';

  @override
  String get authSwitchToLoginText =>
      'Sign in to find your account and continue where you left off.';

  @override
  String get authSwitchToLoginButton => 'Sign in';

  @override
  String get authUserNotFound => 'User not found';

  @override
  String get authIncorrectCredentials => 'Incorrect phone number or password';

  @override
  String get authSignupFailedGeneric => 'Unable to create the account.';

  @override
  String get authAccountCreatedPleaseLogin =>
      'Account created. Sign in to continue.';

  @override
  String get forgotStep1Of2 => 'STEP 1/2';

  @override
  String get forgotStep2Of2 => 'STEP 2/2';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotSubtitle =>
      'Enter the email address linked to your account: we\'ll send you a reset code.';

  @override
  String get forgotSendCodeButton => 'Send code';

  @override
  String get forgotVerificationTitle => 'Verification';

  @override
  String get forgotVerificationSubtitle =>
      'Enter the code you received by email and choose a new password.';

  @override
  String get forgotCodeLabel => '6-digit code';

  @override
  String get forgotCodeInvalid => 'The code must contain 6 digits';

  @override
  String get forgotResendCode => 'Resend code';

  @override
  String get forgotResendCodeInProgress => 'Sending...';

  @override
  String get forgotNewCodeGenerated => 'New code sent by email.';

  @override
  String get forgotNewPasswordLabel => 'New password';

  @override
  String get forgotNewPasswordRequired => 'New password is required';

  @override
  String get forgotResetButton => 'Reset password';

  @override
  String get forgotSuccessTitle => 'Password updated';

  @override
  String get forgotSuccessSubtitle =>
      'You can now sign in with your new password.';

  @override
  String get forgotBackToLogin => 'Back to sign in';

  @override
  String get avatarTakePhoto => 'Take a photo';

  @override
  String get avatarChooseFromGallery => 'Choose from gallery';

  @override
  String get navHome => 'Home';

  @override
  String get navCamions => 'Trucks';

  @override
  String get navChauffeurs => 'Drivers';

  @override
  String get navMissions => 'Missions';

  @override
  String get navGps => 'GPS';

  @override
  String get navProfil => 'Profile';

  @override
  String get navDemande => 'Request';

  @override
  String get navHistorique => 'My requests';

  @override
  String get dashTTitle => 'Dashboard';

  @override
  String dashTGreeting(String nom) {
    return 'Hello, $nom';
  }

  @override
  String get dashTTodaySummary => 'Here\'s the state of your activity today';

  @override
  String get dashTFleetSection => 'Your fleet';

  @override
  String get dashTCamions => 'Trucks';

  @override
  String get dashTAvailable => 'Available';

  @override
  String get dashTChauffeurs => 'Drivers';

  @override
  String get dashTPropositions => 'Proposals';

  @override
  String get dashTTotalRevenue => 'Total revenue';

  @override
  String dashTRevenueThisMonth(String montant) {
    return 'This month: $montant';
  }

  @override
  String get dashTAvailableRequests => 'View open requests and propose a truck';

  @override
  String get dashTMyPropositions => 'Track my sent proposals';

  @override
  String get dashTMissionsSection => 'Missions';

  @override
  String get dashTPlanifiees => 'Planned';

  @override
  String get dashTEnCours => 'In progress';

  @override
  String get dashTTerminees => 'Completed';

  @override
  String get dashTAnnulees => 'Cancelled';

  @override
  String get camionsTitle => 'My trucks';

  @override
  String get camionsErrorLoad => 'No truck registered';

  @override
  String get camionsEmptyTitle => 'No truck registered';

  @override
  String get camionsEmptySubtitle => 'Add your first truck with the + button';

  @override
  String get camionsAvailable => 'Available';

  @override
  String get camionsUnavailable => 'Unavailable';

  @override
  String get camionsEditInfo => 'Edit information';

  @override
  String get camionsManagePhotos => 'Manage photos';

  @override
  String get typeCamionCiterne => 'Tanker truck';

  @override
  String get typeCamionBenne => 'Dump truck';

  @override
  String get typeCamionPlateau => 'Flatbed truck';

  @override
  String get typeCamionConteneur => 'Container truck';

  @override
  String get typeCamionPorteEngin => 'Equipment carrier';

  @override
  String get formatCamionLabel => 'Format';

  @override
  String get formatCamion20Pieds => '20 feet';

  @override
  String get formatCamion40Pieds => '40 feet';

  @override
  String get formatCamion2040Pieds => '20/40 feet';

  @override
  String get formatCamion45Pieds => '45 feet';

  @override
  String get formatCamionCiterne10000L => '10,000 L';

  @override
  String get formatCamionCiterne15000L => '15,000 L';

  @override
  String get formatCamionCiterne20000L => '20,000 L';

  @override
  String get formatCamionCiterne25000L => '25,000 L';

  @override
  String get formatCamionCiterne30000L => '30,000 L';

  @override
  String get formatCamionCiterne35000L => '35,000 L';

  @override
  String get formatCamionCiterne40000L => '40,000 L';

  @override
  String get formatCamionCiterne43000L => '43,000 L';

  @override
  String get formatCamionCiterne45000L => '45,000 L';

  @override
  String get formatCamionCiterne50000L => '50,000 L';

  @override
  String get formatCamionBenne4x2 => '4×2 — 6 wheels';

  @override
  String get formatCamionBenne6x4 => '6×4 — 10 wheels';

  @override
  String get formatCamionBenne8x4 => '8×4 — 12 wheels';

  @override
  String get formatCamionAutre => 'Other';

  @override
  String get formatCamionAutrePrecision => 'Specify the format';

  @override
  String get essieuxLabel => 'Number of axles';

  @override
  String get addCamionTitle => 'Add a truck';

  @override
  String get addCamionType => 'Truck type';

  @override
  String get addCamionRegistration => 'Registration number';

  @override
  String get addCamionRegistrationRequired => 'Registration number is required';

  @override
  String get addCamionMarque => 'Brand';

  @override
  String get addCamionModele => 'Model';

  @override
  String get addCamionCapacity => 'Capacity';

  @override
  String get addCamionCapacityHint => 'E.g.: 43500';

  @override
  String get addCamionCapacityRequired => 'Capacity is required';

  @override
  String get addCamionVille => 'City';

  @override
  String get addCamionVilleHint => 'Bamako';

  @override
  String get addCamionPays => 'Country';

  @override
  String get addCamionPhotosLabel => 'Photos (optional, max 4)';

  @override
  String get addCamionChoosePhotos => 'Choose photos';

  @override
  String get addCamionSave => 'Save';

  @override
  String get addCamionSuccess => 'Truck saved successfully';

  @override
  String get editCamionTitle => 'Edit truck';

  @override
  String get editCamionSuccess => 'Truck updated successfully';

  @override
  String photosCamionTitle(String immatriculation) {
    return 'Photos — $immatriculation';
  }

  @override
  String get photosCamionEmpty => 'No photo for this truck.';

  @override
  String get photosCamionMax => 'Maximum 4 photos per truck.';

  @override
  String get photosCamionPrincipale => 'Main';

  @override
  String get photosCamionDeleteTitle => 'Delete this photo?';

  @override
  String get photosCamionDeleteBody => 'This action is permanent.';

  @override
  String get chauffeursTitle => 'My drivers';

  @override
  String get chauffeursEmpty => 'No driver registered';

  @override
  String get chauffeursActive => 'Active';

  @override
  String get chauffeursInactive => 'Inactive';

  @override
  String get chauffeursNoCamion => 'No truck assigned';

  @override
  String get chauffeursRelease => 'Release';

  @override
  String get chauffeursAssignCamion => 'Assign a truck';

  @override
  String chauffeursReleasedSuccess(String nom) {
    return '$nom: truck released';
  }

  @override
  String get chauffeursNoActiveAssignment =>
      'No active assignment for this driver';

  @override
  String get addChauffeurTitle => 'Add a driver';

  @override
  String get addChauffeurPhotoOptional => 'Photo (optional)';

  @override
  String get addChauffeurFullName => 'Full name';

  @override
  String get addChauffeurNameRequired => 'Name is required';

  @override
  String get addChauffeurPays => 'Country';

  @override
  String get addChauffeurPhone => 'Phone';

  @override
  String get addChauffeurPhoneHelper =>
      'Local number, without the country code';

  @override
  String get addChauffeurPhoneRequired => 'Phone number is required';

  @override
  String get addChauffeurPermisNumber => 'License number';

  @override
  String get addChauffeurPermisRequired => 'License number is required';

  @override
  String get addChauffeurPermisExpiration => 'License expiration (optional)';

  @override
  String get addChauffeurPermisNotSet => 'Not set';

  @override
  String get addChauffeurAccessCode => 'Access code (driver login)';

  @override
  String get addChauffeurAccessCodeHelper =>
      'Used by the driver to sign in to the app with their phone number';

  @override
  String get addChauffeurSave => 'Save';

  @override
  String get addChauffeurSuccess => 'Driver saved successfully';

  @override
  String assignCamionTitle(String nom) {
    return 'Truck for $nom';
  }

  @override
  String get assignCamionEmpty => 'No truck registered. Add one first.';

  @override
  String get assignCamionButton => 'Assign this truck';

  @override
  String get missionsTitle => 'My missions';

  @override
  String get missionsEmpty => 'No mission at the moment.';

  @override
  String get missionsStarted => 'Mission started';

  @override
  String get missionsFinished => 'Mission completed';

  @override
  String get missionsCancelled => 'Mission cancelled';

  @override
  String get missionsCancel => 'Cancel';

  @override
  String get missionsStart => 'Start';

  @override
  String get missionsFinish => 'Finish';

  @override
  String get demandesTitle => 'Available requests';

  @override
  String get demandesTotal => 'Total';

  @override
  String get demandesOuvertes => 'Open';

  @override
  String get demandesEnCours => 'In progress';

  @override
  String get demandesFilterAll => 'ALL';

  @override
  String get demandesSearchHint => 'Search (origin, destination, product)';

  @override
  String get demandesLoadError => 'Unable to load requests.';

  @override
  String get demandesNoneFound => 'No request found.';

  @override
  String get demandesStatusOuverte => 'Open';

  @override
  String get demandesStatusEnCours => 'In progress';

  @override
  String get demandesStatusTerminee => 'Completed';

  @override
  String get demandesStatusAnnulee => 'Cancelled';

  @override
  String demandesCamionCount(int count) {
    return '$count truck(s)';
  }

  @override
  String get demandesProposeButton => 'Propose';

  @override
  String get propositionTitle => 'Send a proposal';

  @override
  String get propositionPriceRequired => 'Enter a valid price.';

  @override
  String get propositionCamionRequired => 'Choose at least one truck.';

  @override
  String propositionCamionCountMismatch(int requis, int actuel) {
    return 'This request requires $requis truck(s): your proposal must include all of them ($actuel so far).';
  }

  @override
  String get propositionSentSuccess => 'Proposal sent successfully';

  @override
  String get propositionAlreadySent =>
      'You already have a pending proposal for this request.';

  @override
  String get propositionNeedCamionFirst =>
      'Add a truck first to be able to make a proposal.';

  @override
  String propositionNoMatchingCamionType(String type) {
    return 'This request requires a $type truck, and you don\'t have one of that type. Add one to be able to make a proposal.';
  }

  @override
  String get propositionCamionsLabel => 'Proposed truck(s)';

  @override
  String get propositionAddCamion => 'Add a truck';

  @override
  String propositionPriceLabel(String devise) {
    return 'Proposed price ($devise)';
  }

  @override
  String get propositionDepartureDate => 'Expected departure date (optional)';

  @override
  String get propositionDepartureDateNotSet => 'Not specified';

  @override
  String get propositionMessageLabel => 'Message (optional)';

  @override
  String get propositionSendButton => 'Send proposal';

  @override
  String get propositionCamionFieldLabel => 'Truck';

  @override
  String get propositionChauffeurFieldLabel => 'Driver (optional)';

  @override
  String get propositionChauffeurNotSet => 'Not specified';

  @override
  String get propositionChauffeurEnMission => 'on mission';

  @override
  String get fraicheurTresFiable => 'Very reliable position';

  @override
  String get fraicheurFiable => 'Reliable position';

  @override
  String get fraicheurAVerifier => 'Position to verify';

  @override
  String get fraicheurAncienne => 'Old position';

  @override
  String get fraicheurInconnue => 'Unknown position';

  @override
  String get gpsFleetTitle => 'My fleet';

  @override
  String get gpsFleetSubtitle =>
      'Real-time location of your trucks and drivers';

  @override
  String get gpsNoChauffeurAssigned => 'No driver assigned';

  @override
  String get gpsNoPositionReported => 'No position reported yet';

  @override
  String get gpsJustNow => 'just now';

  @override
  String gpsAgoMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String gpsAgoHoursMinutes(int heures, String minutes) {
    return '${heures}h$minutes ago';
  }

  @override
  String gpsAgoDays(int jours) {
    return '${jours}d ago';
  }

  @override
  String get gpsTitle => 'GPS tracking';

  @override
  String get gpsEmptyTitle =>
      'No truck registered. Add one to track its position here.';

  @override
  String gpsHistoryTitle(String immatriculation) {
    return 'History · $immatriculation';
  }

  @override
  String get gpsHistoryEmptyTitle => 'No position recorded';

  @override
  String get gpsHistoryEmptySubtitle =>
      'Start GPS tracking to begin recording the route.';

  @override
  String gpsSpeedUnit(String vitesse) {
    return '$vitesse km/h';
  }

  @override
  String gpsMapTitle(String immatriculation) {
    return 'Tracking · $immatriculation';
  }

  @override
  String get gpsMapNoPositionTitle => 'No position available';

  @override
  String get gpsMapNoPositionSubtitle =>
      'This truck hasn\'t reported any GPS position yet.';

  @override
  String get gpsMapFollowing => 'Live tracking';

  @override
  String get gpsMapPaused => 'Tracking paused';

  @override
  String get gpsMapRecenter => 'Recenter';

  @override
  String gpsMapSource(String source) {
    return 'Source: $source';
  }

  @override
  String get profilTTitle => 'My profile';

  @override
  String get profilTUsername => 'Username';

  @override
  String get profilTCompany => 'Company';

  @override
  String get profilTPhone => 'Phone';

  @override
  String get profilTEmail => 'Email';

  @override
  String get profilTAddress => 'Address';

  @override
  String get profilTCountry => 'Country';

  @override
  String get profilTActionsSection => 'Actions';

  @override
  String get profilTEditProfile => 'Edit my profile';

  @override
  String get profilTEditProfileSubtitle => 'Update your personal information';

  @override
  String get profilTSecurity => 'Account security';

  @override
  String get profilTSecuritySubtitle => 'Password, sessions and access';

  @override
  String get profilTLanguage => 'Language';

  @override
  String get profilTLanguageSubtitle => 'Choose the app language';

  @override
  String get profilTLogout => 'Log out';

  @override
  String get profilTLogoutSubtitle => 'Sign out of this session';

  @override
  String get profilTRoleTransporteur => 'Carrier';

  @override
  String get profilTRoleEntreprise => 'Business';

  @override
  String get profilTRoleAdmin => 'Administrator';

  @override
  String get profilTRoleDefault => 'Account';

  @override
  String get profilTNotSet => 'Not set';

  @override
  String get modifierProfilTitle => 'Edit my profile';

  @override
  String modifierProfilLoginId(String telephone) {
    return '$telephone · sign-in ID';
  }

  @override
  String get modifierProfilInfoSection => 'Personal information';

  @override
  String get modifierProfilCompanyName => 'Company name';

  @override
  String get modifierProfilCompanyNameHint => 'E.g.: Diallo Transport';

  @override
  String get modifierProfilEmail => 'Email';

  @override
  String get modifierProfilEmailHint => 'example@mail.com';

  @override
  String get modifierProfilEmailInvalid => 'Invalid email address';

  @override
  String get modifierProfilAddress => 'Address';

  @override
  String get modifierProfilAddressHint => 'Neighborhood, city';

  @override
  String get modifierProfilCountry => 'Country';

  @override
  String get modifierProfilSaveButton => 'Save changes';

  @override
  String get modifierProfilSuccess => 'Profile updated successfully';

  @override
  String get securiteTitle => 'Account security';

  @override
  String get securiteIntro =>
      'Choose a strong password that you don\'t use on any other service.';

  @override
  String get securiteChangePassword => 'Change password';

  @override
  String get securiteCurrentPassword => 'Current password';

  @override
  String get securiteCurrentPasswordRequired => 'Current password is required';

  @override
  String get securiteNewPassword => 'New password';

  @override
  String get securiteNewPasswordRequired => 'New password is required';

  @override
  String get securitePasswordMinLength => 'At least 6 characters';

  @override
  String get securiteStrengthWeak => 'Weak';

  @override
  String get securiteStrengthMedium => 'Medium';

  @override
  String get securiteStrengthStrong => 'Strong';

  @override
  String get securiteConfirmPassword => 'Confirm new password';

  @override
  String get securitePasswordMismatch => 'Passwords do not match';

  @override
  String get securiteUpdateButton => 'Update password';

  @override
  String get securiteSuccess => 'Password updated successfully';

  @override
  String clientHomeGreeting(String nom) {
    return 'Hello, $nom';
  }

  @override
  String get clientHomeSubtitle =>
      'Your business space to manage your transports, requests and missions';

  @override
  String get clientHomeOpenRequests => 'Open requests';

  @override
  String get clientHomeMissionsEnCours => 'Missions in progress';

  @override
  String get clientHomeMissionsTerminees => 'Completed missions';

  @override
  String get clientHomePropositionsReceived => 'Proposals received';

  @override
  String get clientHomePropositionsSubtitle =>
      'Accept or reject carriers\' offers';

  @override
  String get clientHomeTotalExpenses => 'Total expenses';

  @override
  String clientHomeExpensesThisMonth(String montant) {
    return 'This month: $montant';
  }

  @override
  String get clientHomeNewRequestTitle => 'New request';

  @override
  String get clientHomeNewRequestSubtitle => 'Create a new transport request';

  @override
  String get clientHomeMissionsTitle => 'My missions';

  @override
  String get clientHomeMissionsSubtitle =>
      'Track transports entrusted to a carrier';

  @override
  String get clientHomeHistoryTitle => 'My requests';

  @override
  String get clientHomeHistorySubtitle => 'View all your transport requests';

  @override
  String get clientHomeNearbyTitle => 'Nearby trucks';

  @override
  String get clientHomeNearbySubtitle => 'Find an available truck near you';

  @override
  String get clientHomeCompanySpaceTitle => 'Business space';

  @override
  String get clientHomeCompanySpaceSubtitle =>
      'Account information and quick actions';

  @override
  String get compteClientTitle => 'Business account';

  @override
  String get compteClientSubtitle =>
      'Manage your fleet and logistics operations with ease';

  @override
  String get compteClientActiveBadge => 'Active business';

  @override
  String get compteClientQuickActions => 'Quick actions';

  @override
  String get compteClientNewRequestTitle => 'New request';

  @override
  String get compteClientNewRequestSubtitle => 'Create a new transport request';

  @override
  String get compteClientMissionsTitle => 'My missions';

  @override
  String get compteClientMissionsSubtitle => 'Track ongoing transports';

  @override
  String get compteClientHistoryTitle => 'History';

  @override
  String get compteClientHistorySubtitle => 'View your previous requests';

  @override
  String get compteClientSecurityTitle => 'Security';

  @override
  String get compteClientSecuritySubtitle => 'Password and account security';

  @override
  String get compteClientAccountInfo => 'Account information';

  @override
  String get compteClientName => 'Name';

  @override
  String get compteClientPhone => 'Phone';

  @override
  String get compteClientAccountType => 'Account type';

  @override
  String get compteClientStatus => 'Status';

  @override
  String get compteClientStatusValue => 'Premium / active';

  @override
  String get compteClientNotSet => 'Not set';

  @override
  String get profilClientTitle => 'Business profile';

  @override
  String get profilClientVerifiedBadge => 'Verified business account';

  @override
  String get profilClientMainInfo => 'Main information';

  @override
  String get profilClientNom => 'Name';

  @override
  String get profilClientType => 'Type';

  @override
  String get profilClientRole => 'Role';

  @override
  String get profilClientDefaultRole => 'Business client';

  @override
  String get profilClientAdresseNotSet => 'Not set';

  @override
  String get profilClientActivity => 'Activity';

  @override
  String get profilClientDemandes => 'Requests';

  @override
  String get profilClientMissions => 'Missions';

  @override
  String get profilClientQuickActions => 'Quick actions';

  @override
  String get profilClientEditProfile => 'Edit profile';

  @override
  String get profilClientEditProfileSubtitle =>
      'Update your business information';

  @override
  String get nouvelleDemandeTitle => 'New transport request';

  @override
  String get nouvelleDemandeVilleDepart => 'Departure city';

  @override
  String get nouvelleDemandePaysDepart => 'Departure country';

  @override
  String get nouvelleDemandeVilleArrivee => 'Arrival city';

  @override
  String get nouvelleDemandePaysArrivee => 'Arrival country';

  @override
  String get nouvelleDemandeTypeCamion => 'Truck type';

  @override
  String get nouvelleDemandeQuantite => 'Quantity';

  @override
  String get nouvelleDemandeQuantiteInvalid => 'Invalid quantity';

  @override
  String get nouvelleDemandeUnite => 'Unit';

  @override
  String get nouvelleDemandeUniteLitres => 'Liters';

  @override
  String get nouvelleDemandeUniteTonnes => 'Tons';

  @override
  String get nouvelleDemandeUniteKg => 'Kg';

  @override
  String get nouvelleDemandeDateChargement => 'Loading date';

  @override
  String get nouvelleDemandePrixPropose => 'Proposed price (optional)';

  @override
  String get nouvelleDemandePrixInvalid => 'Invalid price';

  @override
  String get nouvelleDemandeDescription => 'Goods to transport';

  @override
  String get nouvelleDemandeDescriptionHint => 'E.g.: 20 tons of bagged cement';

  @override
  String get nouvelleDemandeDescriptionRequired =>
      'The goods to transport are required';

  @override
  String get nouvelleDemandeDescriptionTooShort =>
      'Describe the goods more precisely (at least 3 characters)';

  @override
  String get nouvelleDemandeNombreCamions => 'Number of trucks:';

  @override
  String get nouvelleDemandeSubmitting => 'Sending...';

  @override
  String get nouvelleDemandeSubmitButton => 'Create request';

  @override
  String get nouvelleDemandeSuccess =>
      'Transport request created successfully.';

  @override
  String get nouvelleDemandeEditTitle => 'Edit request';

  @override
  String get nouvelleDemandeUpdateButton => 'Save changes';

  @override
  String get nouvelleDemandeUpdateSuccess => 'Request updated successfully.';

  @override
  String nouvelleDemandeGenericError(String erreur) {
    return 'Error: $erreur';
  }

  @override
  String get missionsClientTitle => 'My missions';

  @override
  String get missionsClientFilterAll => 'All';

  @override
  String get missionsClientFilterPlanifiee => 'Planned';

  @override
  String get missionsClientFilterEnCours => 'In progress';

  @override
  String get missionsClientFilterTerminee => 'Completed';

  @override
  String get missionsClientEmptyFiltered => 'No mission in this status';

  @override
  String get missionsClientEmptyNone => 'No mission at the moment';

  @override
  String get missionsClientChangeFilter =>
      'Change the filter to see your other missions.';

  @override
  String get missionsClientEmptyHint =>
      'Your missions will appear here as soon as a carrier accepts one of your requests.';

  @override
  String get missionsClientPaysLabel => 'Countries';

  @override
  String get missionsClientTransporteurLabel => 'Carrier';

  @override
  String get missionsClientMarchandiseLabel => 'Goods';

  @override
  String get missionsClientCamionsLabel => 'Trucks';

  @override
  String missionsClientCamionsValue(int count, String type) {
    return '$count truck(s) · $type';
  }

  @override
  String get missionsClientChargementLabel => 'Loading';

  @override
  String get missionsClientPrixLabel => 'Final price';

  @override
  String get missionsClientPrixNonConfirme => 'Price to be confirmed';

  @override
  String get missionsClientDepart => 'Departure';

  @override
  String get missionsClientArrivee => 'Arrival';

  @override
  String get propositionsRecuesTitle => 'Received proposals';

  @override
  String get propositionsRecuesFilterAll => 'All';

  @override
  String get propositionsRecuesFilterEnAttente => 'Pending';

  @override
  String get propositionsRecuesFilterAcceptee => 'Accepted';

  @override
  String get propositionsRecuesFilterRefusee => 'Rejected';

  @override
  String get propositionsRecuesEmptyFiltered => 'No proposal in this status';

  @override
  String get propositionsRecuesEmptyNone => 'No proposal received yet';

  @override
  String get propositionsRecuesChangeFilter =>
      'Change the filter to see your other proposals.';

  @override
  String get propositionsRecuesEmptyHint =>
      'Proposals sent by carriers for your requests will appear here.';

  @override
  String get propositionsRecuesTransporteurLabel => 'Carrier';

  @override
  String get propositionsRecuesPrixLabel => 'Proposed price';

  @override
  String get propositionsRecuesCamionsLabel => 'Trucks';

  @override
  String propositionsRecuesCamionsValue(int count, String type) {
    return '$count truck(s) · $type';
  }

  @override
  String get propositionsRecuesMessageLabel => 'Message from the carrier';

  @override
  String get propositionsRecuesAccepterButton => 'Accept';

  @override
  String get propositionsRecuesRefuserButton => 'Reject';

  @override
  String get propositionsRecuesConfirmerAccepterTitle =>
      'Accept this proposal?';

  @override
  String get propositionsRecuesConfirmerAccepterMessage =>
      'A mission will be created with this carrier, and the other proposals received for this request will be automatically rejected.';

  @override
  String get propositionsRecuesConfirmerRefuserTitle => 'Reject this proposal?';

  @override
  String get propositionsRecuesConfirmerRefuserMessage =>
      'The carrier will be notified that their proposal was not selected.';

  @override
  String get propositionsRecuesAccepteeSuccess =>
      'Proposal accepted: the mission was created.';

  @override
  String get propositionsRecuesRefuseeSuccess => 'Proposal rejected.';

  @override
  String get propositionsRecuesHighlightNotFound =>
      'This proposal is no longer available.';

  @override
  String get mesPropositionsTitle => 'My proposals';

  @override
  String get mesPropositionsEmptyNone => 'No proposal sent yet';

  @override
  String get mesPropositionsEmptyHint =>
      'Proposals you send (manually or via automatic matching) will appear here.';

  @override
  String get historiqueClientTitle => 'My requests';

  @override
  String get historiqueClientFilterAll => 'All';

  @override
  String get historiqueClientFilterOuverte => 'Open';

  @override
  String get historiqueClientFilterEnCours => 'In progress';

  @override
  String get historiqueClientFilterTerminee => 'Completed';

  @override
  String get historiqueClientEmptyFiltered => 'No request in this status';

  @override
  String get historiqueClientEmptyNone => 'No request registered';

  @override
  String get historiqueClientChangeFilter =>
      'Change the filter to see your other requests.';

  @override
  String get historiqueClientEmptyHint =>
      'Create a transport request from the \"Request\" tab: it will appear here.';

  @override
  String historiqueClientCreeeLabel(String date) {
    return 'Created on $date';
  }

  @override
  String historiqueClientCamionsValue(int count) {
    return '$count truck(s)';
  }

  @override
  String get historiqueClientQuantiteNonPrecisee => 'Quantity not specified';

  @override
  String historiqueClientChargementLabel(String date) {
    return 'Loading $date';
  }

  @override
  String get historiqueClientModifier => 'Edit';

  @override
  String get historiqueClientSupprimer => 'Delete';

  @override
  String get historiqueClientSupprimerConfirmTitle => 'Delete this request?';

  @override
  String get historiqueClientSupprimerConfirmMessage =>
      'This request will be cancelled and removed from the marketplace. This action cannot be undone.';

  @override
  String get historiqueClientSupprimerSuccess => 'Request deleted.';

  @override
  String get rechercheCamionTitle => 'Nearby trucks';

  @override
  String get rechercheCamionTypeLabel => 'Truck type';

  @override
  String get rechercheCamionCapaciteMin => 'Minimum capacity (optional)';

  @override
  String rechercheCamionPositionDefined(String latitude, String longitude) {
    return 'Position: $latitude, $longitude';
  }

  @override
  String get rechercheCamionPositionUndefined =>
      'Position not set — sorting will be based on GPS freshness only.';

  @override
  String get rechercheCamionMyPosition => 'My position';

  @override
  String get rechercheCamionSearching => 'Searching...';

  @override
  String get rechercheCamionSearchButton => 'Search';

  @override
  String get rechercheCamionEnableLocation =>
      'Enable location to use this here.';

  @override
  String get rechercheCamionPermissionDenied => 'Location permission denied.';

  @override
  String get rechercheCamionChooseType =>
      'Choose a truck type and start the search.';

  @override
  String get rechercheCamionNoneFound =>
      'No truck available for these criteria.';

  @override
  String get chauffeurDashTitle => 'Driver dashboard';

  @override
  String chauffeurDashGreeting(String nom) {
    return 'Hello $nom';
  }

  @override
  String get chauffeurDashDefaultName => 'driver';

  @override
  String get chauffeurDashReady => 'Your tracking space is ready.';

  @override
  String get chauffeurDashLocationActive => 'Location active';

  @override
  String get chauffeurDashLocationUnavailable => 'Location unavailable';

  @override
  String get chauffeurDashNoMissions => 'No mission assigned at the moment.';

  @override
  String get chauffeurDashMissionFallback => 'Mission';

  @override
  String get chauffeurDashNoDetails => 'No details available';

  @override
  String get chauffeurDashIdNotFound => 'Driver ID not found';

  @override
  String get chauffeurDashLocationPermissionDenied =>
      'Location denied: the truck won\'t show up in client searches.';

  @override
  String get chauffeurDashLocationOpenSettings => 'Open settings';

  @override
  String get chauffeurDashLocationRetry => 'Retry';

  @override
  String get chauffeurDashMissionsUpdatedByTransporteur =>
      'The carrier updated one or more missions.';

  @override
  String get chauffeurMissionDetailTitle => 'Mission details';

  @override
  String get chauffeurMissionDetailClient => 'Client';

  @override
  String get chauffeurMissionDetailPhone => 'Phone';

  @override
  String get chauffeurMissionDetailDescription => 'Description';

  @override
  String get chauffeurMissionDetailQuantite => 'Quantity';

  @override
  String get chauffeurMissionDetailPrix => 'Agreed price';

  @override
  String get chauffeurMissionDetailDepart => 'Departure';

  @override
  String get chauffeurMissionDetailArrivee => 'Arrival';

  @override
  String get chauffeurMissionDetailObservations => 'Observations';

  @override
  String get chauffeurMissionDetailNoObservations => 'No observations.';

  @override
  String get chauffeurMissionDetailNotStarted => 'Not started yet';

  @override
  String get chauffeurMissionDetailNotArrived => 'Not arrived yet';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifMarkAllRead => 'Mark all as read';

  @override
  String get notifEmpty => 'No notification at the moment.';

  @override
  String get notifPropositionDeleted => 'This proposal no longer exists.';

  @override
  String get notifTimeJustNow => 'Just now';

  @override
  String notifTimeMinutes(int n) {
    return '$n min ago';
  }

  @override
  String notifTimeHours(int n) {
    return '$n h ago';
  }

  @override
  String notifTimeDays(int n) {
    return '$n d ago';
  }

  @override
  String get adminTitle => 'AfriFlotte Administration';

  @override
  String get adminDefaultName => 'Admin';

  @override
  String adminGreeting(String nom) {
    return 'Welcome, $nom';
  }

  @override
  String get adminOverview => 'Overview of the AfriFlotte platform';

  @override
  String get adminAccountsSection => 'Accounts';

  @override
  String get adminTransporteurs => 'Carriers';

  @override
  String get adminEntreprises => 'Businesses';

  @override
  String get adminChauffeurs => 'Drivers';

  @override
  String get adminFleetSection => 'Fleet';

  @override
  String get adminCamions => 'Trucks';

  @override
  String get adminAvailable => 'Available';

  @override
  String get adminMissionsSection => 'Missions';

  @override
  String get adminTotal => 'Total';

  @override
  String get adminEnCours => 'In progress';

  @override
  String get adminTerminees => 'Completed';

  @override
  String get adminMarketSection => 'Market';

  @override
  String get adminOpenRequests => 'Open requests';

  @override
  String get adminRevenue => 'Revenue';

  @override
  String get adminOtherCurrency => '+1 other currency';

  @override
  String adminOtherCurrencies(int count) {
    return '+$count other currencies';
  }

  @override
  String get paiementTitle => 'Payment';

  @override
  String get paiementChooseModeTitle => 'How would you like to pay?';

  @override
  String get paiementModeCarte => 'Bank card';

  @override
  String get paiementModeCarteDesc => 'Secure online payment';

  @override
  String get paiementModeManuel => 'Cash (in person)';

  @override
  String get paiementModeManuelDesc =>
      'An AfriFlotte agent will come to collect the payment';

  @override
  String get paiementMontantTotal => 'Total amount';

  @override
  String paiementCommission(String taux) {
    return 'AfriFlotte commission ($taux%)';
  }

  @override
  String get paiementNetTransporteur => 'Paid to the carrier';

  @override
  String get paiementValider => 'Confirm';

  @override
  String get paiementEnAttenteConfirmation =>
      'Waiting for payment confirmation…';

  @override
  String get paiementVerifierStatut => 'Check status';

  @override
  String get paiementSucces => 'Payment secured successfully.';

  @override
  String get paiementEchecTitre => 'Payment failed';

  @override
  String get paiementReessayer => 'Retry';

  @override
  String get paiementBouton => 'Pay';

  @override
  String get paiementCarteMontantAPayer => 'Amount to pay';

  @override
  String get paiementCarteNumeroLabel => 'Card number';

  @override
  String get paiementCarteExpirationLabel => 'MM/YY';

  @override
  String get paiementCarteCvvLabel => 'CVV';

  @override
  String get paiementCarteSecuriteNote =>
      'Secure payment. Your card number and CVV are never stored.';

  @override
  String get paiementCarteTraitementEnCours => 'Processing payment…';

  @override
  String get paiementMobileOperateurLabel => 'Mobile Money operator';

  @override
  String get paiementMobileNumeroLabel => 'Mobile Money number';

  @override
  String get paiementMobileNote =>
      'You will receive a payment confirmation request on this number.';

  @override
  String get paiementAnnuleParClient => 'Payment cancelled';

  @override
  String get paiementVerificationDelaiDepasse =>
      'The payment is taking longer than expected to confirm. Check again later in \"My payments\".';

  @override
  String get paiementHistoriqueTitle => 'My payments';

  @override
  String get paiementHistoriqueSubtitle =>
      'Track your payments and their status';

  @override
  String get paiementHistoriqueEmpty => 'No payments yet';

  @override
  String get paiementDetailTitle => 'Payment detail';

  @override
  String get paiementOuvrirLitige => 'Report a problem';

  @override
  String get paiementMotifLitige => 'Describe the problem';

  @override
  String get paiementEnvoyer => 'Send';

  @override
  String get paiementLitigeEnvoye =>
      'Dispute sent, an administrator will review it.';

  @override
  String paiementSource(String reference) {
    return 'Reference: $reference';
  }

  @override
  String get tableColonneNom => 'Name';

  @override
  String get tableColonneTelephone => 'Phone';

  @override
  String get tableColonnePays => 'Country';

  @override
  String get tableColonneTransporteur => 'Carrier';

  @override
  String get tableColonneStatut => 'Status';

  @override
  String get tableColonneImmatriculation => 'Plate number';

  @override
  String get tableColonneType => 'Type';

  @override
  String get tableColonneVille => 'City';

  @override
  String get tableColonneVehicule => 'Vehicle';

  @override
  String get tableColonneTrajet => 'Route';

  @override
  String get tableColonneClient => 'Client';

  @override
  String get tableColonneMontant => 'Amount';

  @override
  String get tableColonneProduit => 'Goods';

  @override
  String get tableColonneAction => 'Action';

  @override
  String get tableColonneCapacite => 'Capacity';

  @override
  String get agentAccueilTitle => 'Payments to collect';

  @override
  String get agentAucunPaiement => 'No pending collections';

  @override
  String get agentEncaisserButton => 'Collect';

  @override
  String get agentReferenceLabel => 'Reference / receipt number';

  @override
  String get agentAjouterPreuve => 'Add a proof (photo)';

  @override
  String get agentPreuveAjoutee => 'Photo added';

  @override
  String get agentEncaissementConfirme =>
      'Collection recorded, awaiting admin validation.';

  @override
  String get paiementMobileConfirme => 'Mobile Money payment confirmed.';

  @override
  String get adminPaiementsTitle => 'Payments to process';

  @override
  String get adminPaiementsEmpty => 'Nothing to process right now';

  @override
  String get adminValiderButton => 'Validate';

  @override
  String get adminVerserButton => 'Mark as paid out';

  @override
  String get adminRembourserButton => 'Refund';

  @override
  String get adminLitigesTitle => 'Disputes';

  @override
  String get adminLitigesEmpty => 'No open disputes';

  @override
  String get adminResoudreButton => 'Resolve';

  @override
  String get adminResolutionClient => 'In favor of the client (refund)';

  @override
  String get adminResolutionTransporteur => 'In favor of the carrier (release)';

  @override
  String get adminResolutionRejete => 'Reject the dispute';

  @override
  String get adminCommentaireLabel => 'Comment';

  @override
  String get adminMotifLabel => 'Reason';

  @override
  String get adminSearchHint => 'Search…';

  @override
  String get adminNoResults => 'No results';

  @override
  String get adminUtilisateursTitleTransporteurs => 'Carriers';

  @override
  String get adminUtilisateursTitleEntreprises => 'Companies';

  @override
  String get adminUtilisateursEmpty => 'No account yet';

  @override
  String get adminChauffeursTitle => 'Drivers';

  @override
  String get adminChauffeursEmpty => 'No driver yet';

  @override
  String get adminCamionsTitle => 'Trucks';

  @override
  String get adminCamionsFilterAll => 'All';

  @override
  String get adminCamionsFilterDispo => 'Available';

  @override
  String get adminCamionsEmpty => 'No truck yet';

  @override
  String get adminMissionsTitle => 'Missions';

  @override
  String get adminMissionsEmpty => 'No mission yet';

  @override
  String get adminDemandesTitle => 'Requests';

  @override
  String get adminDemandesFilterOuverte => 'Open';

  @override
  String get adminDemandesEmpty => 'No request yet';

  @override
  String get missionsClientFilterAnnulee => 'Cancelled';

  @override
  String get contratChargementErreur => 'Unable to load this contract.';

  @override
  String contratVersionLabel(String date) {
    return 'Version of $date';
  }

  @override
  String get contratTelechargerPdf => 'Download as PDF';

  @override
  String get contratPaiementTitre => 'Payment terms';

  @override
  String get contratPaiementLien => 'View the payment terms';

  @override
  String get contratTransporteurTitre => 'Carrier partnership agreement';

  @override
  String get contratTransporteurLireLien =>
      'Read the carrier partnership agreement';

  @override
  String get contratTransporteurLegal => 'Carrier agreement';

  @override
  String get contratTransporteurLegalSousTitre =>
      'Read, download or check the acceptance date';

  @override
  String contratAccepteLe(String date) {
    return 'Accepted on $date';
  }

  @override
  String get authAccepteContratPrefixe => 'I have read and accept the ';

  @override
  String get authAccepteContratLien => 'carrier partnership agreement';

  @override
  String get authAccepteContratRequis =>
      'You must accept the agreement to create a carrier account';

  @override
  String get contratGateTitre => 'Before you continue';

  @override
  String get contratGateSousTitre =>
      'This agreement governs your partnership with AfriFlotte: please read it before continuing.';

  @override
  String get contratGateCheckbox => 'I have read and accept this agreement';

  @override
  String get contratGateAccepter => 'Accept and continue';

  @override
  String get contratGateDeconnexion => 'Log out';
}
