import 'package:flutter/cupertino.dart';

import '../models/direction.dart';

class AppInfo extends ChangeNotifier{
  Directions? userPickupLocation, userDropOffLocation;

  int countTotalTrips=0;

  // List<String> historyTripsKeyList=[];
  //
  // List<TripsHistoryModel> allTripsHistoryList=[];

  void updatePickupLocationAddress(Directions userPickupAddress){
    userPickupLocation=userPickupAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Directions dropOffAddress){
    userDropOffLocation=dropOffAddress;
    notifyListeners();
  }
}