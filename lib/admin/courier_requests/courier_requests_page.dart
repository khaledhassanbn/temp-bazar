import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'services/courier_requests_service.dart';

class CourierRequestsPage extends StatefulWidget {
  const CourierRequestsPage({super.key});

  @override
  State<CourierRequestsPage> createState() => _CourierRequestsPageState();
}

class _CourierRequestsPageState extends State<CourierRequestsPage> {
  final CourierRequestsService _service = CourierRequestsService();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authGuard = context.watch<AuthGuard>();

    // حماية الشاشة للأدمن فقط
    if (authGuard.userStatus != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('غير مصرح'),
          backgroundColor: AppColors.mainColor,
        ),
        body: const Center(
          child: Text(
            'غير مصرح لك بالوصول إلى هذه الصفحة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/dashboard');
            }
          },
        ),
        title: const Text(
          'طلبات تسجيل المناديب',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // لوحة البحث والتصفية بـ Gradient جميل
          _buildSearchAndFiltersHeader(),
          
          // قائمة الطلبات الحية
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getCourierRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;

                // تصفية البيانات محلياً للبحث والفرز السريع جداً
                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? 
                      data['fullName'] ?? 
                      data['full_name'] ?? 
                      data['userName'] ?? 
                      data['user_name'] ?? 
                      data['displayName'] ?? 
                      data['display_name'] ?? 
                      '').toString().toLowerCase();
                  final phone = (data['phone'] ?? 
                      data['phoneNumber'] ?? 
                      data['phone_number'] ?? 
                      '').toString().toLowerCase();
                  final vehicle = (data['vehicleType'] ?? 
                      data['vehicle_type'] ?? 
                      data['vehicle'] ?? 
                      '').toString().toLowerCase();
                  final status = (data['status'] ?? 'pending').toString().toLowerCase();

                  // شرط البحث
                  final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
                      phone.contains(_searchQuery.toLowerCase()) ||
                      vehicle.contains(_searchQuery.toLowerCase());

                  // شرط الفلترة
                  final matchesFilter = _selectedFilter == 'all' || status == _selectedFilter;

                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return _buildNoResultsState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    final id = doc.id;

                    return _buildCourierCard(id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFiltersHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.mainColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // حقل البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'البحث باسم المندوب أو رقم الهاتف...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.mainColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          
          // أزرار الفلترة الأنيقة
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('all', 'الكل (${_getIconForFilter('all')})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'قيد الانتظار'),
                  const SizedBox(width: 8),
                  _buildFilterChip('approved', 'مقبول'),
                  const SizedBox(width: 8),
                  _buildFilterChip('rejected', 'مرفوض'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIconForFilter(String filter) {
    switch (filter) {
      case 'pending':
        return '⏳';
      case 'approved':
        return '✅';
      case 'rejected':
        return '❌';
      default:
        return '📋';
    }
  }

  Widget _buildFilterChip(String filterType, String label) {
    final isSelected = _selectedFilter == filterType;
    Color activeColor = Colors.white;
    Color textColor = Colors.white;
    Color chipBgColor = Colors.white.withOpacity(0.2);

    if (isSelected) {
      textColor = AppColors.mainColor;
      activeColor = Colors.white;
      chipBgColor = Colors.white;
    }

    // تخصيص ألوان الحالات
    if (filterType == 'pending' && !isSelected) {
      label = '⏳ قيد الانتظار';
    } else if (filterType == 'approved' && !isSelected) {
      label = '✅ مقبول';
    } else if (filterType == 'rejected' && !isSelected) {
      label = '❌ مرفوض';
    } else if (filterType == 'pending' && isSelected) {
      label = '⏳ قيد الانتظار';
      textColor = Colors.orange[800]!;
    } else if (filterType == 'approved' && isSelected) {
      label = '✅ مقبول';
      textColor = Colors.green[800]!;
    } else if (filterType == 'rejected' && isSelected) {
      label = '❌ مرفوض';
      textColor = Colors.red[800]!;
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterType;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCourierCard(String id, Map<String, dynamic> data) {
    final name = data['name'] ?? 
        data['fullName'] ?? 
        data['full_name'] ?? 
        data['userName'] ?? 
        data['user_name'] ?? 
        data['displayName'] ?? 
        data['display_name'] ?? 
        'مندوب بدون اسم';

    final phone = data['phone'] ?? 
        data['phoneNumber'] ?? 
        data['phone_number'] ?? 
        'لا يوجد رقم هاتف';

    final vehicle = data['vehicleType'] ?? 
        data['vehicle_type'] ?? 
        data['vehicle'] ?? 
        'غير محدد';

    final status = data['status'] ?? 'pending';

    final photoUrl = data['profileImage'] ?? 
        data['personalPhoto'] ?? 
        data['personal_photo'] ?? 
        data['photoUrl'] ?? 
        data['photo_url'] ?? 
        data['personalImage'] ?? 
        data['personal_image'] ?? 
        data['image'] ?? 
        data['photo'] ?? 
        data['avatar'] ?? 
        data['avatarUrl'] ?? 
        data['avatar_url'] ?? 
        '';

    Color statusColor = Colors.orange;
    String statusText = 'قيد الانتظار';
    IconData statusIcon = Icons.hourglass_empty_rounded;

    if (status == 'approved') {
      statusColor = Colors.green;
      statusText = 'مقبول';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'مرفوض';
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push('/admin/courier-request/$id', extra: data);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // صورة الشخصية للمندوب
                  Hero(
                    tag: 'avatar_$id',
                    child: Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                key: ValueKey(photoUrl),
                                cacheKey: photoUrl,
                                imageUrl: photoUrl,
                                placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                                errorWidget: (context, url, error) => Image.asset(
                                  'assets/images/user_placeholder.png', // في حال عدم وجود صورة
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 35, color: Colors.grey),
                                ),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 35, color: Colors.grey),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // معلومات المندوب
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.directions_bike_rounded, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'المركبة: $vehicle',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // شارة الحالة (Status Badge)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: AppColors.mainColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري جلب الطلبات...',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ في تحميل البيانات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد طلبات تسجيل حتى الآن',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 8),
          Text(
            'عند تقديم طلبات تسجيل جديدة ستظهر هنا فوراً',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'لا توجد نتائج تطابق بحثك',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 8),
          Text(
            'تأكد من كتابة الاسم أو رقم الهاتف بشكل صحيح',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
