import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _launchGoogleForm() async {
  final Uri url = Uri.parse('https://forms.gle/3fmFBd5qdLHkM8Eq9');
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

Future<dynamic> showHelpCenterBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sublyst Help Center',
                    style: appStyle(
                      18.0,
                      Kolors.kPrimary,
                      FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Information Section
                      Text(
                        'We\'d love to hear from you! Please use the feedback form to suggest a feature, report a bug, or share any feedback. Your input helps us make Sublyst better.',
                        style: appStyle(16.0, Kolors.kDark, FontWeight.normal),
                      ),
                      SizedBox(height: 25.h),

                      // Feedback Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _launchGoogleForm();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open feedback form. Please try again later.'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            MaterialCommunityIcons.form_select,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Open Feedback Form',
                            style: appStyle(16.0, Colors.white, FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Kolors.kPrimary,
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25.h),

                      // Help sections
                      Text(
                        'What can you do in the feedback form?',
                        style: appStyle(16.0, Kolors.kDark, FontWeight.bold),
                      ),
                      SizedBox(height: 15.h),

                      _buildHelpItem(
                        icon: MaterialCommunityIcons.lightbulb_outline,
                        title: 'Suggest a Feature',
                        description: 'Share your ideas for new features that would make Sublyst better.',
                      ),
                      SizedBox(height: 15.h),

                      _buildHelpItem(
                        icon: MaterialCommunityIcons.bug_outline,
                        title: 'Report a Bug',
                        description: 'Found something that\'s not working? Let us know so we can fix it.',
                      ),
                      SizedBox(height: 15.h),

                      _buildHelpItem(
                        icon: MaterialCommunityIcons.message_outline,
                        title: 'General Feedback',
                        description: 'Share your overall experience and thoughts about the app.',
                      ),
                      SizedBox(height: 30.h),
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

Widget _buildHelpItem({
  required IconData icon,
  required String title,
  required String description,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Kolors.kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          icon,
          color: Kolors.kPrimary,
          size: 20.0,
        ),
      ),
      const SizedBox(width: 12.0),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: appStyle(14.0, Kolors.kDark, FontWeight.w600),
            ),
            const SizedBox(height: 4.0),
            Text(
              description,
              style: appStyle(13.0, Kolors.kGray, FontWeight.normal),
            ),
          ],
        ),
      ),
    ],
  );
}
