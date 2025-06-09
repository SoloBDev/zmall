import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/custom_widgets/custom_button.dart';
import 'package:zmall/kifiya/kifiya_screen.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/product/product_screen.dart';
import 'package:zmall/size_config.dart';

class CourierCheckout extends StatefulWidget {
  static String routeName = '/courier_checkout';

  @override
  _CourierCheckoutState createState() => _CourierCheckoutState();

  const CourierCheckout({
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
    // TODO: implement initState
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
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(
            getProportionateScreenWidth(kDefaultPadding),
          ),
          child: Column(
            children: [
              CategoryContainer(
                title: "Order Details",
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 4),
              ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sender :",
                          style: TextStyle(color: kGreyColor),
                        ),
                        SizedBox(
                          width:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        Text(
                          "${widget.orderDetail['pickup_addresses'][0]['user_details']['name']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                getProportionateScreenWidth(kDefaultPadding),
                          ),
                        )
                      ],
                    ),
                    Container(
                        width: double.infinity, height: 0.1, color: kGreyColor),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Phone :",
                          style: TextStyle(color: kGreyColor),
                        ),
                        SizedBox(
                          width:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        Text(
                          "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${widget.orderDetail['pickup_addresses'][0]['user_details']['phone']}",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * .8),
                          ),
                        )
                      ],
                    ),
                    Container(
                        width: double.infinity, height: 0.1, color: kGreyColor),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Receiver :",
                          style: TextStyle(color: kGreyColor),
                        ),
                        SizedBox(
                          width:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        Text(
                          "${widget.orderDetail['destination_addresses'][0]['user_details']['name']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                getProportionateScreenWidth(kDefaultPadding),
                          ),
                        )
                      ],
                    ),
                    Container(
                        width: double.infinity, height: 0.1, color: kGreyColor),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Phone :",
                          style: TextStyle(color: kGreyColor),
                        ),
                        SizedBox(
                          width:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        Text(
                          "${Provider.of<ZMetaData>(context, listen: false).areaCode} ${widget.orderDetail['destination_addresses'][0]['user_details']['phone']}",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * .8),
                          ),
                        )
                      ],
                    ),
                    Container(
                        width: double.infinity, height: 0.1, color: kGreyColor),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pickup :",
                          style: TextStyle(color: kGreyColor),
                        ),
                        SizedBox(
                          width:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        Expanded(
                          child: Text(
                            "${widget.orderDetail['pickup_addresses'][0]['address']}",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: getProportionateScreenWidth(
                                  kDefaultPadding * .8),
                            ),
                            softWrap: true,
                            textAlign: TextAlign.right,
                          ),
                        )
                      ],
                    ),
                    Container(
                        width: double.infinity, height: 0.1, color: kGreyColor),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Dropoff :",
                          style: TextStyle(color: kGreyColor),
                        ),
                        SizedBox(
                          width:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        Expanded(
                          child: Text(
                            "${widget.orderDetail['destination_addresses'][0]['address']}",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: getProportionateScreenWidth(
                                  kDefaultPadding * .8),
                            ),
                            softWrap: true,
                            textAlign: TextAlign.right,
                          ),
                        )
                      ],
                    ),
                    Container(
                        width: double.infinity, height: 0.1, color: kGreyColor),
                  ],
                ),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding),
              ),
              CategoryContainer(
                title: "Payment Details",
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding / 4),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Time :",
                          style: TextStyle(color: kGreyColor),
                        ),
                        SizedBox(
                          width:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        Text(
                          "${widget.cartInvoice['order_payment']['total_time']} mins",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * .8),
                          ),
                        )
                      ],
                    ),
                    Container(
                        width: double.infinity, height: 0.1, color: kGreyColor),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Distance :",
                          style: TextStyle(color: kGreyColor),
                        ),
                        SizedBox(
                          width:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        Text(
                          "${widget.cartInvoice['order_payment']['total_distance'].toStringAsFixed(2)} km",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: getProportionateScreenWidth(
                                kDefaultPadding * .8),
                          ),
                        )
                      ],
                    ),
                    Container(
                        width: double.infinity, height: 0.1, color: kGreyColor),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 4),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Service Price :",
                          style: TextStyle(color: kGreyColor),
                        ),
                        SizedBox(
                          width:
                              getProportionateScreenWidth(kDefaultPadding / 2),
                        ),
                        Text(
                          "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.cartInvoice['order_payment']['total_service_price'].toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize:
                                getProportionateScreenWidth(kDefaultPadding),
                          ),
                        )
                      ],
                    ),
                    Container(
                        width: double.infinity, height: 0.1, color: kGreyColor),
                    SizedBox(
                      height: getProportionateScreenHeight(kDefaultPadding / 3),
                    ),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Total",
                            style: TextStyle(
                              color: kGreyColor,
                            ),
                          ),
                          SizedBox(
                            height: getProportionateScreenHeight(
                                kDefaultPadding / 3),
                          ),
                          Text(
                            "${Provider.of<ZMetaData>(context, listen: false).currency} ${widget.cartInvoice['order_payment']['total'].toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize:
                                  getProportionateScreenWidth(kDefaultPadding),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: getProportionateScreenHeight(kDefaultPadding),
              ),
              CustomButton(
                title: "Place Order",
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return KifiyaScreen(
                          price: widget.cartInvoice['order_payment']['total']
                              .toDouble(),
                          orderPaymentId: widget.cartInvoice['order_payment']
                              ['_id'],
                          orderPaymentUniqueId: widget
                              .cartInvoice['order_payment']['unique_id']
                              .toString(),
                          isCourier: true,
                          vehicleId: widget.cartInvoice['vehicles'][0]['_id'],
                        );
                      },
                    ),
                  );
                },
                color: kSecondaryColor,
              )
//              Text("${widget.cartInvoice}"),
            ],
          ),
        ),
      ),
    );
  }
}
