import 'package:flutter/material.dart';

import '../constants/pays_cedeao.dart';

/// Sélecteur de pays CEDEAO, réutilisé partout où un pays doit être choisi
/// (demande de transport, camion...) — la liste des 15 pays n'est ainsi
/// écrite qu'à un seul endroit côté UI (`paysCedeaoListe`).
class PaysDropdown extends StatelessWidget {
  final String value;
  final String label;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  const PaysDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.icon = Icons.flag_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final valeurConnue = paysCedeaoListe.any((pays) => pays.code == value);

    return DropdownButtonFormField<String>(
      initialValue: valeurConnue ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      items: paysCedeaoListe
          .map(
            (pays) => DropdownMenuItem(value: pays.code, child: Text(pays.nom)),
          )
          .toList(),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
