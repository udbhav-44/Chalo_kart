
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final nameTextEditingController=TextEditingController();
  final phoneTextEditingController=TextEditingController();
  final addressTextEditingController=TextEditingController();

  // DatabaseReference userRef =FirebaseDatabase.instance.ref().child("users");

  Future<void> showUserNameDialogAlert(BuildContext context, String name){
    nameTextEditingController.text=name;
    return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("Update"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: nameTextEditingController,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.red),)
              ),
              TextButton(
                  onPressed: (){
                    // userRef.child(firebaseAuth.currentUser!.uid).update({
                    //   "name":nameTextEditingController.text.trim(),
                    // }).then((value){
                    //   nameTextEditingController.clear();
                    //   Fluttertoast.showToast(msg: "Updated Successfully. \n Reload the app to see changes");
                    // }).catchError((errorMessage){
                    //   Fluttertoast.showToast(msg: "Error Occurred. \n $errorMessage");
                    // });
                    Navigator.pop(context);
                  },
                  child: Text("OK", style: TextStyle(color: Colors.black),)
              )
            ],
          );
        }
    );
  }

  Future<void> showUserPhoneDialogAlert(BuildContext context, String phone){
    phoneTextEditingController.text=phone;
    return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("Update"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: phoneTextEditingController,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.red),)
              ),
              TextButton(
                  onPressed: (){
                    // userRef.child(firebaseAuth.currentUser!.uid).update({
                    //   "phone":phoneTextEditingController.text.trim(),
                    // }).then((value){
                    //   phoneTextEditingController.clear();
                    //   Fluttertoast.showToast(msg: "Updated Successfully. \n Reload the app to see changes");
                    // }).catchError((errorMessage){
                    //   Fluttertoast.showToast(msg: "Error Occurred. \n $errorMessage");
                    // });
                    Navigator.pop(context);
                  },
                  child: Text("OK", style: TextStyle(color: Colors.black),)
              )
            ],
          );
        }
    );
  }

  Future<void> showUserAddressDialogAlert(BuildContext context, String address){
    addressTextEditingController.text=address;
    return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text("Update"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: addressTextEditingController,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.red),)
              ),
              TextButton(
                  onPressed: (){
                    // userRef.child(firebaseAuth.currentUser!.uid).update({
                    //   "address":addressTextEditingController.text.trim(),
                    // }).then((value){
                    //   addressTextEditingController.clear();
                    //   Fluttertoast.showToast(msg: "Updated Successfully. \n Reload the app to see changes");
                    // }).catchError((errorMessage){
                    //   Fluttertoast.showToast(msg: "Error Occurred. \n $errorMessage");
                    // });
                    Navigator.pop(context);
                  },
                  child: Text("OK", style: TextStyle(color: Colors.black),)
              )
            ],
          );
        }
    );
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
            "Profile Screen",
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "DAdddyyy", // change to userModelCurrentInfo!.name!
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                        onPressed: (){
                          showUserNameDialogAlert(context, "DAdddyy");//change to userModelCurrentInfo!.name!
                        },
                        icon: Icon(
                          Icons.edit
                        )
                    ),
                  ],
                ),
                Divider(
                  thickness: 1,
                ),
                //Phone Edit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "9698769867", // change to userModelCurrentInfo!.phone!
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                        onPressed: (){
                          showUserPhoneDialogAlert(context, "9698769867");//change to userModelCurrentInfo!.phone!
                        },
                        icon: Icon(
                            Icons.edit
                        )
                    ),
                  ],
                ),
                Divider(
                  thickness: 1,
                ),
                //Address Edit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Hall 2", // change to userModelCurrentInfo!.address!
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                        onPressed: (){
                          showUserAddressDialogAlert(context, "Hall 2");//change to userModelCurrentInfo!.address!
                        },
                        icon: Icon(
                            Icons.edit
                        )
                    ),
                  ],
                ),
                Divider(
                  thickness: 1,
                ),
                //Email
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "divyamag22@iitk.ac.in", // change to userModelCurrentInfo!.email!
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }
}
