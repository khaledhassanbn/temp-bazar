import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:bazar_suez/theme/app_color.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/Onboarding Screens/one.png',
      title: 'أنشئ متجرك بسهولة',
      description:
          'يمكن للتجار إنشاء متاجرهم الإلكترونية\nوعرض منتجاتهم بطريقة احترافية.',
    ),
    OnboardingData(
      image: 'assets/images/Onboarding Screens/two.png',
      title: 'اعرض منتجاتك\nواستقبل الطلبات',
      description:
          'أضف منتجاتك وتابع الطلبات والعملاء\nمن مكان واحد.',
    ),
    OnboardingData(
      image: 'assets/images/Onboarding Screens/three.png',
      title: 'اطلب مناديب للتوصيل',
      description:
          'يمكنك طلب مناديب لتوصيل الطلبات\nومتابعة حالة التوصيل بسهولة.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _fadeController.reset();
    _slideController.reset();
    _scaleController.reset();
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go('/');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // زر التخطي
              Align(
                alignment: AlignmentDirectional.topStart,
                child: AnimatedOpacity(
                  opacity: isLastPage ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: TextButton(
                      onPressed: isLastPage ? null : _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.mainColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'تخطي',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // المحتوى الأساسي
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], size);
                  },
                ),
              ),

              // Indicator و الزر
              _buildBottomSection(isLastPage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // الصورة
          ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                height: size.height * 0.38,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(
                  data.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // العنوان
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // الوصف
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      child: Column(
        children: [
          // Page Indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: AppColors.mainColor,
              dotColor: AppColors.mainColor.withOpacity(0.2),
              dotHeight: 10,
              dotWidth: 10,
              expansionFactor: 3.5,
              spacing: 8,
            ),
          ),

          const SizedBox(height: 32),

          // الزر الرئيسي
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: SizedBox(
              key: ValueKey<bool>(isLastPage),
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLastPage
                        ? [
                            const Color(0xFF43B89C),
                            const Color(0xFF3AA68E),
                          ]
                        : [
                            AppColors.mainColor,
                            AppColors.mainColor.withBlue(200),
                          ],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isLastPage
                              ? const Color(0xFF43B89C)
                              : AppColors.mainColor)
                          .withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastPage ? 'ابدأ الآن' : 'التالي',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isLastPage ? 0.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          isLastPage
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
