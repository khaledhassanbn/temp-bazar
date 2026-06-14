import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/craftsmen/data/craftsman_categories.dart';
import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_analytics_service.dart';
import 'package:bazar_suez/craftsmen/viewmodels/craftsmen_list_viewmodel.dart';
import 'package:bazar_suez/markets/saved_locations/viewmodels/saved_locations_viewmodel.dart';
import 'package:bazar_suez/markets/saved_locations/widgets/saved_locations_sheet.dart';
import 'package:bazar_suez/widgets/auth_gate.dart';

class CraftsmenHomePage extends StatefulWidget {
  const CraftsmenHomePage({super.key});

  @override
  State<CraftsmenHomePage> createState() => _CraftsmenHomePageState();
}

class _CraftsmenHomePageState extends State<CraftsmenHomePage> {
  CraftsmenListViewModel? _categoryVm;
  GeoPoint? _lastLoc;
  bool _initialized = false;
  String? _selectedGroupId;
  bool _isCraftsman = false; // لمعرفة إذا كان المستخدم صنايعي
  bool _checkingCraftsmanStatus = true; // للتحقق من حالة المستخدم

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locationVm = Provider.of<SavedLocationsViewModel>(context);
    final activeLoc = locationVm.activeLocation;

    if (!_initialized || _lastLoc != activeLoc) {
      _lastLoc = activeLoc;
      _initialized = true;
    }
    
