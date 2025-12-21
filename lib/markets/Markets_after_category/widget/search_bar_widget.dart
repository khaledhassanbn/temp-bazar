import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final List<String> suggestions;

  const SearchBarWidget({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return TextField(
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(fontSize: 16, color: Colors.black54),
        // ✅ استخدمنا hint بدل label للتحكم الكامل في المحاذاة والمسافة
        hint: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "ابحث عن ",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            // ✅ قللنا المسافة جدًا بين النص والكلمة المتغيرة
            Flexible(child: _TypingText(words: suggestions)),
          ],
        ),
      ),
    );
  }
}

class _TypingText extends StatefulWidget {
  final List<String> words;

  const _TypingText({required this.words});

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> {
  late String _displayedText;
  int _wordIndex = 0;
  bool _isDeleting = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _displayedText = "";
    // فقط ابدأ التأثير إذا كانت هناك كلمات متاحة
    if (widget.words.isNotEmpty) {
      _startTypingEffect();
    }
  }

  Future<void> _startTypingEffect() async {
    // التحقق من وجود كلمات قبل البدء
    if (widget.words.isEmpty) {
      return;
    }

    while (!_disposed) {
      // ⏱️ سرعة الكتابة والحذف
      await Future.delayed(Duration(milliseconds: _isDeleting ? 100 : 130));

      if (_disposed) break;

      // التحقق مرة أخرى من وجود كلمات
      if (widget.words.isEmpty) {
        break;
      }

      setState(() {
        final currentWord = widget.words[_wordIndex];

        if (_isDeleting) {
          if (_displayedText.isNotEmpty) {
            _displayedText = currentWord.substring(
              0,
              _displayedText.length - 1,
            );
          } else {
            _isDeleting = false;
            _wordIndex = (_wordIndex + 1) % widget.words.length;
          }
        } else {
          if (_displayedText.length < currentWord.length) {
            _displayedText = currentWord.substring(
              0,
              _displayedText.length + 1,
            );
          } else {
            // ✅ انتظر ثانيتين بعد كتابة الكلمة
            Future.delayed(const Duration(seconds: 1)).then((_) {
              if (mounted) {
                setState(() {
                  _isDeleting = true;
                });
              }
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إذا كانت القائمة فارغة، اعرض نص ثابت
    if (widget.words.isEmpty) {
      return const Text(
        "منتجات",
        style: TextStyle(fontSize: 16, color: Colors.black54),
        maxLines: 1,
        overflow: TextOverflow.clip,
      );
    }

    return Text(
      _displayedText,
      style: const TextStyle(fontSize: 16, color: Colors.black54),
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }
}
