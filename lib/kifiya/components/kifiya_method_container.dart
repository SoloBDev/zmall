import 'package:flutter/material.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/size_config.dart';

class KifiyaMethodContainer extends StatelessWidget {
  const KifiyaMethodContainer({
    Key? key,
    required this.selected,
    required this.title,
    required this.kifiyaMethod,
    required this.imagePath,
    required this.press,
  }) : super(key: key);

  final bool selected;
  final int kifiyaMethod;
  final String title;
  final String imagePath;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: getProportionateScreenWidth(kDefaultPadding * 4),
              height: getProportionateScreenHeight(kDefaultPadding * 3),
              child: Image.asset(
                imagePath,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.caption?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kBlackColor,
                  ),
            ),
          ],
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? kSecondaryColor : kBlackColor.withOpacity(0.2),
          ),
          color: selected ? kSecondaryColor.withOpacity(0.4) : kPrimaryColor,
          borderRadius: BorderRadius.circular(
            getProportionateScreenWidth(kDefaultPadding / 2),
          ),
        ),
      ),
    );
  }
}
