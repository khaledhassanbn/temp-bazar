import 'package:flutter/material.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import 'section_title_widget.dart';
import 'edit_text_field.dart';
import 'package:bazar_suez/theme/app_color.dart';

class ContactInfoSection extends StatelessWidget {
  final EditStoreViewModel viewModel;
  final TextEditingController phoneController;
  final TextEditingController facebookController;
  final TextEditingController instagramController;

  const ContactInfoSection({
    Key? key,
    required this.viewModel,
    required this.phoneController,
    required this.facebookController,
    required this.instagramController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitleWidget(title: 'رقم الهاتف (واتساب)'),
        EditTextField(
          hint: '+20...',
          keyboardType: TextInputType.phone,
          required: true,
          controller: phoneController,
          onChanged: viewModel.setPhone,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'فيسبوك',
                        style: TextStyle(
                          color: AppColors.mainColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    EditTextField(
                      hint: 'https://facebook.com/...',
                      controller: facebookController,
                      onChanged: viewModel.setFacebook,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'انستجرام',
                        style: TextStyle(
                          color: AppColors.mainColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    EditTextField(
                      hint: 'https://instagram.com/...',
                      controller: instagramController,
                      onChanged: viewModel.setInstagram,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
