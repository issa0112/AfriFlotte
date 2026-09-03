import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/generated/app_localizations.dart';

/// Avatar circulaire avec badge appareil-photo, réutilisé pour la photo de
/// profil (transporteur/client) et la photo d'un chauffeur : affiche l'image
/// réseau si `photoUrl` est fourni, sinon les initiales. Un tap ouvre une
/// feuille de choix caméra/galerie puis transmet le fichier choisi via
/// [onImageSelectionnee] — l'upload effectif (et sa cible : `/profil/` ou
/// `/chauffeurs/{id}/`) reste à la charge de l'écran appelant.
///
/// [previewBytes] permet d'afficher un aperçu local avant tout upload — cas
/// de la création d'un chauffeur, où la photo est choisie avant que la
/// ressource n'existe côté serveur (donc avant d'avoir une `photoUrl`) ; elle
/// prévaut sur `photoUrl` quand les deux sont fournis.
class AvatarPicker extends StatelessWidget {
  final String? photoUrl;
  final Uint8List? previewBytes;
  final String initiales;
  final double radius;
  final bool loading;
  final ValueChanged<XFile> onImageSelectionnee;

  const AvatarPicker({
    super.key,
    required this.photoUrl,
    required this.initiales,
    required this.onImageSelectionnee,
    this.previewBytes,
    this.radius = 34,
    this.loading = false,
  });

  Future<void> _choisirSource(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.avatarTakePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.avatarChooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final fichier = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );

    if (fichier != null) onImageSelectionnee(fichier);
  }

  @override
  Widget build(BuildContext context) {
    final aApercu = previewBytes != null;
    final aPhoto = aApercu || (photoUrl != null && photoUrl!.isNotEmpty);
    final ImageProvider? image = aApercu
        ? MemoryImage(previewBytes!)
        : (aPhoto ? NetworkImage(photoUrl!) : null);

    return GestureDetector(
      onTap: loading ? null : () => _choisirSource(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            backgroundImage: image,
            child: loading
                ? SizedBox(
                    width: radius * 0.7,
                    height: radius * 0.7,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.indigo.shade700,
                    ),
                  )
                : (!aPhoto)
                    ? Text(
                        initiales,
                        style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: radius * 0.78,
                        ),
                      )
                    : null,
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
