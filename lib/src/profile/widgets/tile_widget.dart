import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';

class ProfileTileWidget extends StatelessWidget {
  const ProfileTileWidget({super.key, required this.title, this.onTap, required this.leading});

  final String title;
  final void Function()? onTap;
  final IconData leading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      onTap: onTap,
      leading: Icon(leading, color: Kolors.kGray,),
      title: Text(title, style: appStyle(13, Kolors.kDark, FontWeight.normal),),
      trailing: const Icon(
        AntDesign.right,
        size: 16,
        color: Kolors.kDark
      ),
    );
  }
}