import 'package:flutter/material.dart';
import 'package:sign_language_recognition_app/models/sign_model.dart';
import 'package:sign_language_recognition_app/services/db_helper.dart';
import 'package:sign_language_recognition_app/shared/widgets/sign_card.dart';

class SignsLibraryPage extends StatefulWidget {
  const SignsLibraryPage({super.key});

  @override
  State<SignsLibraryPage> createState() => _SignsLibraryPageState();
}

class _SignsLibraryPageState extends State<SignsLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  final DBHelper _dbHelper = DBHelper();
  List<Sign> _allSigns = [];
  List<Sign> _filteredSigns = [];

  final List<String> _categories = [
    'All',
    'Alphabet',
    'Numbers',
    'Words',
  ];

  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadSigns();
    _searchController.addListener(_filterSigns);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSigns);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSigns() async {
    try {
      final signs = await _dbHelper.getAllSigns();
      if (!mounted) return;
      setState(() {
        _allSigns = signs;
        _filteredSigns = signs;
      });
    } catch (e) {
      if (!mounted) return;
    }
  }

  void _filterSigns() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSigns = _allSigns
          .where((sign) {
            final matchesCategory = _selectedCategory == 'All' ||
                sign.category.toLowerCase() == _selectedCategory.toLowerCase();
            final matchesQuery = sign.name.toLowerCase().contains(query);
            return matchesCategory && matchesQuery;
          })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("MSL Sign Library"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(height: 10),
            SearchBar(
              controller: _searchController,
              hintText: 'Search for signs...',
              leading: const Icon(
                Icons.search,
                color: Color.fromRGBO(113, 113, 130, 1),
              ),
              onChanged: (value) {
                // The listener already handles filtering
              },
              constraints: const BoxConstraints(
                minHeight: 45
              ),
              elevation: WidgetStateProperty.all(0), // No shadow
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // Slightly rounded corners
                  side: const BorderSide(color: Color.fromRGBO(227, 230, 234, 1), width: 0.5), // Light grey border
                ),
              ),
              backgroundColor: WidgetStateProperty.all(Color.fromRGBO(243, 243, 245, 1)),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Align(
                          alignment: Alignment.center,
                          child: Text(category),
                        ),
                        backgroundColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                        showCheckmark: false,
                        selected: _selectedCategory == category,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategory = category;
                              _filterSigns();
                            }
                          });
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: _selectedCategory == category ? Theme.of(context).colorScheme.onPrimary : null,
                        ),
                      ),
                    );
                  },
                ),
            ),
            SizedBox(height: 10),
            // sign card

            Expanded(
              child: _filteredSigns.isEmpty 
              ? const Center(child: Text('No signs found.')) 
              : ListView.separated(
                itemCount: _filteredSigns.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10); 
                },
                itemBuilder: (context, index) {
                  final sign = _filteredSigns[index];
                  return SignCard(
                    sign: sign
                  );
                }
              )
            )
          ],
        ),
      ),
    );
  }
}