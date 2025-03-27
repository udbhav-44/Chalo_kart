import 'package:firebase_database/firebase_database.dart';

class UserModel{
  String? phone;
  String? email;
  String? name;
  String? id;

  UserModel({
    this.phone,
    this.email,
    this.name,
    this.id,
  });

  UserModel.fromSnapshot(DataSnapshot snap){
    phone=(snap.value as dynamic)["phone"];
    name=(snap.value as dynamic)["name"];
    email=(snap.value as dynamic)["email"];
    id=snap.key;
  }
}