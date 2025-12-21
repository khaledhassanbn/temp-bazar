import 'package:flutter/material.dart';
import 'uploadCategories.dart';

class UploadCategoriesPage extends StatefulWidget {
  const UploadCategoriesPage({super.key});

  @override
  State<UploadCategoriesPage> createState() => _UploadCategoriesPageState();
}

class _UploadCategoriesPageState extends State<UploadCategoriesPage> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _uploadCategories() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري رفع الفئات...';
    });

    try {
      await uploadCategories();
      setState(() {
        _statusMessage = '✅ تم رفع جميع الفئات بنجاح!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ حدث خطأ: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفع الفئات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'رفع فئات المتاجر (رئيسية → فرعية → متاجر)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('✅')
                      ? Colors.green.shade100
                      : _statusMessage.contains('❌')
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('✅')
                        ? Colors.green
                        : _statusMessage.contains('❌')
                            ? Colors.red
                            : Colors.blue,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('✅')
                        ? Colors.green.shade800
                        : _statusMessage.contains('❌')
                            ? Colors.red.shade800
                            : Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadCategories,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upload),
              label: Text(_isLoading ? 'جاري الرفع...' : 'رفع الفئات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '⚠️ تأكد من اتصالك بالإنترنت وأن Firebase مُعد بشكل صحيح',
              style: TextStyle(color: Colors.orange, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
