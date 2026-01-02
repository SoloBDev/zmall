import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/utils/size_config.dart';

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
    this.initialValue,
    // this.maxLines = 1,

    ///for phone TextFormField with flgs
    this.onFlagChanged,
    this.countryFilter,
    this.favorite = const [],
    this.dialogSize,
    this.hideSearch = true,
    this.minLines,
    this.maxLines = 1,
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
  String? initialValue;
  List<String> favorite;
  Size? dialogSize;
  bool hideSearch;
  // int? maxLines;
  int? minLines;
  int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      minLines: minLines,
      maxLines: maxLines,
      enabled: enabled,
      style: style,
      // maxLines: maxLines,
      initialValue: initialValue,
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
      obscuringCharacter: "*",
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountryCodePicker(
                      showFlag: true,
                      flagWidth: getProportionateScreenWidth(
                        kDefaultPadding * 2,
                      ),
                      alignLeft: false,
                      hideSearch: hideSearch,
                      hideMainText: true,
                      showFlagDialog: true,
                      showCountryOnly: false,
                      favorite: favorite,
                      padding: EdgeInsets.zero,
                      onChanged: onFlagChanged,
                      showDropDownButton: false,
                      countryFilter: countryFilter,
                      showOnlyCountryWhenClosed: false,
                      initialSelection: initialSelection,
                      dialogSize:
                          dialogSize ??
                          Size.fromHeight(
                            getProportionateScreenHeight(kDefaultPadding * 12),
                          ),
                      boxDecoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(kDefaultPadding),
                      ),
                      searchDecoration: InputDecoration(
                        border:
                            border ??
                            OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                        enabledBorder:
                            enabledBorder ??
                            OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: kGreyColor.withValues(alpha: 0.15),
                                // kWhiteColor
                              ),
                            ),
                        focusedBorder:
                            focusedBorder ??
                            OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: kGreyColor.withValues(alpha: 0.3),
                              ),
                            ),
                      ),
                    ),
                    Container(
                      width: 2,
                      margin: EdgeInsets.only(
                        right: getProportionateScreenWidth(kDefaultPadding / 2),
                      ),
                      height: getProportionateScreenHeight(
                        kDefaultPadding * 1.8,
                      ),
                      color:
                          // kWhiteColor
                          Colors.grey.withValues(alpha: 0.08),
                    ),
                  ],
                ),
              )
            : prefixIcon,
        prefix: prefix,
        hintStyle: hintStyle ?? TextStyle(fontSize: 14, color: kGreyColor),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.error)) {
            return TextStyle(color: Colors.red);
          }
          return TextStyle(color: kBlackColor);
        }),
        labelStyle:
            labelStyle ??
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
        border:
            border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
        enabledBorder:
            enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: kGreyColor.withValues(alpha: 0.15),
                // kWhiteColor
              ),
            ),
        focusedBorder:
            focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kGreyColor.withValues(alpha: 0.3)),
            ),
        errorBorder:
            focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: kSecondaryColor.withValues(alpha: 0.3),
              ),
            ),
        focusedErrorBorder:
            focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                width: 2,
                color: kSecondaryColor.withValues(alpha: 0.3),
              ),
            ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding,
        ),
      ),
    );
  }
}


  // border: border ??
        //     OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(kDefaultPadding),
        //       borderSide: BorderSide(color: kGreyColor.withValues(alpha: 0.4)),
        //     ),
        // enabledBorder: enabledBorder ??
        //     OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(kDefaultPadding),
        //       borderSide: BorderSide(color: kSecondaryColor),
        //       // borderSide: BorderSide(color: kGreyColor.withValues(alpha: 0.4)),
        //     ),
        // focusedBorder: focusedBorder ??
        //     OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(kDefaultPadding),
        //       borderSide: BorderSide(color: kGreyColor.withValues(alpha: 0.4)),
        //     ),