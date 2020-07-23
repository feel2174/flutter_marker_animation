import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttermapexample/models/lat_lng_delta.dart';
import 'package:fluttermapexample/streams/lat_lng_interpolation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

final startPosition = LatLng(36.625769, 127.457584);

//Run over the polygon position
final polygon = <LatLng>[
  startPosition,
  LatLng(36.630969, 127.454580),
  LatLng(36.630969, 127.454580),
  LatLng(36.630969, 127.454580),
  LatLng(36.630969, 127.454580),
];

class FlutterMapMarkerAnimationExample extends StatefulWidget {
  @override
  _FlutterMapMarkerAnimationExampleState createState() =>
      _FlutterMapMarkerAnimationExampleState();
}

class _FlutterMapMarkerAnimationExampleState
    extends State<FlutterMapMarkerAnimationExample> {
//Markers collection, proper way
  final Map<MarkerId, Marker> _markers = Map<MarkerId, Marker>();
  StreamSubscription _locationSubscription;
  Location _locationTracker = Location();

  MarkerId sourceId = MarkerId("SourcePin");

  LatLngInterpolationStream _latLngStream = LatLngInterpolationStream(
    movementDuration: Duration(milliseconds: 2000),
  );

  StreamSubscription<LatLngDelta> subscription;

  GoogleMapController _controller;

  final CameraPosition _kSantoDomingo = CameraPosition(
    target: startPosition,
    zoom: 15,
  );

  @override
  void initState() {
    subscription =
        _latLngStream.getLatLngInterpolation().listen((LatLngDelta delta) {
      LatLng from = delta.from;

      LatLng to = delta.to;

      double angle = delta.rotation;
      print("Angle: -> $angle");
      //Update the animated marker
      setState(() {
        Marker sourceMarker = Marker(
          markerId: sourceId,
          rotation: delta.rotation,
          position: LatLng(
            delta.from.latitude,
            delta.from.longitude,
          ),
        );
        _markers[sourceId] = sourceMarker;
      });

      if (polygon.isNotEmpty) {
        //Pop the last position
        _latLngStream.addLatLng(polygon.removeLast());
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Markers Animation Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: SafeArea(
          child: GoogleMap(
            mapType: MapType.normal,
            markers: Set<Marker>.of(_markers.values),
            initialCameraPosition: _kSantoDomingo,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _locationSubscription =
                  _locationTracker.onLocationChanged().listen((newLocalData) {
                if (_controller != null) {
                  _controller.animateCamera(CameraUpdate.newCameraPosition(
                      new CameraPosition(
                          target: LatLng(
                              newLocalData.latitude, newLocalData.longitude),
                          tilt: 0,
                          zoom: 18.00)));
                  setState(() {
                    Marker sourceMarker = Marker(
                      markerId: sourceId,
                      position:
                          LatLng(newLocalData.latitude, newLocalData.longitude),
                    );
                    _markers[sourceId] = sourceMarker;
                  });
                  polygon.add(
                      LatLng(newLocalData.latitude, newLocalData.longitude));
                  _latLngStream.addLatLng(
                      LatLng(newLocalData.latitude, newLocalData.longitude));
                  //Add second position to start position over
                  Future.delayed(const Duration(milliseconds: 3000), () {
                    _latLngStream.addLatLng(polygon.removeLast());
                  });
                }
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}
