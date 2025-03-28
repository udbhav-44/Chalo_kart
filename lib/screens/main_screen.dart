import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoder2/geocoder2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import 'package:chalokart/global/global.dart';
import 'package:chalokart/global/map_key.dart';
import 'package:chalokart/infoHandler/app_info.dart';
import 'package:chalokart/screens/drawer_screen.dart';
import 'package:chalokart/screens/precise_pickup_screen.dart';
import 'package:chalokart/screens/search_places_screen.dart';
import 'package:chalokart/utils/app_colors.dart';

import '../Assistance/assistance_methods.dart';
import '../models/direction.dart';
import '../widgets/progress_dialog.dart';
import '../utils/logger.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  LatLng? pickLocation;
  loc.Location location=loc.Location();
  // String? _address;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(26.512507487655384, 80.23335575281814),
    zoom: 14.4746,
  );


  final GlobalKey<ScaffoldState> _scaffoldState=GlobalKey<ScaffoldState>();

  double searchLocationContainer=220;
  double waitingResponseFromDriverContainerHeight=0;

  Position? userCurrentPosition;

  var geoLocation=Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap=0;

  List<LatLng> pLineCoordinatesList=[];

  Set<Polyline> polylineSet={};

  Set<Marker> markerSet={};

  Set<Circle> circleSet={};

  String userName="";
  String userEmail="";

  bool openNavigationDrawer=true;

  bool activeNearbyDriverKeysLoaded=false;

  BitmapDescriptor? activeNearbyIcon;
  
  bool _isInitializing = true;
  bool _initializationError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    try {
      checkLocationPermissionAllowed();
      _isInitializing = false;
      setState(() {});
    } catch (e) {
      AppLogger.error('Error initializing MainScreen', e);
      _initializationError = true;
      _errorMessage = e.toString();
      _isInitializing = false;
      setState(() {});
    }
  }


  locateUserPosition() async{
    try {
      Position cPosition= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      userCurrentPosition=cPosition;
  
      LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
      CameraPosition cameraPosition=CameraPosition(target: latLngPosition, zoom: 15);
  
      newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  
      String humanReadableAddress=await AssistantMethods.searchAddressForGeoCoordinates(userCurrentPosition!, context);
      AppLogger.info('Address: $humanReadableAddress');
    } catch (e) {
      AppLogger.error('Error locating user position', e);
    }
  }


  Future<void> drawPolylineFromOriginToDestination(bool darkTheme) async{
    var originPosition=Provider.of<AppInfo>(context, listen: false).userPickupLocation;
    var destinationPosition=Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(originPosition!.locationLatitude!,originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!,destinationPosition.locationLongitude!);
    
    showDialog(
        context: context,
        builder: (BuildContext context)=>ProgressDialog(message: "Please wait"),
    );

    var (directionDetailsWithPolyline, encodedPolylineString)=await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);

    setState(() {
      tripDirectionDetailsInfo=directionDetailsWithPolyline;
    });

    Navigator.pop(context);

    PolylinePoints pPoints=PolylinePoints();
    List<PointLatLng> decodePolyLinePointsResultList=pPoints.decodePolyline(encodedPolylineString);
    // print(decodePolyLinePointsResultList);
    pLineCoordinatesList.clear();

    if(decodePolyLinePointsResultList.isNotEmpty){
      for (var pointLatLng in decodePolyLinePointsResultList) {
        pLineCoordinatesList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: darkTheme? Colors.greenAccent:Colors.greenAccent,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 8,
        visible: true
      );

      polylineSet.add(polyline);
    });
    // print("Divyam");
    // print(pLineCoordinatesList);
    LatLngBounds boundsLatLng;
    if(originLatLng.latitude>destinationLatLng.latitude&& originLatLng.longitude>destinationLatLng.longitude){
      boundsLatLng=LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude>destinationLatLng.longitude){
      boundsLatLng=LatLngBounds(
          southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude)
      );
    }
    else if(originLatLng.latitude>destinationLatLng.latitude){
      boundsLatLng=LatLngBounds(
          southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
          northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude)
      );
    }
    else{
      boundsLatLng=LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }
    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker=Marker(
      markerId: const MarkerId("originID"),
      infoWindow: InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
    );

    Marker destinationMarker=Marker(
        markerId: const MarkerId("destinationID"),
        infoWindow: InfoWindow(title: destinationPosition.locationName, snippet: "Destination"),
        position: destinationLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
    );

    setState(() {
      markerSet.add(originMarker);
      markerSet.add(destinationMarker);
    });

    Circle originCircle=Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.greenAccent,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );
    Circle destinationCircle=Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.greenAccent,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      circleSet.add(originCircle);
      circleSet.add(destinationCircle);
    });
  }


  // getAddressesFromLatLng() async{
  //   try{
  //     GeoData data= await Geocoder2.getDataFromCoordinates(
  //         latitude: pickLocation!.latitude,
  //         longitude: pickLocation!.longitude,
  //         googleMapApiKey: mapKey
  //     );
  //     setState(() {
  //
  //       Directions userPickupAddress=Directions();
  //       userPickupAddress.locationLatitude=pickLocation!.latitude;
  //       userPickupAddress.locationLongitude=pickLocation!.longitude;
  //       userPickupAddress.locationName=data.address;
  //
  //       // _address=data.address;
  //
  //       Provider.of<AppInfo>(context, listen: false).updatePickupLocationAddress(userPickupAddress);
  //     });
  //
  //   }
  //   catch(e){
  //     print(e);
  //   }
  // }

  checkLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission==LocationPermission.denied){
      _locationPermission = await Geolocator.requestPermission();
    }

  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness==Brightness.dark;
    
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                "Loading map...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: darkTheme ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_initializationError) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                "Error initializing map",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkTheme ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _isInitializing = true;
                  _initializationError = false;
                  setState(() {});
                  _initializeScreen();
                },
                child: Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      key: _scaffoldState,
      drawer: DrawerScreen(),
      body: GestureDetector(
        onTap:(){
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: bottomPaddingOfMap, top: 30),
              mapType: MapType.normal,
              polylines: polylineSet,
              markers: markerSet,
              initialCameraPosition: _kGooglePlex,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              circles: circleSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController=controller;

                setState(() {
                  bottomPaddingOfMap=290;
                });

                locateUserPosition();
              },
            ),
            // Align(
            //   alignment: Alignment.center,
            //   child: Padding(
            //       padding: const EdgeInsets.only(bottom: 40.0),
            //       child: Image.asset("images/pick_pin.jpg", height: 45,width: 45,),
            //   ),
            // ),
            // Positioned(
            //   top: 40,
            //   left: 20,
            //   right: 20,
            //   child: Container(
            //     decoration: BoxDecoration(
            //       border: Border.all(color: Colors.black),
            //       color: Colors.white
            //     ),
            //     padding: EdgeInsets.all(20),
            //     child: Text(
            //       Provider.of<AppInfo>(context).userPickupLocation!=null ?
            //       (Provider.of<AppInfo>(context).userPickupLocation!.locationName!.substring(0,45))+'...'
            //           : 'Add Pickup Location',
            //       overflow: TextOverflow.visible, softWrap: true,
            //     ),
            //   ),
            // )
            //custom Hamburger Icon for drawer
            Positioned(
              top: 50,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  try {
                    if (_scaffoldState.currentState != null) {
                      _scaffoldState.currentState!.openDrawer();
                    }
                  } catch (e) {
                    debugPrint("Error opening drawer: $e");
                    // Show a toast or snackbar if there's an error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Could not open menu"))
                    );
                  }
                },
                child: CircleAvatar(
                  backgroundColor: darkTheme? Colors.greenAccent.shade400:Colors.white,
                  child: Icon(
                    Icons.menu,
                    color: darkTheme? Colors.greenAccent:Colors.greenAccent,
                  ),
                ),
              ),
            ),

            //ui for location search
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.black: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: darkTheme ? Colors.grey.shade900: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, color: darkTheme? Colors.greenAccent.shade400:Colors.green,),
                                      const SizedBox(width: 10,),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("From",
                                            style: TextStyle(color: darkTheme? Colors.greenAccent.shade400:Colors.green,
                                                fontSize: 16, fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          Text(
                                            Provider.of<AppInfo>(context).userPickupLocation!=null ?
                                              '${Provider.of<AppInfo>(context).userPickupLocation!.locationName!.substring(0,30)}...'
                                              : 'Add Pickup Location',
                                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                                          )
                                        ],
                                      )

                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5,),

                                Divider(
                                  height: 1,
                                  thickness: 2,
                                  color: darkTheme? Colors.greenAccent.shade400:Colors.greenAccent,
                                ),

                                SizedBox(height: 5,),
                                Padding(
                                  padding: EdgeInsets.all(5),
                                  child: GestureDetector(
                                    onDoubleTap: () async{
                                      // go to search places screen
                                      var responseFromSearchScreen= await Navigator.push(context, MaterialPageRoute(builder: (c)=>SearchPlacesScreen()));

                                      if(responseFromSearchScreen=="obtainedDropOffLocation"){
                                        setState(() {
                                          openNavigationDrawer=false;

                                        });
                                      }

                                      await drawPolylineFromOriginToDestination(darkTheme);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, color: darkTheme? Colors.greenAccent.shade400:Colors.green,),
                                        SizedBox(width: 10,),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("To",
                                              style: TextStyle(color: darkTheme? Colors.greenAccent.shade400:Colors.green,
                                                  fontSize: 16, fontWeight: FontWeight.bold
                                              ),
                                            ),
                                            Text(
                                              Provider.of<AppInfo>(context).userDropOffLocation!=null ?
                                              Provider.of<AppInfo>(context).userDropOffLocation!.locationName!
                                                  : 'Add Drop Off Location',
                                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                                            )
                                          ],
                                        )

                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                  onPressed: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (c)=>PrecisePickupScreen()));
                                  },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme? Colors.greenAccent.shade400:Colors.greenAccent,
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  )
                                ),
                                  child: Text(
                                    "Change Pick Up",
                                    style: TextStyle(
                                      color: darkTheme? Colors.black: Colors.white,
                                    ),
                                  )
                              ),

                              SizedBox(width: 20,),

                              ElevatedButton(
                                  onPressed: (){

                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: darkTheme? Colors.greenAccent.shade400:Colors.greenAccent,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      )
                                  ),
                                  child: Text(
                                    "Request Ride",
                                    style: TextStyle(
                                      color: darkTheme? Colors.black: Colors.white,
                                    ),
                                  )
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

