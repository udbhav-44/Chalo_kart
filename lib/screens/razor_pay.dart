import 'package:chalokart/global/global.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../utils/logger.dart';

class RazorPay extends StatefulWidget {
  const RazorPay({super.key});
  @override
  State<RazorPay> createState() => _RazorPayState();
}

class _RazorPayState extends State<RazorPay> {
  late Razorpay _razorpay;
  DatabaseReference userRef =FirebaseDatabase.instance.ref().child("users");
  TextEditingController amtController=TextEditingController();

  void openCheckout(amount) async{
    amount=amount*100;
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': amount,
      'name': 'Divyam',
      'prefill': {'contact': '8888888888', 'email': 'william.johnson@example-pet-store.com'},
      'external': {
        'wallets': ['paytm']
      }
    };
    try{
      _razorpay.open(options);
    }catch(e){
      AppLogger.error('Payment error', e);
    }
  }

  void handlePaymentSuccess(PaymentSuccessResponse response){
    int addedAmount = int.parse(amtController.text.toString());
    var currentWalletBalance = int.tryParse(userModelCurrentInfo!.wallet_amount!)! ;
    currentWalletBalance += addedAmount;
    var walletAmount = currentWalletBalance.toString();
    userRef.child(firebaseAuth.currentUser!.uid).update({
      "wallet_amount":walletAmount,
    }).then((value){
      amtController.clear();
      Fluttertoast.showToast(msg: "Updated Successfully. \n Reload the app to see changes");
    }).catchError((errorMessage){
      Fluttertoast.showToast(msg: "Error Occurred. \n $errorMessage");
    });
    Fluttertoast.showToast(msg: "Payment Successful"+response.paymentId!, toastLength: Toast.LENGTH_SHORT);
    Fluttertoast.showToast(msg: "\n Reload the App to see changes");
  }

  void handlePaymentError(PaymentFailureResponse response){
    Fluttertoast.showToast(msg: "Payment Failed"+response.message!, toastLength: Toast.LENGTH_SHORT);
  }

  void handleExternalWallet(ExternalWalletResponse response){
    Fluttertoast.showToast(msg: "External Wallet"+response.walletName!, toastLength: Toast.LENGTH_SHORT);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _razorpay.clear();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _razorpay=Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 100,),
            Text(
              "Recharge Wallet",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,

              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30,),
            Padding(padding: EdgeInsets.all(8),
              child: TextFormField(
                  cursorColor: Colors.white,
                  autofocus: false,
                  style: TextStyle(
                    color: Colors.white,

                  ),
                  decoration: InputDecoration(
    labelText: "enter amount",
    labelStyle: TextStyle(
    fontSize: 15,color: Colors.white,

    ),
    border: OutlineInputBorder(
    borderSide: BorderSide(
    color: Colors.white,
    width: 1
    )
    ),
    enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(
    color: Colors.white,
    width: 1,
    )
    ),
    errorStyle: TextStyle(
    fontSize: 15,
    color: Colors.redAccent,
    )

    ),
    controller: amtController,
    validator: (value){
                    if(value==null || value.isEmpty){
                      return "please enter";
    }
                    return null;

    },
              ),
            ),
    SizedBox(height: 30,),
    ElevatedButton(onPressed: (){
      if(amtController.text.toString().isNotEmpty){
        setState(() {
          int amount=int.parse(amtController.text.toString());
          openCheckout(amount);
        });
    }
    }, child:
        Padding(padding: EdgeInsets.all(8),
    child: Text("Make payment"),
    ),
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    ),
    )


        ],
      ),
      )
    );
  }
}
