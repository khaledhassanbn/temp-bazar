import 'package:bazar_suez/markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';
import 'package:bazar_suez/markets/cart/viewmodels/cart_view_model.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';
import 'package:bazar_suez/markets/grid_of_categories/ViewModel/ViewModel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/widgets/auth_gate.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _query = '';
  String? _submittedQuery;
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();

    // تحميل البيانات اللازمة للبحث
    Future.microtask(() {
      final categoryVm = context.read<CategoryViewModel>();
      if (categoryVm.categories.isEmpty) {
        categoryVm.fetchCategories();
      }

      final filterVm = context.read<CategoryFilterViewModel>();
      // Always refresh stores so availability changes appear immediately
      filterVm.fetchAllStores();
    });

    // طلب التركيز على حقل البحث بعد بناء الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _controller.addListener(() {
      setState(() {
        _query = _controller.text.trim();
        _submittedQuery = null; // عند الكتابة نرجع لوضع الاقتراحات
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(String text) {
    final q = text.trim();
    if (q.isEmpty) return;

    setState(() {
      _submittedQuery = q;
      _query = q;
      if (!_recentSearches.contains(q)) {
        _recentSearches.insert(0, q);
        if (_recentSearches.length > 10) _recentSearches.removeLast();
      }
    });
    _focusNode.unfocus();
  }

  String _normalize(String input) {
    final diacritics = RegExp('[\u064B-\u0652]');
    return input
        .replaceAll(diacritics, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .toLowerCase()
        .trim();
  }

  List<StoreModel> _filterStores(List<StoreModel> stores, String query) {
    if (query.isEmpty) return [];
    final q = _normalize(query);
    return stores.where((store) {
      final name = _normalize(store.name);
      return name.contains(q);
    }).toList();
  }

  bool _isStoreBusy(StoreModel store) => !store.available;
  bool _isStoreClosed(StoreModel store) => store.isClosedByWorkingHours;

  Widget _buildCategoryImage(String icon) {
    if (icon.isEmpty) return const SizedBox.shrink();

    // حالة الصورة من الإنترنت
    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return Image.network(
        icon,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) => const Icon(Icons.category),
      );
    }

    // حالة الصورة من التطبيق
    final imagePath = icon.startsWith('assets/')
        ? icon
        : 'assets/images/categories/$icon';

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, _, __) => const Icon(Icons.category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryVm = context.watch<CategoryViewModel>();
    final filterVm = context.watch<CategoryFilterViewModel>();

    final isTyping = _query.isNotEmpty && _submittedQuery == null;
    final showResults = _submittedQuery != null;

    final suggestions = isTyping
        ? _filterStores(filterVm.stores, _query)
        : <StoreModel>[];
    final results = showResults
        ? _filterStores(filterVm.stores, _submittedQuery!)
        : <StoreModel>[];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(context),
              const SizedBox(height: 12),
              Expanded(
                child: filterVm.isLoading && filterVm.stores.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : isTyping
                    ? _buildSuggestionsList(suggestions)
                    : showResults
                    ? _buildResultsList(results)
                    : _buildExploreContent(categoryVm, filterVm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final cartVm = context.watch<CartViewModel>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/HomePage'),
          ),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                textAlignVertical: TextAlignVertical.center,
                onSubmitted: _handleSubmit,
                decoration: InputDecoration(
                  hintText: 'ابحث عن طعامك، متاجرك، بقّالتك...',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => pushIfAuthed(
                  context,
                  '/CartPage',
                  message: 'سجّل دخولك لعرض سلة المشتريات',
                ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                if (cartVm.itemCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${cartVm.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreContent(
    CategoryViewModel categoryVm,
    CategoryFilterViewModel filterVm,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const SizedBox(height: 8),
        const Text(
          'ماذا تشتهي اليوم؟',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: categoryVm.categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final category = categoryVm.categories[index];
                    return GestureDetector(
                      onTap: () {
                        // فتح صفحة CategoryMarketPage مع categoryId
                        context.go(
                          '/CategoryMarketPage?categoryId=${category.id}',
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.center,
                            child: category.icon.isNotEmpty
                                ? _buildCategoryImage(category.icon)
                                : Text(
                                    category.name.characters.first,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 72,
                            child: Text(
                              category.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: categoryVm.categories.length,
                ),
        ),
        const SizedBox(height: 24),
        if (_recentSearches.isNotEmpty) ...[
          const Text(
            'ما بحثت عنه مؤخرًا',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches
                .map(
                  (q) => ActionChip(
                    label: Text(q),
                    avatar: const Icon(Icons.history, size: 18),
                    onPressed: () {
                      _controller.text = q;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                      _handleSubmit(q);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (filterVm.stores.isNotEmpty) ...[
          const Text(
            'المتاجر الكبرى بالقرب منك',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final store = filterVm.stores[index];
                return GestureDetector(
                  onTap: () {
                    context.go('/HomeMarketPage?marketLink=${store.id}');
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          image:
                              store.logoUrl != null && store.logoUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(store.logoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: (store.logoUrl == null || store.logoUrl!.isEmpty)
                            ? Text(
                                store.name.characters.first,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 80,
                        child: Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: filterVm.stores.length > 10
                  ? 10
                  : filterVm.stores.length,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionsList(List<StoreModel> stores) {
    if (stores.isEmpty) {
      return const Center(child: Text('لا توجد اقتراحات مطابقة حتى الآن'));
    }
    return ListView.separated(
      itemCount: stores.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final store = stores[index];
        return ListTile(
          leading: const Icon(Icons.north_east),
          title: Text(store.name),
          trailing: const Icon(Icons.search),
          onTap: () => _handleSubmit(store.name),
        );
      },
    );
  }

  Widget _buildResultsList(List<StoreModel> stores) {
    if (stores.isEmpty) {
      return const Center(child: Text('لا توجد متاجر مطابقة لبحثك'));
    }
    return ListView.separated(
      itemCount: stores.length,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final store = stores[index];
        final busy = _isStoreBusy(store);
        final closed = _isStoreClosed(store);
        final blocked = busy || closed;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.go('/HomeMarketPage?marketLink=${store.id}');
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDEDED)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: Colors.grey[200],
                          child:
                              store.logoUrl != null && store.logoUrl!.isNotEmpty
                              ? Image.network(
                                  store.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      store.name.characters.first,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    store.name.characters.first,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                        ),
                        if (blocked)
                          Container(color: Colors.black.withOpacity(0.22)),
                        if (blocked)
                          Center(
                            child: Image.asset(
                              closed
                                  ? 'assets/images/closed.png'
                                  : 'assets/images/busy.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        if (blocked) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F1DE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              closed
                                  ? 'المتجر مغلق حاليًا حسب مواعيد العمل. يمكنك تصفح المنتجات لكن لا يمكن إتمام الطلب الآن.'
                                  : 'المتجر مشغول حاليًا. يمكنك تصفح المنتجات لكن لا يمكن إتمام الطلب الآن.',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5A4A1B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
