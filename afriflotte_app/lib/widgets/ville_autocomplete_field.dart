import 'package:flutter/material.dart';

import '../constants/villes_cedeao.dart';

const String _lettresAccentuees = 'àâäáãåèéêëìíîïòóôöõùúûüýÿçñ';
const String _lettresSimples = 'aaaaaaeeeeiiiiooooouuuuyycn';

/// Comparaison insensible aux accents : un utilisateur qui tape "segou" doit
/// quand même voir "Ségou" proposé, clavier sans accents ou pas.
String _sansAccents(String texte) {
  var resultat = texte.toLowerCase();
  for (var i = 0; i < _lettresAccentuees.length; i++) {
    resultat = resultat.replaceAll(_lettresAccentuees[i], _lettresSimples[i]);
  }
  return resultat;
}

/// Champ ville avec suggestions filtrées par pays, cliquables au fil de la
/// saisie (cf. `villesParPays`). Reste un champ libre : les suggestions
/// assistent la saisie sans la contraindre, toute ville absente de la liste
/// reste acceptée — remplace un `TextFormField` simple à isoler de code.
class VilleAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String pays;
  final InputDecoration decoration;
  final String? Function(String?)? validator;

  const VilleAutocompleteField({
    super.key,
    required this.controller,
    required this.pays,
    required this.decoration,
    this.validator,
  });

  @override
  State<VilleAutocompleteField> createState() =>
      _VilleAutocompleteFieldState();
}

class _VilleAutocompleteFieldState extends State<VilleAutocompleteField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue value) {
        final saisie = _sansAccents(value.text.trim());
        if (saisie.isEmpty) return const Iterable<String>.empty();
        final villes = villesParPays[widget.pays] ?? const <String>[];
        return villes.where((ville) => _sansAccents(ville).contains(saisie));
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: widget.decoration,
          validator: widget.validator,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, minWidth: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_city_outlined,
                      size: 20,
                    ),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
