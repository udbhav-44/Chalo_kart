import 'package:flutter/material.dart';
import 'package:chalokart/global/global.dart';
import 'package:chalokart/screens/profile_screen.dart';

import 'sign_in_screen.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      child: Drawer(
        child: Padding(
            padding: EdgeInsets.fromLTRB(30, 50, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.black,
                      size: 60,
                    ),
                  ),
                  SizedBox(height: 20,),
                  Text(
                    "Chud Gaye Guru",// change to userModelCurrentInfo!.name!
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10,),
                  GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (c)=>ProfileScreen()));
                    },
                    child: Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent.shade700,
                      ),
                    ),
                  ),

                  SizedBox(height: 30,),
                  Text(
                    "Your Trips",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  SizedBox(height: 15,),
                  Text(
                    "Wallet",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  SizedBox(height: 15,),
                  Text(
                    "About US",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),


                ],
              ),
              GestureDetector(
                onTap: (){
                  // firebaseAuth.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c)=>SignInScreen()));
                },
                child: Text(
                  "Logout",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red,
                  ),
                ),
              )
            ],
          ),
        ),

      ),
    );
  }
}
