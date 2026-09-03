import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/camion.dart';
import '../../../services/camion_service.dart';

/// Gestion des photos d'un camion déjà enregistré : ajouter (jusqu'à 4),
/// choisir laquelle est la principale, supprimer. La photo n'est pas requise
/// à la création du camion — cet écran couvre l'après-coup.
class GererPhotosCamion extends StatefulWidget {
  final String token;
  final Camion camion;

  const GererPhotosCamion({
    super.key,
    required this.token,
    required this.camion,
  });

  @override
  State<GererPhotosCamion> createState() => _GererPhotosCamionState();
}

class _GererPhotosCamionState extends State<GererPhotosCamion> {
  late Camion _camion;
  bool _chargement = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _camion = widget.camion;
  }

  void _erreur(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Pas de `GET /api/camions/<id>/` côté backend : on recharge la liste du
  /// transporteur et on reprend ce camion, plutôt que de dupliquer l'état
  /// côté client au fil des mutations.
  Future<void> _rafraichir() async {
    try {
      final camions = await CamionService.getCamions(widget.token);
      final trouve = camions.where((c) => c.id == _camion.id);
      if (trouve.isNotEmpty && mounted) {
        setState(() => _camion = trouve.first);
      }
    } catch (e) {
      _erreur('$e'.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _ajouterPhotos() async {
    final l10n = AppLocalizations.of(context);

    if (_camion.images.length >= 4) {
      _erreur(l10n.photosCamionMax);
      return;
    }

    final fichiers = await _picker.pickMultiImage();
    if (fichiers.isEmpty) return;

    final placesRestantes = 4 - _camion.images.length;

    setState(() => _chargement = true);

    try {
      for (final fichier in fichiers.take(placesRestantes)) {
        await CamionService.uploadImageCamion(
          token: widget.token,
          camionId: _camion.id,
          imageFile: fichier,
        );
      }
      await _rafraichir();
    } catch (e) {
      _erreur('$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _definirPrincipale(CamionImage image) async {
    if (image.principale) return;

    setState(() => _chargement = true);

    try {
      await CamionService.definirImagePrincipale(
        token: widget.token,
        imageId: image.id,
      );
      await _rafraichir();
    } catch (e) {
      _erreur('$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _supprimer(CamionImage image) async {
    final l10n = AppLocalizations.of(context);

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.photosCamionDeleteTitle),
        content: Text(l10n.photosCamionDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.commonDelete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _chargement = true);

    try {
      await CamionService.supprimerImageCamion(
        token: widget.token,
        imageId: image.id,
      );
      await _rafraichir();
    } catch (e) {
      _erreur('$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.photosCamionTitle(_camion.immatriculation)),
        backgroundColor: const Color(0xFF102C5C),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF102C5C),
        onPressed: _chargement ? null : _ajouterPhotos,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
      body: Stack(
        children: [
          _camion.images.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.photosCamionEmpty),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: _camion.images.length,
                  itemBuilder: (context, index) {
                    final image = _camion.images[index];
                    return _PhotoTile(
                      image: image,
                      onDefinirPrincipale: () => _definirPrincipale(image),
                      onSupprimer: () => _supprimer(image),
                    );
                  },
                ),
          if (_chargement)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final CamionImage image;
  final VoidCallback onDefinirPrincipale;
  final VoidCallback onSupprimer;

  const _PhotoTile({
    required this.image,
    required this.onDefinirPrincipale,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            image.url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
            ),
          ),
          if (image.principale)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF102C5C),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.photosCamionPrincipale,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: _RondIcone(
              icon: Icons.delete_outline,
              color: Colors.redAccent,
              onTap: onSupprimer,
            ),
          ),
          if (!image.principale)
            Positioned(
              bottom: 4,
              right: 4,
              child: _RondIcone(
                icon: Icons.star_outline,
                color: const Color(0xFF102C5C),
                onTap: onDefinirPrincipale,
              ),
            ),
        ],
      ),
    );
  }
}

class _RondIcone extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RondIcone({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
