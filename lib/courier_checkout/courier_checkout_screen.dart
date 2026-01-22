import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:zmall/utils/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/kifiya/kifiya_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/utils/size_config.dart';
import 'package:zmall/widgets/order_status_row.dart';
import 'package:zmall/courier_checkout/components/checkout_detail_row.dart';

class CourierCheckout extends StatefulWidget {
  static String routeName = '/courier_checkout';

  @override
  _CourierCheckoutState createState() => _CourierCheckoutState();

  const CourierCheckout({
    super.key,
    @required this.orderDetail,
    @required this.userData,
    @required this.cartInvoice,
  });

  final orderDetail;
  final userData;
  final cartInvoice;
}

class _CourierCheckoutState extends State<CourierCheckout> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Checkout",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 0,
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.only(
          left: getProportionateScreenWidth(kDefaultPadding),
          right: getProportionateScreenWidth(kDefaultPadding),
          bottom: getProportionateScreenHeight(kDefaultPadding / 2),
        ),
        child: CustomButton(
          title: "Place Order",
          press: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return KifiyaScreen(
                    price:
                        widget.cartInvoice['order_payment']['total'].toDouble(),
                    orderPaymentId: widget.cartInvoice['order_payment']['_id'],
                    orderPaymentUniqueId: widget.cartInvoice['order_payment']
                            ['unique_id']
                        .toString(),
                    isCourier: true,
                    vehicleId: widget.cartInvoice['vehicles'][0]['_id'],
                  );
                },
              ),
            );
          },
          color: kSecondaryColor,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: getProportionateScreenHeight(kDefaultPadding),
            children: [
              Container(
                padding: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding)),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                  boxShadow: [boxShadow],
                ),
                child: Column(
                  children: [
                    OrderStatusRow(
                      value: "Order Details",
                      title: "Your courier delivery details",
                      icon: HeroiconsOutline.informationCircle,
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    CheckoutDetailRow(
                      label: "Sender",
                      value:
                          "${widget.orderDetail['pickup_addresses'][0]['user_details']['name']}",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: getProportionateScreenWidth(kDefaultPadding),
                      ),
                    ),
                    CheckoutDetailRow(
                      label: "Phone",
                      value:
                          "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${widget.orderDetail['pickup_addresses'][0]['user_details']['phone']}",
                    ),
                    SizedBox(
                        height: getProportionateScreenHeight(
                      kDefaultPadding,
                    )),
                    CheckoutDetailRow(
                      label: "Receiver",
                      value:
                          "${widget.orderDetail['destination_addresses'][0]['user_details']['name']}",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: getProportionateScreenWidth(kDefaultPadding),
                      ),
                    ),
                    CheckoutDetailRow(
                      label: "Phone",
                      value:
                          "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${widget.orderDetail['destination_addresses'][0]['user_details']['phone']}",
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    CheckoutDetailRow(
                      label: "Pickup",
                      value:
                          "${widget.orderDetail['pickup_addresses'][0]['address']}",
                      isExpanded: true,
                    ),
                    CheckoutDetailRow(
                      label: "Dropoff",
                      value:
                          "${widget.orderDetail['destination_addresses'][0]['address']}",
                      isExpanded: true,
                      spacing: 0,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(
                    getProportionateScreenWidth(kDefaultPadding)),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  boxShadow: [boxShadow],
                  borderRadius: BorderRadius.circular(
                    getProportionateScreenWidth(kDefaultPadding / 2),
                  ),
                ),
                child: Column(
                  children: [
                    OrderStatusRow(
                      value: "Payment Details",
                      title: "Your courier payment details",
                      icon: HeroiconsOutline.banknotes,
                    ),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding),
                    ),
                    CheckoutDetailRow(
                      label: "Time",
                      value:
                          "${widget.cartInvoice['order_payment']['total_time']} mins",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize:
                            getProportionateScreenWidth(kDefaultPadding * 0.8),
                      ),
                    ),
                    CheckoutDetailRow(
                      label: "Distance",
                      value:
                          "${widget.cartInvoice['order_payment']['total_distance'].toStringAsFixed(2)} km",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize:
                            getProportionateScreenWidth(kDefaultPadding * 0.8),
                      ),
                    ),
                    CheckoutDetailRow(
                      label: "Service Price",
                      value:
                          "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.cartInvoice['order_payment']['total_service_price'].toStringAsFixed(2)}",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize:
                            getProportionateScreenWidth(kDefaultPadding * 0.8),
                      ),
                      spacing:
                          getProportionateScreenHeight(kDefaultPadding / 3),
                    ),
                    CheckoutDetailRow(
                      label: "Total Order Price",
                      value:
                          "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.cartInvoice['order_payment']['total'].toStringAsFixed(2)}",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: getProportionateScreenWidth(kDefaultPadding),
                      ),
                      spacing: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
