import 'package:flutter/material.dart';

/// Visionneuse plein écran pour une ou plusieurs photos (galerie camion, ou
/// photo unique de chauffeur) : fond noir, zoom au pincement, défilement
/// horizontal entre les photos, indicateurs de page — le style "regarder en
/// grand" qu'on retrouve dans les galeries photo natives.
class PhotoGalleryViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String? titre;

  const PhotoGalleryViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.titre,
  });

  /// Ouvre la visionneuse en plein écran, avec un fondu plutôt qu'un slide
  /// (plus sobre pour une simple mise en grand d'image). Ne fait rien si
  /// `photos` est vide — appelable directement au clic sans garde préalable.
  static Future<void> ouvrir(
    BuildContext context, {
    required List<String> photos,
    int initialIndex = 0,
    String? titre,
  }) {
    if (photos.isEmpty) return Future<void>.value();

    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => PhotoGalleryViewer(
          photos: photos,
          initialIndex: initialIndex.clamp(0, photos.length - 1),
          titre: titre,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<PhotoGalleryViewer> createState() => _PhotoGalleryViewerState();
}

class _PhotoGalleryViewerState extends State<PhotoGalleryViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plusieurs = widget.photos.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: widget.photos[i],
                    child: Image.network(
                      widget.photos[i],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                            strokeWidth: 2.5,
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white38,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  if (widget.titre != null)
                    Expanded(
                      child: Text(
                        widget.titre!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  _BoutonRond(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (plusieurs)
              Positioned(
                left: 0,
                right: 0,
                bottom: 22,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_index + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.photos.length, (i) {
                        final actif = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: actif ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: actif ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BoutonRond({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}
