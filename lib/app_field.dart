// lib/widgets/app_field.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? inputType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.inputType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: inputType,
      obscureText:  obscure,
      validator:    validator,
      style: const TextStyle(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        prefixIcon: Icon(icon, color: AppColors.green600, size: 20),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        hintStyle:  const TextStyle(fontSize: 13, color: AppColors.textMuted),
        filled:     true,
        fillColor:  Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.green600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.red600, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.red600, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11, color: AppColors.red600),
      ),
    );
  }
}