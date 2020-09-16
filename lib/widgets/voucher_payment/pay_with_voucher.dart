import 'package:flutter/material.dart';
import 'package:flutterwave/core/voucher_payment/voucher_payment_manager.dart';
import 'package:flutterwave/models/requests/voucher/voucher_payment_request.dart';
import 'package:flutterwave/models/responses/charge_response.dart';
import 'package:flutterwave/widgets/flutterwave_view_utils.dart';
import 'package:hexcolor/hexcolor.dart';

import 'package:http/http.dart' as http;

class PayWithVoucher extends StatefulWidget {
  final VoucherPaymentManager _paymentManager;

  PayWithVoucher(this._paymentManager);

  @override
  _PayWithVoucherState createState() => _PayWithVoucherState();
}

class _PayWithVoucherState extends State<PayWithVoucher> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _voucherPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  BuildContext loadingDialogContext;

  @override
  Widget build(BuildContext context) {
    final String initialPhoneNumber = this.widget._paymentManager.phoneNumber;
    this._phoneNumberController.text =
    initialPhoneNumber != null ? initialPhoneNumber : "";

    return MaterialApp(
      home: Scaffold(
        key: this._scaffoldKey,
        appBar: AppBar(
          backgroundColor: Hexcolor("#fff1d0"),
          title: RichText(
            textAlign: TextAlign.left,
            text: TextSpan(
              text: "Pay with ",
              style: TextStyle(fontSize: 20, color: Colors.black),
              children: [
                TextSpan(
                  text: "Voucher",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black),
                )
              ],
            ),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Container(
            margin: EdgeInsets.fromLTRB(20, 35, 20, 20),
            width: double.infinity,
            child: Form(
              key: this._formKey,
              child: ListView(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      hintText: "Phone Number",
                    ),
                    controller: this._phoneNumberController,
                    validator: (value) =>
                    value.isEmpty ? "phone number is required" : null,
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Voucher Pin",
                      hintText: "Voucher Pin",
                    ),
                    controller: this._voucherPinController,
                    validator: (value) =>
                    value.isEmpty ? "voucher pin is required" : null,
                  ),
                  Container(
                    width: double.infinity,
                    height: 50,
                    margin: EdgeInsets.fromLTRB(0, 40, 0, 20),
                    child: RaisedButton(
                      onPressed: this._onPayPressed,
                      color: Colors.orange,
                      child: Text(
                        "Pay with Voucher",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showLoading(String message) {
    return showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        this.loadingDialogContext = context;
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                backgroundColor: Colors.orangeAccent,
              ),
              SizedBox(
                width: 40,
              ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black),
              )
            ],
          ),
        );
      },
    );
  }

  void closeDialog() {
    if (this.loadingDialogContext != null) {
      Navigator.of(this.loadingDialogContext).pop();
      this.loadingDialogContext = null;
    }
  }

  void _removeFocusFromView() {
    FocusScope.of(this.context).requestFocus(FocusNode());
  }

  void showSnackBar(String message) {
    SnackBar snackBar = SnackBar(
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
    );
    this._scaffoldKey.currentState.showSnackBar(snackBar);
  }

  void _onPayPressed() {
    if (this._formKey.currentState.validate()) {
      final VoucherPaymentManager paymentManager = this.widget._paymentManager;
      FlutterwaveViewUtils.showConfirmPaymentModal(
          this.context, paymentManager.currency, paymentManager.amount,
          this._initiatePayment);

      print("Should have called pay pressed");
      // this._initiatePayment();
    }
  }

  void _initiatePayment() async {
    this.showLoading("initiating payment...");

    final VoucherPaymentManager paymentManager = this.widget._paymentManager;
    final VoucherPaymentRequest request = VoucherPaymentRequest(
        amount: paymentManager.amount,
        currency: paymentManager.currency,
        email: paymentManager.email,
        txRef: paymentManager.txRef,
        fullName: paymentManager.fullName,
        phoneNumber: paymentManager.phoneNumber,
        pin: this._voucherPinController.text.toString());
    try {
      print("Voucher request is ${request.toJson()}");
      final http.Client client = http.Client();
      final result = await paymentManager.payWithVoucher(request, client);
      this.closeDialog();
      print("voucher response is ${result.toJson()}");
    } catch (error) {
      this.closeDialog();
      print("voucher error is ${error.toString()}");
    }
  }

  void _onComplete(final ChargeResponse chargeResponse) {}
}
