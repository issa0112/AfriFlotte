# TODO - Conception et évolution du projet AfriFlotte

## Vision du produit
AfriFlotte est une application de gestion logistique pour faciliter la mise en relation entre clients, transporteurs et entreprises autour des demandes de transport, des propositions, des missions et du suivi GPS.

## Architecture retenue
- Backend : Django + Django REST Framework
- Frontend : Flutter pour mobile
- Base de données : SQLite en environnement de développement
- Authentification : JWT via Django REST Framework simplejwt
- Stockage des médias : dossiers media/ pour photos de camions, chauffeurs et profils

## Modules principaux
- Authentification et profils utilisateur
- Gestion des camions et chauffeurs
- Demandes de transport
- Propositions de transport
- Missions et suivi de statut
- Dashboard transporteur / client / administrateur
- Suivi GPS et historique de mission

## État actuel du projet
- [x] Structure backend avec modèles principaux déjà définis
- [x] API Django organisée autour de plusieurs endpoints
- [x] Écran de profil transporteur moderne en Flutter
- [x] Intégration du profil dans l’accueil transporteur

## Priorités de conception pour la suite
- [ ] Finaliser le flux d’authentification et la gestion des sessions
- [ ] Relier les écrans Flutter aux endpoints Django
- [ ] Définir précisément le flux demande → proposition → mission
- [ ] Harmoniser l’interface des écrans transporteur et client
- [ ] Ajouter la gestion des états de chargement et des erreurs API
- [ ] Préparer la logique de suivi GPS et de mise à jour des statuts

## Checklist de validation
- [x] Modèle de domaine principal
- [x] Structure backend
- [x] Structure frontend
- [ ] Flux utilisateur complet
- [ ] Flux opérationnel de transport
- [ ] Expérience mobile cohérente
