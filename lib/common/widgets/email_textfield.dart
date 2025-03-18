import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';

class EmailTextField extends StatelessWidget {
  const EmailTextField({
    super.key,
    this.prefixIcon,
    this.keyboardType,
    this.onEditingComplete,
    this.controller,
    this.hintText,
    this.labelText,
    this.floatingLabelBehavior,
    this.focusNode,
    this.initialValue,
    this.radius,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.errorText,
  });
  final String? hintText;
  final String? labelText;
  final FloatingLabelBehavior? floatingLabelBehavior;
  final double? radius;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final void Function()? onEditingComplete;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        cursorColor: Colors.black,
        textInputAction: textInputAction ?? TextInputAction.next,
        onEditingComplete: onEditingComplete,
        onFieldSubmitted: onSubmitted,
        keyboardType: keyboardType,
        initialValue: initialValue,
        controller: controller,
        onChanged: onChanged,
        validator: validator,
        focusNode: focusNode,
        style: appStyle(14, Kolors.kDark, FontWeight.normal),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText ?? hintText,
          floatingLabelBehavior: floatingLabelBehavior ?? FloatingLabelBehavior.auto,
          prefixIcon: prefixIcon,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          
          hintStyle: appStyle(14, Kolors.kGray, FontWeight.normal),
          labelStyle: appStyle(14, Kolors.kGray, FontWeight.normal),
          
          floatingLabelStyle: appStyle(14, Kolors.kPrimary, FontWeight.normal),
          
          errorText: errorText,
          errorStyle: appStyle(12, Colors.red, FontWeight.normal),
          
          errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 0.5),
              borderRadius: BorderRadius.all(Radius.circular(radius??12))),
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Kolors.kPrimary, width: 1.0),
              borderRadius: BorderRadius.all(Radius.circular(radius??12))),
          focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 0.5),
              borderRadius: BorderRadius.all(Radius.circular(radius??12))),
          disabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Kolors.kGray, width: 0.5),
              borderRadius: BorderRadius.all(Radius.circular(radius??12))),
          enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Kolors.kGray, width: 0.5),
              borderRadius: BorderRadius.all(Radius.circular(radius??12))),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Kolors.kPrimary, width: 0.5),
            borderRadius: BorderRadius.all(
              Radius.circular(radius??12),
            ),
          ),
        ));
  }
}
