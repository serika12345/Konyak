import 'package:flutter/material.dart';

import '../../cli/konyak_cli_client.dart';

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
  String? _selectedVerbId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _filteredWinetricksCategories(
      categories: widget.categories,
      query: _searchController.text,
    );
    final selectedVerbId = _selectedVerbId;
    final canRun =
        selectedVerbId != null &&
        _winetricksCategoriesContainVerb(filteredCategories, selectedVerbId);

    return AlertDialog(
      title: Text('Winetricks in ${widget.bottleName}'),
      content: SizedBox(
        width: 640,
        height: 420,
        child: widget.categories.isEmpty
            ? const Center(child: Text('No winetricks verbs found.'))
            : Column(
                children: [
                  TextField(
                    key: const ValueKey('winetricks-search-field'),
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search winetricks packages',
                      prefixIcon: Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filteredCategories.isEmpty
                        ? const Center(
                            child: Text('No matching winetricks verbs.'),
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
                                          selectedVerbId: selectedVerbId,
                                          onSelected: (verb) {
                                            setState(() {
                                              _selectedVerbId = verb.id;
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: !canRun
              ? null
              : () => Navigator.of(context).pop(selectedVerbId),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Run'),
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

bool _winetricksCategoriesContainVerb(
  List<WinetricksCategorySummary> categories,
  String verbId,
) {
  return categories.any(
    (category) => category.verbs.any((verb) => verb.id == verbId),
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
    required this.selectedVerbId,
    required this.onSelected,
  });

  final WinetricksCategorySummary category;
  final String? selectedVerbId;
  final ValueChanged<WinetricksVerbSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    if (category.verbs.isEmpty) {
      return const Center(child: Text('No verbs in this category.'));
    }

    return ListView.builder(
      itemCount: category.verbs.length,
      itemBuilder: (context, index) {
        final verb = category.verbs[index];

        return ListTile(
          title: Text(verb.name),
          subtitle: Text(verb.description),
          selected: verb.id == selectedVerbId,
          onTap: () => onSelected(verb),
        );
      },
    );
  }
}
