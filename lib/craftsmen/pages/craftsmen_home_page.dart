import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/craftsmen/data/craftsman_categories.dart';
import 'package:bazar_suez/markets/saved_locations/viewmodels/saved_locations_viewmodel.dart';
import 'package:bazar_suez/markets/saved_locations/widgets/saved_locations_sheet.dart';
import 'package:bazar_suez/widgets/auth_gate.dart';

class CraftsmenHomePage extends StatefulWidget {
  const CraftsmenHomePage({super.key});

  @override
  State<CraftsmenHomePage> createState() => _CraftsmenHomePageState();
}

class _CraftsmenHomePageState extends State<CraftsmenHomePage> {
  bool _isCraftsman = false;
  bool _checkingCraftsmanStatus = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  void _openCategory(String groupId) {
    context.push('/CraftsmenCategoryPage?groupId=$groupId');
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
        body: CustomScrollView(
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
                          return _CategoryCard(
                            group: g,
                            onTap: () => _openCategory(g.id),
                            icon: _iconFor(g.iconName),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
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
}

// Category Card Widget
class _CategoryCard extends StatelessWidget {
  final CraftsmanCategoryGroup group;
  final VoidCallback onTap;
  final IconData icon;

  const _CategoryCard({
    required this.group,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4E99B4).withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFF4E99B4),
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
                  color: Colors.black87,
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