    // التحقق من حالة الصنايعي
    if (_checkingCraftsmanStatus) {
      _checkCraftsmanStatus();
    }
  }

  Future<void> _checkCraftsmanStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isCraftsman = false;
          _checkingCraftsmanStatus = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      bool isCraftsman = data?['craftsmanProfileActive'] == true ||
          data?['isCraftsman'] == true ||
          data?['craftsmanProfileId'] != null;
      
      if (!isCraftsman) {
        // التحقق المباشر من قاعدة بيانات الصنايعية
        final craftsmanDoc = await FirebaseFirestore.instance.collection('craftsmen').doc(user.uid).get();
        if (craftsmanDoc.exists) {
          isCraftsman = true;
          // مزامنة الحقل في مستند المستخدم لضمان الاتساق
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'craftsmanProfileActive': true},
            SetOptions(merge: true),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isCraftsman = isCraftsman;
          _checkingCraftsmanStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCraftsman = false;
          _checkingCraftsmanStatus = false;
        });
      }
    }
  }

  Future<void> _selectCategory(String groupId) async {
    if (_selectedGroupId == groupId) return;
    
    setState(() {
      _selectedGroupId = groupId;
      _categoryVm = CraftsmenListViewModel(
        initialFilters: CraftsmanFilterOptions(
          groupId: groupId,
          sortBy: CraftsmanSortBy.distance,
          sortAscending: true,
        ),
      );
    });
    
    await _categoryVm!.load();
  }

  void _showSubCategoryBottomSheet() {
    if (_selectedGroupId == null) return;
    
    final group = kCraftsmanCategoryGroups.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => kCraftsmanCategoryGroups.first,
    );
    
    String? selectedProfessionId = _categoryVm?.filters.professionId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    16 + MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                          const Expanded(
                            child: Text(
                              'الفئات الفرعية',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                onTap: () => setSheetState(() => selectedProfessionId = null),
                                title: const Text(
                                  'كل المهن',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Radio<String?>(
                                  value: null,
                                  groupValue: selectedProfessionId,
                                  onChanged: (_) =>
                                      setSheetState(() => selectedProfessionId = null),
                                  activeColor: const Color(0xFF4E99B4),
                                ),
                              ),
                              const Divider(height: 1),
                              ...group.professions.map((prof) {
                                return Column(
                                  children: [
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 6),
                                      onTap: () =>
                                          setSheetState(() => selectedProfessionId = prof.id),
                                      title: Text(
                                        prof.nameAr,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      trailing: Radio<String?>(
                                        value: prof.id,
                                        groupValue: selectedProfessionId,
                                        onChanged: (_) => setSheetState(
                                          () => selectedProfessionId = prof.id,
                                        ),
                                        activeColor: const Color(0xFF4E99B4),
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4E99B4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            if (_categoryVm != null) {
                              _categoryVm!.applyFilters(
                                _categoryVm!.filters.copyWith(
                                  professionId: selectedProfessionId,
                                  groupId: _selectedGroupId,
                                ),
                              );
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'تطبيق',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleFabTap(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      pushIfAuthed(
        context,
        '/craftsmen/register',
        message: 'سجّل دخولك لإنشاء ملف صنايعي وعرض خدماتك',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final data = doc.data();
      final isCraftsman = data?['craftsmanProfileActive'] == true ||
          data?['isCraftsman'] == true ||
          data?['craftsmanProfileId'] != null;

      if (isCraftsman) {
        context.push('/craftsmen/dashboard');
      } else {
        context.push('/craftsmen/register');
      }
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      context.push('/craftsmen/register');
    }
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'plumbing':
        return Icons.plumbing;
      case 'carpenter':
        return Icons.carpenter;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'kitchen':
        return Icons.kitchen;
      case 'videocam':
        return Icons.videocam;
      case 'yard':
        return Icons.yard;
      case 'build':
        return Icons.build;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'person':
        return Icons.person;
      default:
        return Icons.home_work;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F7),
        body: RefreshIndicator(
          onRefresh: () async {
            if (_categoryVm != null) await _categoryVm!.load();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // الهيدر المتدرج
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4E99B4), Color(0xFF2A7A95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          // Location
                          Consumer<SavedLocationsViewModel>(
                            builder: (context, locationVm, _) {
                              final isBusy = locationVm.isInitializing || locationVm.isLoading;
                              final title = isBusy ? 'جاري تحديد الموقع...' : locationVm.displayAddress;
                              return GestureDetector(
                                onTap: () {
                                  if (FirebaseAuth.instance.currentUser != null) {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => const SavedLocationsSheet(),
                                    );
                                    return;
                                  }
                                  showAuthBottomSheet(
                                    context,
                                    message: 'سجّل دخولك لحفظ عناوين التوصيل وتحديد موقعك',
                                    onAuthenticated: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => const SavedLocationsSheet(),
                                      );
                                    },
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isBusy)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    else
                                      const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Search Bar
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.push('/craftsmen/categories'),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.category,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        context.push('/craftsmen/browse?q=${Uri.encodeComponent(value.trim())}');
                                      } else {
                                        context.push('/craftsmen/browse');
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'ابحث عن صنايعي أو خدمة...',
                                      hintStyle: GoogleFonts.cairo(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // المساحة الإعلانية كصورة
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/adsmarket.jpg',
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Services Section - الفئات
                    _buildSectionHeader(
                      'الفئات',
                      Icons.category,
                      onSeeAll: () => context.push('/craftsmen/categories'),
                    ),
                    
                    // Grid للفئات مثل HomePage
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: kCraftsmanCategoryGroups.length,
                        itemBuilder: (context, i) {
                          final g = kCraftsmanCategoryGroups[i];
                          final isSelected = _selectedGroupId == g.id;
                          return _CategoryCard(
                            group: g,
                            isSelected: isSelected,
                            onTap: () => _selectCategory(g.id),
                            icon: _iconFor(g.iconName),
                          );
                        },
                      ),
                    ),

                    // الصنايعية حسب الفئة المختارة
                    if (_selectedGroupId != null && _categoryVm != null) ...[
                      const SizedBox(height: 24),
                      
                      // الفلاتر
                      _buildCraftsmenFilterBar(),
                      
                      const SizedBox(height: 12),
                      
                      // عنوان المتاجر
                      _buildSectionHeader(
                        'الصنايعية',
                        Icons.handyman,
                        onSeeAll: () => context.push('/craftsmen/browse?groupId=$_selectedGroupId'),
                      ),
                      
                      // قائمة الصنايعية
                      ListenableBuilder(
                        listenable: _categoryVm!,
                        builder: (context, _) {
                          if (_categoryVm!.isLoading) {
                            return const SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4E99B4),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          
                          if (_categoryVm!.error != null) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  _categoryVm!.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          }
                          
                          if (_categoryVm!.results.isEmpty) {
                            return const SizedBox(
                              height: 160,
                              child: Center(
                                child: Text(
                                  'لا توجد صنايعية في هذه الفئة',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          final results = _categoryVm!.results.take(8).toList();
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              children: results.map((r) => _CraftsmanCard(result: r)).toList(),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),

        // FAB - يظهر فقط إذا لم يكن المستخدم صنايعي
        floatingActionButton: _isCraftsman
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _handleFabTap(context),
                backgroundColor: const Color(0xFF4E99B4),
                icon: const Icon(Icons.handyman, color: Colors.white),
                label: Text(
                  'اضف صنايعى',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                ),
                elevation: 8,
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4E99B4), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'عرض الكل',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4E99B4)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCraftsmenFilterBar() {
    if (_categoryVm == null) return const SizedBox.shrink();
    
    return ListenableBuilder(
      listenable: _categoryVm!,
      builder: (context, _) {
        final filters = _categoryVm!.filters;
        final hasProfession = filters.professionId != null;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: hasProfession ? 'الفئات الفرعية ✓' : 'الفئات الفرعية',
                  selected: hasProfession,
                  onTap: _showSubCategoryBottomSheet,
                ),
                const SizedBox(width: 6),
                _FilterChipButton(
                  label: 'الأقرب',
                  selected: filters.sortBy == CraftsmanSortBy.distance,
                  onTap: () {
                    _categoryVm!.applyFilters(
                      filters.copyWith(sortBy: CraftsmanSortBy.distance, sortAscending: true),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _FilterChipButton(
                  label: 'الأعلى تقييماً',
                  selected: filters.sortBy == CraftsmanSortBy.rating,
                  onTap: () {
                    _categoryVm!.applyFilters(
                      filters.copyWith(sortBy: CraftsmanSortBy.rating, sortAscending: false),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _FilterChipButton(
                  label: 'الأكثر تواصلاً',
                  selected: filters.sortBy == CraftsmanSortBy.contactCount,
                  onTap: () {
                    _categoryVm!.applyFilters(
                      filters.copyWith(sortBy: CraftsmanSortBy.contactCount, sortAscending: false),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _FilterChipButton(
                  label: 'الأحدث',
                  selected: filters.sortBy == CraftsmanSortBy.newest,
                  onTap: () {
                    _categoryVm!.applyFilters(
                      filters.copyWith(sortBy: CraftsmanSortBy.newest, sortAscending: false),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _FilterChipButton(
                  label: 'تقييم 4.0+',
                  selected: filters.minRating >= 4.0,
                  onTap: () {
                    _categoryVm!.applyFilters(
                      filters.copyWith(minRating: filters.minRating >= 4.0 ? 0 : 4.0),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _FilterChipButton(
                  label: 'الافتراضي',
                  selected: filters.sortBy == CraftsmanSortBy.distance && filters.minRating == 0 && filters.professionId == null,
                  onTap: () {
                    _categoryVm!.applyFilters(
                      CraftsmanFilterOptions(
                        groupId: _selectedGroupId,
                        sortBy: CraftsmanSortBy.distance,
                        sortAscending: true,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Category Card Widget
class _CategoryCard extends StatelessWidget {
  final CraftsmanCategoryGroup group;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _CategoryCard({
    required this.group,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4E99B4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4E99B4)
                : const Color(0xFF4E99B4).withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4E99B4).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF4E99B4),
              size: 32,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                group.nameAr,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Chip Button
class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4E99B4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF4E99B4)
                : const Color(0xFF4E99B4).withOpacity(0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF4E99B4),
          ),
        ),
      ),
    );
  }
}

// Craftsman Card
class _CraftsmanCard extends StatelessWidget {
  final CraftsmanSearchResult result;

  const _CraftsmanCard({
    required this.result,
  });

  Color _getColorForCraftsman(String id) {
    final colors = [
      const Color(0xFF2A7A95),
      const Color(0xFF5E3A8C),
      const Color(0xFF1B5E20),
      const Color(0xFFD84315),
      const Color(0xFF00838F),
      const Color(0xFFAD1457),
    ];
    final hash = id.hashCode.abs();
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final c = result.craftsman;
    final color = _getColorForCraftsman(c.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/craftsmen/${c.id}'),
          child: Column(
            children: [
              // Cover
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover image or gradient fallback
                    if (c.coverImageUrl != null && c.coverImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: CachedNetworkImage(
                          imageUrl: c.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.9), color],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.9), color],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.9), color],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                      ),
                    // Dark overlay when cover image exists for better text readability
                    if (c.coverImageUrl != null && c.coverImageUrl!.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.35),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                      ),
                    if (c.isFeatured)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.black87),
                              SizedBox(width: 4),
                              Text('مميز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: -28,
                      right: 16,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFEAF6FB),
                          backgroundImage: c.photoUrl != null && c.photoUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(c.photoUrl!)
                              : null,
                          child: c.photoUrl == null || c.photoUrl!.isEmpty
                              ? Text(
                                  c.name.isNotEmpty ? c.name[0] : '?',
                                  style: GoogleFonts.cairo(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(
                      c.professionName,
                      style: GoogleFonts.cairo(fontSize: 13.5, color: color, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              c.averageRating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(' (${c.totalReviews})', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        if (result.distanceKm != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFE53935), size: 17),
                              const SizedBox(width: 4),
                              Text(result.distanceText),
                            ],
                          )
                        else if (c.areaName != null && c.areaName!.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFE53935), size: 17),
                              const SizedBox(width: 4),
                              Text(c.areaName!),
                            ],
                          ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Color(0xFF4E99B4), size: 17),
                            const SizedBox(width: 4),
                            Text('${result.totalContacts} تواصل'),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _iconActionButton(
                          icon: Icons.phone,
                          color: const Color(0xFF2A7A95),
                          bgColor: const Color(0xFFEAF6FB),
                          onTap: () {
                            CraftsmanAnalyticsService().logContact(
                              craftsmanId: c.id,
                              channel: ContactChannel.call,
                              phone: c.phone,
                              whatsapp: c.whatsapp,
                            );
                          },
                        ),
                        _iconActionButton(
                          icon: Icons.message,
                          color: const Color(0xFF25D366),
                          bgColor: const Color(0xFFE8F5E9),
                          onTap: () {
                            CraftsmanAnalyticsService().logContact(
                              craftsmanId: c.id,
                              channel: ContactChannel.whatsapp,
                              phone: c.phone,
                              whatsapp: c.whatsapp,
                            );
                          },
                        ),
                        _iconActionButton(
                          icon: Icons.person,
                          color: Colors.white,
                          bgColor: color,
                          onTap: () {
                            context.push('/craftsmen/${c.id}');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}