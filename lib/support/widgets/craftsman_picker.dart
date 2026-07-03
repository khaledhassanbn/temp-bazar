import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bazar_suez/support/services/support_service.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CraftsmanPicker extends StatefulWidget {
  final String? selectedCraftsmanId;
  final Function(String id, String name) onSelected;

  const CraftsmanPicker({
    super.key,
    required this.selectedCraftsmanId,
    required this.onSelected,
  });

  @override
  State<CraftsmanPicker> createState() => _CraftsmanPickerState();
}

class _CraftsmanPickerState extends State<CraftsmanPicker> {
  final SupportService _supportService = SupportService();
  final TextEditingController _searchController = TextEditingController();
  
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _selectedName;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await _supportService.searchCraftsmen(query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ابحث عن الصنايعي المعني بالاسم أو المهنة:',
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'اكتب اسم الصنايعي أو مهنته (مثلاً: سباك، كهربائي)...',
            hintStyle: const TextStyle(fontFamily: 'NotoSansArabic', fontSize: 13, color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: AppColors.mainColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mainColor, width: 1.5),
            ),
          ),
        ),
        if (widget.selectedCraftsmanId != null && _selectedName != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.mainColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.mainColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.mainColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الصنايعي المحدد: $_selectedName',
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedName = null;
                    });
                    widget.onSelected('', '');
                  },
                  child: const Text(
                    'تغيير',
                    style: TextStyle(fontFamily: 'NotoSansArabic', color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.mainColor),
            ),
          )
        else if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                final id = item['id'] as String;
                final name = item['name'] as String;
                final profession = item['professionName'] as String;
                final imageUrl = item['imageUrl'] as String;
                final isSelected = widget.selectedCraftsmanId == id;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: imageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(imageUrl)
                        : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person, color: AppColors.mainColor)
                        : null,
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.mainColor : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    profession,
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.mainColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedName = name;
                      _searchResults = [];
                      _searchController.clear();
                    });
                    widget.onSelected(id, name);
                  },
                );
              },
            ),
          )
        else if (_searchController.text.isNotEmpty && !_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                'لا توجد نتائج مطابقة لبحثك.',
                style: TextStyle(fontFamily: 'NotoSansArabic', fontSize: 13, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }
}
