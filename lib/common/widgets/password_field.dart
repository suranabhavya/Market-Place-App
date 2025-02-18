import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/src/auth/controllers/password_notifier.dart';
import 'package:provider/provider.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    Key? key,
    required this.controller,
    this.focusNode, this.radius, this.hintText
  }) : super(key: key);

  final TextEditingController controller;
  final FocusNode? focusNode;
  final double? radius;
  final String? hintText;

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
          textInputAction: TextInputAction.next,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.visiblePassword,
          controller: widget.controller,
          obscureText: _isObscured,
          validator: (value) {
            if (value!.isEmpty) {
              return "Please enter a valid password";
            } else {
              return null;
            }
          },
          style: appStyle(12, Kolors.kDark, FontWeight.normal),
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
              color: Kolors.kGrayLight,
              size: 26,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.all(6),
            hintStyle: appStyle(12, Kolors.kGray, FontWeight.normal),
            // contentPadding: EdgeInsets.only(left: 24),
            errorBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            focusedBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Kolors.kPrimary, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            focusedErrorBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Kolors.kRed, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            disabledBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Kolors.kGray, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            enabledBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Kolors.kGray, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(widget.radius??12))),
            border:  OutlineInputBorder(
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
