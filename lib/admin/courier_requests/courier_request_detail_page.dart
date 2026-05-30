import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'services/courier_requests_service.dart';

class CourierRequestDetailPage extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic>? initialData;

  const CourierRequestDetailPage({
    super.key,
    required this.requestId,
    this.initialData,
  });

  @override
  State<CourierRequestDetailPage> createState() => _CourierRequestDetailPageState();
}

class _CourierRequestDetailPageState extends State<CourierRequestDetailPage> {
  final CourierRequestsService _service = CourierRequestsService();
  bool _isProcessing = false;

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
          child: Text('غير مصرح لك بالوصول إلى هذه الصفحة'),
        ),
      );
    }

    // استخدام StreamBuilder للحصول على تحديثات فورية من Firestore
    // عند تعديل المندوب لبياناته وإعادة الإرسال، ستظهر التغييرات تلقائياً
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('courier_requests')
          .doc(widget.requestId)
          .snapshots(),
      builder: (context, snapshot) {
        // لا نعتمد على initialData - فقط على Stream الحي
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.mainColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('خطأ')),
            body: Center(child: Text('حدث خطأ: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('خطأ')),
            body: const Center(child: Text('لم يتم العثور على الطلب')),
          );
        }

        final data = snapshot.data!.data();
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('خطأ')),
            body: const Center(child: Text('بيانات الطلب فارغة')),
          );
        }

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

        final personalPhoto = data['profileImage'] ?? 
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

        final nationalIdPhoto = data['nationalIdImage'] ?? 
            data['nationalIdPhoto'] ?? 
            data['national_id_photo'] ?? 
            data['idCardPhoto'] ?? 
            data['id_card_photo'] ?? 
            data['national_id_image'] ?? 
            data['idCardImage'] ?? 
            data['id_card_image'] ?? 
            data['nationalId'] ?? 
            data['national_id'] ?? 
            data['idCard'] ?? 
            data['id_card'] ?? 
            '';

        final licensePhoto = data['vehicleLicenseImage'] ?? 
            data['licensePhoto'] ?? 
            data['license_photo'] ?? 
            data['licenseImage'] ?? 
            data['license_image'] ?? 
            data['drivingLicense'] ?? 
            data['driving_license'] ?? 
            data['license'] ?? 
            data['drivingLicensePhoto'] ?? 
            data['driving_license_photo'] ?? 
            '';

        final rejectionReason = data['rejectionReason'] ?? 
            data['rejection_reason'] ?? 
            '';
        final createdAt = data['createdAt'] as Timestamp?;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: Colors.grey[50],
              body: CustomScrollView(
                slivers: [
                  // App Bar تفاعلي مع خلفية متدرجة وتأثير Hero للصورة الشخصية
                  _buildSliverAppBar(context, name, status, personalPhoto),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100), // مساحة إضافية للأزرار العائمة
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // شارة تفاصيل الحالة الحالية للطلب
                          _buildStatusCard(status, rejectionReason),
                          const SizedBox(height: 20),

                          // قسم البيانات الشخصية
                          _buildSectionTitle('البيانات الشخصية', Icons.person_outline),
                          const SizedBox(height: 10),
                          _buildDetailsCard([
                            _buildDetailItem('الاسم الكامل', name, Icons.badge_outlined),
                            _buildDetailItem('رقم الهاتف', phone, Icons.phone_android_outlined, isPhone: true),
                            _buildDetailItem('نوع المركبة', vehicle, Icons.directions_bike_rounded),
                            if (createdAt != null)
                              _buildDetailItem(
                                'تاريخ التقديم',
                                _formatTimestamp(createdAt),
                                Icons.calendar_month_outlined,
                              ),
                          ]),
                          const SizedBox(height: 24),

                          // قسم المستندات والوثائق المرفقة
                          _buildSectionTitle('المستندات والوثائق المرفقة', Icons.file_present_rounded),
                          const SizedBox(height: 12),
                          const Text(
                            'اضغط على أي صورة لعرضها بملء الشاشة مع إمكانية التكبير والتصغير للتحقق من البيانات.',
                            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 16),

                          // بطاقات المستندات
                          _buildDocumentItem('صورة بطاقة الرقم القومي (ID Card)', nationalIdPhoto, context),
                          const SizedBox(height: 16),
                          _buildDocumentItem('صورة رخصة القيادة (Driving License)', licensePhoto, context, isOptional: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: status == 'pending'
                  ? _buildActionsBottomBar(context, name)
                  : _buildProcessedBottomBar(context, status),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.mainColor),
                          const SizedBox(height: 16),
                          const Text(
                            'جاري تحديث حالة الطلب...',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String name, String status, String photoUrl) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.mainColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // خلفية متدرجة حديثة
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.mainColor,
                    Color(0xFF336C80),
                  ],
                ),
              ),
            ),
            // دوائر زينة خلفية
            Positioned(
              right: -30,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // صورة المندوب الشخصية الكبيرة
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Hero(
                    tag: 'avatar_${widget.requestId}',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                        child: ClipOval(
                        child: photoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                key: ValueKey(photoUrl),
                                cacheKey: photoUrl,
                                imageUrl: photoUrl,
                                placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.person, size: 55, color: Colors.grey),
                                ),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 55, color: Colors.grey),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, String rejectionReason) {
    Color statusColor = Colors.orange;
    String statusTitle = 'بانتظار المراجعة والقرار';
    String statusDesc = 'هذا الطلب لم يتم اتخاذ أي إجراء بشأنه بعد. يرجى فحص المستندات بعناية.';
    IconData statusIcon = Icons.pending_actions_rounded;

    if (status == 'approved') {
      statusColor = Colors.green;
      statusTitle = 'طلب مقبول بالكامل';
      statusDesc = 'تمت الموافقة على هذا المندوب بنجاح وتم تفعيل حسابه للعمل في التطبيق.';
      statusIcon = Icons.verified_rounded;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusTitle = 'طلب مرفوض';
      statusDesc = 'تم رفض هذا الطلب من قبل الإدارة.';
      statusIcon = Icons.gpp_bad_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                statusTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            statusDesc,
            style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4),
          ),
          if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سبب الرفض المكتوب:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rejectionReason,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.mainColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index < items.length - 1)
                Divider(height: 1, color: Colors.grey[100], indent: 50),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.grey[600], size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  textDirection: isPhone ? TextDirection.ltr : null,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String title, String photoUrl, BuildContext context, {bool isOptional = false}) {
    final hasImage = photoUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان المستند
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                if (isOptional && !hasImage)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'اختياري (غير متوفر)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          
          // عرض المستند
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: hasImage
                  ? InkWell(
                      onTap: () => _openInteractiveImage(context, photoUrl, title),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                            ),
                            child: CachedNetworkImage(
                              key: ValueKey(photoUrl),
                              cacheKey: photoUrl,
                              imageUrl: photoUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(color: AppColors.mainColor),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('فشل تحميل الصورة', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // تأثير تراكب شفاف ورمز تكبير الصورة
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.no_photography_outlined, size: 36, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'لم يتم إرفاق هذا المستند',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openInteractiveImage(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.95),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                key: ValueKey(imageUrl),
                cacheKey: imageUrl,
                imageUrl: imageUrl,
                placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.white),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionsBottomBar(BuildContext context, String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الرفض
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'رفض الطلب',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // زر القبول
          Expanded(
            child: ElevatedButton(
              onPressed: () => _confirmApproval(context, name),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 3,
                shadowColor: Colors.green.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'قبول المندوب',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedBottomBar(BuildContext context, String status) {
    final isApproved = status == 'approved';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: () {
          // السماح بتغيير القرار من مقبول لمرفوض أو العكس لمرونة كاملة
          if (isApproved) {
            _showRejectDialog(context);
          } else {
            _confirmApproval(context, '');
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.mainColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppColors.mainColor),
            const SizedBox(width: 8),
            Text(
              isApproved ? 'تغيير القرار إلى رفض الطلب' : 'تغيير القرار إلى قبول المندوب',
              style: const TextStyle(
                color: AppColors.mainColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApproval(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تأكيد قبول المندوب', textAlign: TextAlign.right),
          content: Text(
            'هل أنت متأكد من رغبتك في قبول المندوب وتفعيل حسابه للعمل في التطبيق؟',
            textAlign: TextAlign.right,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _executeApprove();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('قبول وتفعيل'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeApprove() async {
    setState(() => _isProcessing = true);
    try {
      await _service.approveRequest(widget.requestId);
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم قبول المندوب بنجاح وتفعيل حسابه.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في قبول المندوب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('رفض طلب التسجيل', textAlign: TextAlign.right),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'يرجى كتابة سبب رفض الطلب بالتفصيل ليتم إرساله وتوضيحه للمندوب.',
                  style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'مثال: صورة البطاقة غير واضحة أو منتهية الصلاحية...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.mainColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى كتابة سبب الرفض';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final reason = controller.text.trim();
                  Navigator.of(context).pop();
                  _executeReject(reason);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تأكيد الرفض'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeReject(String reason) async {
    setState(() => _isProcessing = true);
    try {
      await _service.rejectRequest(widget.requestId, reason);
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم رفض الطلب بنجاح مع حفظ السبب: "$reason"'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في رفض الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}/${date.month}/${date.day} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
