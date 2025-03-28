import 'package:chalokart/screens/razor_pay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../global/global.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  String _walletAmount = "Loading...";
  bool _isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.microtask(() => _loadAmount());
  }
  Future<void> _loadAmount() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Check if we already have the info in global variables
      if (userModelCurrentInfo != null) {
        if (!mounted) return;
        setState(() {
          _walletAmount = userModelCurrentInfo!.wallet_amount!;
          _isLoading = false;
        });
        return;
      }

      // Get current user from Firebase directly
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Use display name or fallback to email
        if (!mounted) return;
        setState(() {
          // _userName = user.displayName!;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          // _userName = "Unknown User";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
      if (!mounted) return;
      setState(() {
        // _userName = "Unknown User";
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: (){
              Navigator.pop(context);
            },
            icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.black
            ),
          ),
          elevation: 0,
          title: Text(
            "Wallet",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,

        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 50),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(50),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20,),
                //Name Edit
                _isLoading
                    ? const Text(
                  "Loading...",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )
                    : Text(
                  _walletAmount,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const RazorPay()),
                    ).then((_) => _loadAmount()); // Refresh name when returning from profile
                  },
                  child: Text(
                    "Recharge Wallet",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }
}
