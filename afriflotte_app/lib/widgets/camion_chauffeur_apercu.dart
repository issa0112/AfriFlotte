import 'package:flutter/material.dart';

import '../models/camion.dart' show CamionImage;
import 'photo_gallery_viewer.dart';

/// Aperçu compact du camion (miniature de sa photo principale) et du
/// chauffeur affecté (miniature de sa photo) proposés/assignés sur une
/// ligne de proposition ou de mission — cliquer sur une photo l'ouvre en
/// grand (galerie complète pour le camion, plein écran pour le chauffeur).
/// Partagé entre `propositions_recues_screen.dart` et
/// `missions_client_screen.dart` : avant son ajout, le client ne voyait
/// jamais à quoi ressemblait le camion ou le chauffeur qu'on lui proposait.
class CamionChauffeurApercu extends StatelessWidget {
  final String camionImmatriculation;
  final List<CamionImage> camionImages;
  final String? chauffeurNom;
  final String? chauffeurPhoto;

  const CamionChauffeurApercu({
    super.key,
    required this.camionImmatriculation,
    this.camionImages = const [],
    this.chauffeurNom,
    this.chauffeurPhoto,
  });

  CamionImage? get _imagePrincipale {
    if (camionImages.isEmpty) return null;
    final principale = camionImages.where((image) => image.principale);
    return principale.isNotEmpty ? principale.first : camionImages.first;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imagePrincipale = _imagePrincipale;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          _MiniatureCamion(
            image: imagePrincipale,
            nombrePhotos: camionImages.length,
            onTap: imagePrincipale == null
                ? null
                : () => PhotoGalleryViewer.ouvrir(
                    context,
                    photos: camionImages.map((i) => i.url).toList(),
                    initialIndex: camionImages.indexOf(imagePrincipale),
                    titre: camionImmatriculation,
                  ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  camionImmatriculation,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
                if (chauffeurNom != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          chauffeurNom!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (chauffeurNom != null) ...[
            const SizedBox(width: 10),
            _AvatarChauffeur(nom: chauffeurNom!, photo: chauffeurPhoto),
          ],
        ],
      ),
    );
  }
}

class _MiniatureCamion extends StatelessWidget {
  final CamionImage? image;
  final int nombrePhotos;
  final VoidCallback? onTap;

  const _MiniatureCamion({
    required this.image,
    required this.nombrePhotos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget placeholder() => Container(
      color: scheme.secondary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(Icons.local_shipping_rounded, color: scheme.secondary, size: 22),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: SizedBox(
        width: 54,
        height: 54,
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: image?.url ?? 'camion-sans-photo-$hashCode',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: image != null
                      ? Image.network(
                          image!.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => placeholder(),
                        )
                      : placeholder(),
                ),
              ),
            ),
            if (nombrePhotos > 1)
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_rounded, size: 9, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        '$nombrePhotos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarChauffeur extends StatelessWidget {
  final String nom;
  final String? photo;

  const _AvatarChauffeur({required this.nom, required this.photo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initiale = nom.trim().isNotEmpty ? nom.trim()[0].toUpperCase() : '?';

    Widget avatar() => photo != null
        ? Hero(
            tag: photo!,
            child: CircleAvatar(radius: 19, backgroundImage: NetworkImage(photo!)),
          )
        : CircleAvatar(
            radius: 19,
            backgroundColor: scheme.secondary.withValues(alpha: 0.18),
            child: Text(
              initiale,
              style: TextStyle(color: scheme.secondary, fontWeight: FontWeight.w800),
            ),
          );

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: photo == null
          ? null
          : () => PhotoGalleryViewer.ouvrir(context, photos: [photo!], titre: nom),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant, width: 1.5),
        ),
        child: avatar(),
      ),
    );
  }
}
