import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:zmall/constants.dart';
import 'package:zmall/models/metadata.dart';
import 'package:zmall/service.dart';
import 'package:zmall/size_config.dart';
import 'package:zmall/widgets/custom_progress_indicator.dart';

class TicketOrderPayment extends StatefulWidget {
  const TicketOrderPayment({
    required this.quantity,
    required this.userId,
    required this.serverToken,
    required this.ticketId,
  });

  final String ticketId;
  final String userId;
  final String serverToken;
  final int quantity;

  @override
  _TicketOrderPaymentState createState() => _TicketOrderPaymentState();
}

class _TicketOrderPaymentState extends State<TicketOrderPayment> {
  bool _loading = false;
  var orderPayment;

  @override
  void initState() {
    super.initState();
    _getTicketInvoice();
  }

  void _getTicketInvoice() async {
    debugPrint("Getting event invoice");
    setState(() {
      _loading = true;
    });
    await getTicketOrderPayment();

    if (orderPayment != null && orderPayment['success']) {
      debugPrint("Successful...");
      // debugPrint(orderPayment);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${errorCodes['${orderPayment['error_code']}']}"),
          ),
        );
      }
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Purchase",
          style: TextStyle(color: kBlackColor),
        ),
        elevation: 1.0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        progressIndicator: CustomLinearProgressIndicator(
          message: "Generating ticket invoice...",
        ),
        child: Padding(
          padding: EdgeInsets.all(getProportionateScreenWidth(kDefaultPadding)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: getProportionateScreenHeight(kDefaultPadding * 6),
                    height:
                        getProportionateScreenHeight(kDefaultPadding * 1.25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          getProportionateScreenHeight(kDefaultPadding)),
                      border: Border.all(width: 1.0, color: kSecondaryColor),
                    ),
                    child: Center(
                      child: Text(
                        'Z-EVENT',
                        style: TextStyle(color: kSecondaryColor),
                      ),
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'TELEBIRR',
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  'Event Ticket',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical:
                          getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    child: ticketDetailsWidget(
                        'User',
                        'Yoseph Solomon',
                        'Date',
                        orderPayment['ticket_order_payment']['created_at']
                            .split('T')[0]),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical:
                          getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    child: ticketDetailsWidget(
                        'Host',
                        orderPayment['ticket_order_payment']
                            ['organization_name'],
                        'Event',
                        orderPayment['ticket_order_payment']['event_name']),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical:
                          getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    child: ticketDetailsWidget(
                        'Ticket Type',
                        orderPayment['ticket_order_payment']['ticket_name'],
                        'Unit Price',
                        '${Provider.of<ZMetaData>(context, listen: false).currency} ${orderPayment['ticket_order_payment']['total'] / orderPayment['ticket_order_payment']['quantity']}'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical:
                          getProportionateScreenHeight(kDefaultPadding / 2),
                    ),
                    child: ticketDetailsWidget(
                        'Quantity',
                        orderPayment['ticket_order_payment']['quantity']
                            .toString(),
                        'Total Price',
                        '${Provider.of<ZMetaData>(context, listen: false).currency} ${orderPayment['ticket_order_payment']['total']}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> getTicketOrderPayment() async {
    var url =
        "${Provider.of<ZMetaData>(context, listen: false).baseUrl}/api/admin/generate_ticket_invoice";
    Map data = {
      "user_id": widget.userId,
      "server_token": widget.serverToken,
      "quantity": widget.quantity,
      "ticket_type_id": widget.ticketId
    };
    var body = json.encode(data);

    try {
      http.Response response = await http
          .post(
        Uri.parse(url),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: body,
      )
          .timeout(
        Duration(seconds: 15),
        onTimeout: () {
          setState(() {
            this._loading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              Service.showMessage(
                  "Something went wrong! Check your internet and try again",
                  true,
                  duration: 3),
            );
          }

          throw TimeoutException("The connection has timed out!");
        },
      );
      setState(() {
        this.orderPayment = json.decode(response.body);
        this._loading = false;
      });
      return json.decode(response.body);
    } catch (e) {
      // debugPrint(e);
      setState(() {
        this._loading = false;
      });

      return null;
    }
  }

  Widget ticketDetailsWidget(String firstTitle, String firstDesc,
      String secondTitle, String secondDesc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                firstTitle,
                style: TextStyle(color: kGreyColor),
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: getProportionateScreenHeight(kDefaultPadding / 4)),
                child: Text(
                  firstDesc,
                  style: TextStyle(color: kBlackColor),
                ),
              )
            ],
          ),
        ),
        // SizedBox(
        //   width: getProportionateScreenWidth(kDefaultPadding * 5),
        // ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                secondTitle,
                style: TextStyle(color: kGreyColor),
              ),
              Padding(
                padding: EdgeInsets.only(
                    top: getProportionateScreenHeight(kDefaultPadding / 4)),
                child: Text(
                  secondDesc,
                  style: TextStyle(color: kBlackColor),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
