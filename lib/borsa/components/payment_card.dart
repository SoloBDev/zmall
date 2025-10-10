import 'package:flutter/material.dart';
import 'package:zmall/utils/size_config.dart';

class PaymentCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String subtitle;
  final Function()? onPressed;
  const PaymentCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.onPressed,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: getProportionateScreenWidth(50),
              height: getProportionateScreenHeight(50),
              decoration: BoxDecoration(
                color: Color(0xFF667EEA).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.asset(
                  imageUrl,
                  width: getProportionateScreenWidth(40),
                  height: getProportionateScreenWidth(40),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    // style: GoogleFonts.inter(
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    // style: GoogleFonts.inter(
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
