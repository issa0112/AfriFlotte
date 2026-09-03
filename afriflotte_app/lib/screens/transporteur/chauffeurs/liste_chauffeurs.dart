import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/pays_cedeao.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/chauffeur.dart';
import '../../../services/chauffeur_service.dart';
import '../../../utils/telephone.dart';
import '../../../widgets/avatar_picker.dart';
import '../../../widgets/liquid_bottom_nav.dart';
import 'affecter_camion_screen.dart';
import 'ajouter_chauffeur.dart';

class ListeChauffeurs extends StatefulWidget {
  final String token;

  const ListeChauffeurs({super.key, required this.token});

  @override
  State<ListeChauffeurs> createState() => _ListeChauffeursState();
}

class _ListeChauffeursState extends State<ListeChauffeurs> {
  late Future<List<Chauffeur>> _futureChauffeurs;
  int? _actionEnCoursPourId;
  int? _photoEnCoursPourId;

  @override
  void initState() {
    super.initState();
    _futureChauffeurs = ChauffeurService.getChauffeurs(widget.token);
  }

  Future<void> _rafraichir() async {
    final future = ChauffeurService.getChauffeurs(widget.token);
    // Bloc `{ }`, pas une flèche `=>` : `_futureChauffeurs = future` est une
    // expression qui VAUT `future` (un Future) — en flèche, setState()
    // recevrait un callback qui "retourne" ce Future et lève une assertion
    // ("setState() callback argument returned a Future").
    setState(() {
      _futureChauffeurs = future;
    });
    await future.catchError((_) => <Chauffeur>[]);
  }

  Future<void> _ouvrirAjout() async {
    final retour = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterChauffeur(token: widget.token),
      ),
    );

    if (retour == true) _rafraichir();
  }

  Future<void> _assigner(Chauffeur chauffeur) async {
    final retour = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AffecterCamionScreen(token: widget.token, chauffeur: chauffeur),
      ),
    );

    if (retour == true) _rafraichir();
  }

  Future<void> _liberer(Chauffeur chauffeur) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _actionEnCoursPourId = chauffeur.id);

    try {
      final affectations = await ChauffeurService.getAffectations(
        widget.token,
        chauffeurId: chauffeur.id,
        active: true,
      );

      if (affectations.isEmpty) {
        throw Exception(l10n.chauffeursNoActiveAssignment);
      }

      await ChauffeurService.terminerAffectation(
        token: widget.token,
        affectationId: affectations.first.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chauffeursReleasedSuccess(chauffeur.nom))),
      );

      await _rafraichir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _actionEnCoursPourId = null);
    }
  }

  Future<void> _changerPhoto(Chauffeur chauffeur, XFile fichier) async {
    setState(() => _photoEnCoursPourId = chauffeur.id);

    try {
      await ChauffeurService.uploaderPhotoChauffeur(
        token: widget.token,
        chauffeurId: chauffeur.id,
        photo: fichier,
      );

      await _rafraichir();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _photoEnCoursPourId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chauffeursTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            onPressed: _rafraichir,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom:
              LiquidBottomNav.height + MediaQuery.of(context).padding.bottom,
        ),
        child: FloatingActionButton(
          onPressed: _ouvrirAjout,
          child: const Icon(Icons.add),
        ),
      ),
      body: FutureBuilder<List<Chauffeur>>(
        future: _futureChauffeurs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'.replaceFirst('Exception: ', '')),
            );
          }

          final chauffeurs = snapshot.data ?? const <Chauffeur>[];

          if (chauffeurs.isEmpty) {
            return RefreshIndicator(
              onRefresh: _rafraichir,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(l10n.chauffeursEmpty)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _rafraichir,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: chauffeurs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final chauffeur = chauffeurs[index];
                final actionEnCours = _actionEnCoursPourId == chauffeur.id;

                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AvatarPicker(
                              photoUrl: chauffeur.photo,
                              initiales: chauffeur.nom.isNotEmpty
                                  ? chauffeur.nom[0].toUpperCase()
                                  : '?',
                              radius: 20,
                              loading: _photoEnCoursPourId == chauffeur.id,
                              onImageSelectionnee: (fichier) =>
                                  _changerPhoto(chauffeur, fichier),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chauffeur.nom,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${formaterLocal(chauffeur.telephone, chauffeur.pays)} · ${nomParPays(chauffeur.pays) ?? chauffeur.pays}',
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: chauffeur.actif
                                    ? Colors.green.shade50
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                chauffeur.actif
                                    ? l10n.chauffeursActive
                                    : l10n.chauffeursInactive,
                                style: TextStyle(
                                      color: chauffeur.actif
                                          ? Theme.of(context).colorScheme.secondary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                chauffeur.aUnCamion
                                    ? chauffeur.camionActuel!.immatriculation
                                    : l10n.chauffeursNoCamion,
                                style: TextStyle(
                                  color: chauffeur.aUnCamion
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: actionEnCours
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : chauffeur.aUnCamion
                              ? TextButton.icon(
                                  onPressed: () => _liberer(chauffeur),
                                  icon: const Icon(Icons.link_off),
                                  label: Text(l10n.chauffeursRelease),
                                )
                              : TextButton.icon(
                                  onPressed: () => _assigner(chauffeur),
                                  icon: const Icon(Icons.link),
                                  label: Text(l10n.chauffeursAssignCamion),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
