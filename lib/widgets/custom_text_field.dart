import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

// ignore: must_be_immutable
class CustomTextField extends StatelessWidget {
  CustomTextField({
    super.key,
    this.maxLength,
    this.focusNode,
    this.obscureText,
    this.keyboardType,
    this.textInputAction,
    this.onSaved,
    this.onChanged,
    this.validator,
    this.labelText,
    this.hintText,
    this.prefix,
    this.floatingLabelBehavior,
    this.suffixIcon,
    this.iconData,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.controller,
    this.cursorColor,
    this.errorText,
    this.inputFormatters,
    this.helperText,
    this.counterText,
    this.fillColor,
    this.filled,
    this.prefixIcon,
    this.decoration,
    this.isPhoneWithFlag,
    this.initialSelection,
    this.enabled,
    this.style,
    this.hintStyle,
    this.labelStyle,

    ///for phone TextFormField with flgs
    this.onFlagChanged,
    this.countryFilter,
  });
  final int? maxLength;
  final FocusNode? focusNode;
  final bool? obscureText;
  TextInputType? keyboardType;
  TextInputAction? textInputAction;
  Function(String?)? onSaved;
  Function(String)? onChanged;
  List<TextInputFormatter>? inputFormatters;
  String? Function(String?)? validator;
  String? labelText;
  String? hintText;
  FloatingLabelBehavior? floatingLabelBehavior;
  Widget? suffixIcon;
  IconData? iconData;
  InputBorder? border;
  InputBorder? enabledBorder;
  InputBorder? focusedBorder;
  Widget? prefix;
  TextEditingController? controller;
  Color? cursorColor;
  String? errorText;
  String? helperText;
  String? counterText;
  bool? filled;
  Color? fillColor;
  Widget? prefixIcon;
  InputDecoration? decoration;
  bool? isPhoneWithFlag;
  void Function(CountryCode)? onFlagChanged;
  List<String>? countryFilter;
  String? initialSelection;
  bool? enabled;
  TextStyle? style;
  TextStyle? hintStyle;
  TextStyle? labelStyle;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: enabled,
      style: style,
      controller: controller,
      obscureText: obscureText ?? false,
      maxLength: maxLength,
      focusNode: focusNode,
      keyboardType: keyboardType ?? TextInputType.name,
      cursorColor: cursorColor,
      textInputAction: textInputAction,
      onSaved: onSaved,
      onChanged: onChanged,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        filled: filled,
        fillColor: fillColor,
        helperText: helperText,
        errorText: errorText,
        labelText: labelText,
        hintText: hintText,
        errorMaxLines: 3,
        prefixIcon: isPhoneWithFlag != null && isPhoneWithFlag == true
            ? IntrinsicHeight(
                child: Row(
                  children: [
                    CountryCodePicker(
                      showFlag: true,
                      flagWidth: 32.0,
                      alignLeft: false,
                      hideSearch: true,
                      hideMainText: true,
                      showFlagDialog: true,
                      showCountryOnly: false,
                      padding: EdgeInsets.zero,
                      onChanged: onFlagChanged,
                      showDropDownButton: false,
                      countryFilter: countryFilter,
                      showOnlyCountryWhenClosed: false,
                      initialSelection: initialSelection,
                      dialogSize: Size.fromHeight(
                          getProportionateScreenHeight(kDefaultPadding * 12)),
                      boxDecoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(kDefaultPadding),
                      ),
                    ),
                    VerticalDivider(color: Colors.grey.withValues(alpha: 0.3)),
                  ],
                  mainAxisSize: MainAxisSize.min,
                ),
              )
            : prefixIcon,
        prefix: prefix,
        hintStyle: hintStyle ?? TextStyle(fontSize: 14),
        floatingLabelStyle:
            WidgetStateTextStyle.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.error)) {
            return TextStyle(color: Colors.red);
          }
          return TextStyle(color: kBlackColor);
        }),
        labelStyle: labelStyle ??
            WidgetStateTextStyle.resolveWith((Set<WidgetState> states) {
              if (states.contains(WidgetState.error)) {
                return TextStyle(color: Colors.red);
              }
              return TextStyle(color: kBlackColor);
            }),
        counterText: counterText,
        floatingLabelBehavior:
            floatingLabelBehavior ?? FloatingLabelBehavior.always,
        suffixIcon: suffixIcon,
        border: border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              borderSide: BorderSide(color: kGreyColor.withValues(alpha: 0.4)),
            ),
        enabledBorder: enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              borderSide: BorderSide(color: kGreyColor.withValues(alpha: 0.4)),
            ),
        focusedBorder: focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              borderSide: BorderSide(color: kGreyColor.withValues(alpha: 0.4)),
            ),
      ),
    );
  }
}
