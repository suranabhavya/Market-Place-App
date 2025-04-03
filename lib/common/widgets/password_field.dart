import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/src/auth/controllers/password_notifier.dart';
import 'package:provider/provider.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.radius,
    this.hintText,
    this.onEditingComplete,
    this.onChanged,
    this.validator,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final double? radius;
  final String? hintText;
  final void Function()? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordNotifier>(
      builder: (context, passwordNotifier, child) {
        return TextFormField(
          cursorColor: Colors.black,
          textInputAction: widget.textInputAction ?? TextInputAction.next,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.visiblePassword,
          controller: widget.controller,
          obscureText: _isObscured,
          onEditingComplete: widget.onEditingComplete,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator ?? (value) {
            if (value == null || value.isEmpty) {
              return "Please enter a valid password";
            } else {
              return null;
            }
          },
          style: appStyle(14, Kolors.kDark, FontWeight.normal),
          decoration: InputDecoration(
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              },
              child: Icon(
                _isObscured
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Kolors.kGrayLight,
              ),
            ),
            hintText: widget.hintText,
            prefixIcon: const Icon(
              CupertinoIcons.lock_circle,
              size: 26,
              color: Kolors.kGray,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            hintStyle: appStyle(14, Kolors.kGray, FontWeight.normal),
            
            errorText: widget.errorText,
            errorStyle: appStyle(12, Colors.red, FontWeight.normal),
            
            errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Kolors.kPrimary, width: 1.0),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            disabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Kolors.kGray, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Kolors.kGray, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: Kolors.kPrimary, width: 0.5),
              borderRadius: BorderRadius.all(
                Radius.circular(widget.radius??12),
              ),
            ),
          ),
        );
      },
    );
  }
}
