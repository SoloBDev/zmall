import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class CheckoutDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final bool isExpanded;
  final TextAlign? valueTextAlign;
  final double? spacing;

  const CheckoutDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.isExpanded = false,
    this.valueTextAlign,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: labelStyle ??
                  TextStyle(
                    fontWeight: label.toLowerCase().contains("total")
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: label.toLowerCase().contains("total")
                        ? kBlackColor
                        : kGreyColor,
                  ),
            ),
            SizedBox(
              width: getProportionateScreenWidth(kDefaultPadding / 2),
            ),
            isExpanded
                ? Expanded(
                    child: Text(
                      value,
                      style: valueStyle ??
                          TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * 0.8),
                          ),
                      softWrap: true,
                      textAlign: valueTextAlign ?? TextAlign.right,
                    ),
                  )
                : Text(
                    value,
                    style: valueStyle ??
                        TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: getProportionateScreenWidth(
                              kDefaultPadding * 0.8),
                        ),
                  ),
          ],
        ),
        if (spacing != null)
          SizedBox(height: spacing!)
        else
          SizedBox(height: getProportionateScreenHeight(kDefaultPadding / 4)),
      ],
    );
  }
}
