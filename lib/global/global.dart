// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:chalokart/models/direction_details_info.dart';
import 'package:chalokart/models/user_model.dart';
import 'package:chalokart/models/direction_details_with_polyline.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth firebaseAuth=FirebaseAuth.instance;
User? currentUser;

UserModel? userModelCurrentInfo;

String userDropOffAddress="";

DirectionDetailsWithPolyline? tripDirectionDetailsInfo;

String currentUserEmail="";