import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../cli/konyak_cli_client.dart';
import '../../l10n/konyak_localizations.dart';

part 'winetricks_dialog.freezed.dart';

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class WinetricksVerbDecision with _$WinetricksVerbDecision {
  const factory WinetricksVerbDecision.install(String verbId) =
      InstallWinetricksVerb;

  const factory WinetricksVerbDecision.cancelled() = CancelledWinetricksDialog;
}

@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class WinetricksVerbSelection with _$WinetricksVerbSelection {
  const factory WinetricksVerbSelection.selected(WinetricksVerbSummary verb) =
      SelectedWinetricksVerb;

  const factory WinetricksVerbSelection.none() = NoWinetricksVerbSelection;
}

WinetricksVerbDecision winetricksVerbDecisionFromNullable(
  WinetricksVerbDecision? decision,
) {
  return decision ?? const WinetricksVerbDecision.cancelled();
}

WinetricksVerbSelection winetricksVerbSelectionById({
  required List<WinetricksCategorySummary> categories,
  required String verbId,
}) {
  final matches = categories
      .expand((category) => category.verbs)
      .where((verb) => verb.id == verbId)
      .take(1)
      .toList(growable: false);
  return switch (matches) {
    [final verb] => WinetricksVerbSelection.selected(verb),
    _ => const WinetricksVerbSelection.none(),
  };
}

WinetricksVerbSelection visibleWinetricksVerbSelection({
  required WinetricksVerbSelection selection,
  required List<WinetricksCategorySummary> categories,
}) {
  return switch (selection) {
    SelectedWinetricksVerb(:final verb) => winetricksVerbSelectionById(
      categories: categories,
      verbId: verb.id,
    ),
    NoWinetricksVerbSelection() => const WinetricksVerbSelection.none(),
  };
}

class WinetricksDialog extends StatefulWidget {
  const WinetricksDialog({
    super.key,
    required this.bottleName,
    required this.categories,
  });

  final String bottleName;
  final List<WinetricksCategorySummary> categories;

  @override
  State<WinetricksDialog> createState() => _WinetricksDialogState();
}

class _WinetricksDialogState extends State<WinetricksDialog> {
  final TextEditingController _searchController = TextEditingController();
  WinetricksVerbSelection _verbSelection = const WinetricksVerbSelection.none();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = KonyakLocalizations.of(context);
    final filteredCategories = _filteredWinetricksCategories(
      categories: widget.categories,
      query: _searchController.text,
    );
    final visibleSelection = visibleWinetricksVerbSelection(
      selection: _verbSelection,
      categories: filteredCategories,
    );

    return AlertDialog(
      title: Text(localizations.winetricksIn(widget.bottleName)),
      content: SizedBox(
        width: 640,
        height: 420,
        child: widget.categories.isEmpty
            ? Center(child: Text(localizations.noWinetricksVerbsFound))
            : Column(
                children: [
                  TextField(
                    key: const ValueKey('winetricks-search-field'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: localizations.searchWinetricksPackages,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredCategories.isEmpty
                        ? Center(
                            child: Text(
                              localizations.noMatchingWinetricksVerbs,
                            ),
                          )
                        : DefaultTabController(
                            key: ValueKey(
                              'winetricks-tabs-${filteredCategories.length}-'
                              '${_normalizedWinetricksSearchQuery(_searchController.text)}',
                            ),
                            length: filteredCategories.length,
                            child: Column(
                              children: [
                                TabBar(
                                  isScrollable: true,
                                  tabs: [
                                    for (final category in filteredCategories)
                                      Tab(text: category.name),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      for (final category in filteredCategories)
                                        _WinetricksVerbList(
                                          category: category,
                                          selection: visibleSelection,
                                          onSelected: (verb) {
                                            setState(() {
                                              _verbSelection =
                                                  WinetricksVerbSelection.selected(
                                                    verb,
                                                  );
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(const WinetricksVerbDecision.cancelled());
          },
          child: Text(localizations.cancel),
        ),
        FilledButton.icon(
          onPressed: switch (visibleSelection) {
            SelectedWinetricksVerb(:final verb) => () {
              Navigator.of(
                context,
              ).pop(WinetricksVerbDecision.install(verb.id));
            },
            NoWinetricksVerbSelection() => null,
          },
          icon: const Icon(Icons.play_arrow),
          label: Text(localizations.run),
        ),
      ],
    );
  }
}

List<WinetricksCategorySummary> _filteredWinetricksCategories({
  required List<WinetricksCategorySummary> categories,
  required String query,
}) {
  final normalizedQuery = _normalizedWinetricksSearchQuery(query);
  if (normalizedQuery.isEmpty) {
    return categories;
  }

  return List.unmodifiable([
    for (final category in categories)
      if (_filteredWinetricksVerbs(category.verbs, normalizedQuery).isNotEmpty)
        WinetricksCategorySummary(
          id: category.id,
          name: category.name,
          verbs: _filteredWinetricksVerbs(category.verbs, normalizedQuery),
        ),
  ]);
}

List<WinetricksVerbSummary> _filteredWinetricksVerbs(
  List<WinetricksVerbSummary> verbs,
  String normalizedQuery,
) {
  return List.unmodifiable(
    verbs.where((verb) => _winetricksVerbMatches(verb, normalizedQuery)),
  );
}

bool _winetricksVerbMatches(
  WinetricksVerbSummary verb,
  String normalizedQuery,
) {
  final haystack = '${verb.id} ${verb.name} ${verb.description}'.toLowerCase();
  return haystack.contains(normalizedQuery);
}

String _normalizedWinetricksSearchQuery(String query) {
  return query.trim().toLowerCase();
}

class _WinetricksVerbList extends StatelessWidget {
  const _WinetricksVerbList({
    required this.category,
    required this.selection,
    required this.onSelected,
  });

  final WinetricksCategorySummary category;
  final WinetricksVerbSelection selection;
  final ValueChanged<WinetricksVerbSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    if (category.verbs.isEmpty) {
      return Center(
        child: Text(KonyakLocalizations.of(context).noVerbsInThisCategory),
      );
    }

    return ListView.builder(
      itemCount: category.verbs.length,
      itemBuilder: (context, index) {
        final verb = category.verbs[index];

        return ListTile(
          title: Text(verb.name),
          subtitle: Text(verb.description),
          selected: switch (selection) {
            SelectedWinetricksVerb(verb: final selectedVerb) =>
              verb.id == selectedVerb.id,
            NoWinetricksVerbSelection() => false,
          },
          onTap: () => onSelected(verb),
        );
      },
    );
  }
}
