import 'package:flutter/material.dart';

import '../utils/responsive.dart';

const _bleuNuit = Color(0xFF102C5C);

/// Une colonne d'un `ResponsiveEntityList` — `sortBy` optionnel : `null`
/// rend la colonne non triable (en-tête statique), sinon un tap sur l'en-tête
/// trie `items` avec ce comparateur (bascule ascendant/descendant).
class TableColumn<T> {
  final String label;
  final DataCell Function(T item) cell;
  final Comparator<T>? sortBy;
  final bool numeric;

  const TableColumn({
    required this.label,
    required this.cell,
    this.sortBy,
    this.numeric = false,
  });
}

/// Liste d'entités responsive : sur mobile, la liste de cartes existante de
/// l'écran appelant (`mobileCardBuilder`, strictement inchangée visuellement)
/// ; sur tablette/desktop, une vraie table dense et triable (`DataTable`),
/// pour donner à l'admin/au transporteur un vrai espace de travail façon
/// tableur plutôt qu'une colonne de cartes étirée. Ne gère ni le chargement
/// ni les erreurs ni l'état vide — l'écran appelant garde cette logique
/// exactement comme avant, cette liste ne reçoit que des `items` déjà prêts
/// à afficher.
class ResponsiveEntityList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item) mobileCardBuilder;
  final List<TableColumn<T>> columns;
  final void Function(T item)? onRowTap;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry padding;

  const ResponsiveEntityList({
    super.key,
    required this.items,
    required this.mobileCardBuilder,
    required this.columns,
    this.onRowTap,
    this.onRefresh,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<ResponsiveEntityList<T>> createState() => _ResponsiveEntityListState<T>();
}

class _ResponsiveEntityListState<T> extends State<ResponsiveEntityList<T>> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<T> get _itemsTries {
    final index = _sortColumnIndex;
    if (index == null) return widget.items;
    final comparateur = widget.columns[index].sortBy;
    if (comparateur == null) return widget.items;

    final copie = List<T>.of(widget.items);
    copie.sort(_sortAscending ? comparateur : (a, b) => comparateur(b, a));
    return copie;
  }

  @override
  Widget build(BuildContext context) {
    if (formFactorOf(context) == FormFactor.mobile) {
      final liste = ListView.separated(
        padding: widget.padding,
        itemCount: widget.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            widget.mobileCardBuilder(context, widget.items[index]),
      );

      return widget.onRefresh == null
          ? liste
          : RefreshIndicator(onRefresh: widget.onRefresh!, child: liste);
    }

    final items = _itemsTries;

    return SingleChildScrollView(
      padding: widget.padding,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            headingRowColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _bleuNuit,
              fontSize: 13,
            ),
            columns: [
              for (var i = 0; i < widget.columns.length; i++)
                DataColumn(
                  label: Text(widget.columns[i].label),
                  numeric: widget.columns[i].numeric,
                  onSort: widget.columns[i].sortBy == null
                      ? null
                      : (columnIndex, ascending) => setState(() {
                          _sortColumnIndex = columnIndex;
                          _sortAscending = ascending;
                        }),
                ),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  cells: [for (final col in widget.columns) col.cell(item)],
                  onSelectChanged: widget.onRowTap == null
                      ? null
                      : (_) => widget.onRowTap!(item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
