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
    Fluttertoast.showToast(msg: "Payment Successful"+response.paymentId!, toastLength: Toast.LENGTH_SHORT);
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
            Image.network('https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.pngwing.com%2Fen%2Fsearch%3Fq%3Drazorpay&psig=AOvVaw1C8aq0-OAlTEj89baK2FmI&ust=1743018628002000&source=images&cd=vfe&opi=89978449&ved=0CBQQjRxqFwoTCLjz08OApowDFQAAAAAdAAAAABAG', height: 100, width: 300,),
            SizedBox(height: 10,),
            Text(
              "Welcome",
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
