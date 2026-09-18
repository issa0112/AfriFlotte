/// Un bloc de section : soit un paragraphe, soit une liste à puces — miroir
/// de `core/contrats.py` (`_p`/`_liste`) côté Django, seule source du texte.
sealed class ContratBloc {
  factory ContratBloc.depuisJson(Map<String, dynamic> json) {
    if (json['type'] == 'liste') {
      return ContratBlocListe(
        (json['items'] as List).map((e) => e.toString()).toList(),
      );
    }
    return ContratBlocParagraphe(json['texte']?.toString() ?? '');
  }
}

class ContratBlocParagraphe implements ContratBloc {
  final String texte;
  const ContratBlocParagraphe(this.texte);
}

class ContratBlocListe implements ContratBloc {
  final List<String> items;
  const ContratBlocListe(this.items);
}

class ContratSection {
  final String titre;
  final List<ContratBloc> blocs;

  const ContratSection({required this.titre, required this.blocs});

  factory ContratSection.depuisJson(Map<String, dynamic> json) {
    return ContratSection(
      titre: json['titre']?.toString() ?? '',
      blocs: (json['blocs'] as List)
          .map((b) => ContratBloc.depuisJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Contrat {
  final String type;
  final String titre;
  final String version;
  final List<ContratSection> sections;

  const Contrat({
    required this.type,
    required this.titre,
    required this.version,
    required this.sections,
  });

  factory Contrat.depuisJson(Map<String, dynamic> json) {
    return Contrat(
      type: json['type']?.toString() ?? '',
      titre: json['titre']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      sections: (json['sections'] as List)
          .map((s) => ContratSection.depuisJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
