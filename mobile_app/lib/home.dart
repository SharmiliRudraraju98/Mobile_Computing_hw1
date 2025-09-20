import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nude_detector/flutter_nude_detector.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_app/dailies.dart';
import 'package:mobile_app/exercise.dart';
import 'package:mobile_app/home.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/help.dart';
import 'package:mobile_app/profile.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:path_provider/path_provider.dart';
import 'signup.dart';
import 'groups.dart';
import 'journal.dart';
import 'package:firebase_storage/firebase_storage.dart';

List<String> collegeList = [];
String dropdownValue = '';
//trying to fetch all the colleges names first and store in an array
Future<List<String>> fetchCollegeList() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  QuerySnapshot querySnapshot = await firestore.collection('locations').get();


  for (var doc in querySnapshot.docs) {
    String college = doc['college'];
    if (!collegeList.contains(college)) {
      collegeList.add(college);
    }
  }
  dropdownValue = collegeList.first;
  return collegeList;
}

class Home extends StatelessWidget {
  const Home({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

num _lindermanFeel = -1;
num _fmlFeel = -1;
num _storeFeel = -1;
List<File?> _lindermanImgList = [];
List<File?> _fmlImgList = [];
List<File?> _storeImgList = [];
List<bool> _lindermanImgBoolList = [];
List<bool> _fmlImgBoolList = [];
List<bool> _storeImgBoolList = [];
DateTime _lindermanTime = DateTime.parse("2000-01-01");
DateTime _fmlTime = DateTime.parse("2000-01-01");
DateTime _storeTime = DateTime.parse("2000-01-01");
bool imgFlag = false;
var auth = FirebaseAuth.instance.currentUser;

class _MyHomePageState extends State<MyHomePage> {
  File? galleryFile;
  final picker = ImagePicker();
  bool _mapReady = false;

  //calls each time the app is opened
  @override
void initState() {
  super.initState();
  fetchCollegeList().then((college) {
    setState(() {
      collegeList = college;
      if (collegeList.isNotEmpty) {
        dropdownValue = collegeList.first;
      }
    });
    _kickoffInitialMarkers();  // load markers now
  });
}

Future<String?> _uploadCommentImage(String locValue) async {
  if (_imagePath == null) return null;
  final file = File(_imagePath!);

  // create a unique filename per user + time
  final filename =
      '${auth?.uid ?? "anon"}_${DateTime.now().millisecondsSinceEpoch}.jpg';

  final ref = FirebaseStorage.instance
      .ref()
      .child('comment_images/$locValue/$filename');

  // upload
  await ref.putFile(
    file,
    SettableMetadata(contentType: 'image/jpeg'),
  );

  // public download URL
  return await ref.getDownloadURL();
}

  Widget _buildDisplayDialog(BuildContext context, data) {
    return AlertDialog(
      title: Text(data['user'].toString() + '\'s comment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(data['data'],
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14))
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<List<Object?>> getComments(locValue) async {
    CollectionReference collectionRef = FirebaseFirestore.instance
        .collection('comments')
        .doc(locValue)
        .collection("comments");

    QuerySnapshot querySnapshot = await collectionRef.get();

    DateTime now = DateTime.now();
    final allData = querySnapshot.docs
        .map((doc) {
          var data = doc.data();
          if (data != null) {
            // Explicitly cast data to Map<String, dynamic>
            Map<String, dynamic> dataMap = data as Map<String, dynamic>;
            DateTime? visibleTime =
                (dataMap['visibleTime'] as Timestamp?)?.toDate();
            if (visibleTime != null && now.isAfter(visibleTime)) {
              if (dataMap['feel'] == 'g') {
                return dataMap;
              }
            }
          }
          return null;
        })
        .where((data) => data != null)
        .toList();

    return allData;
  }

  bool _isNSFW = false;

  Widget _buildPopupDialog(BuildContext context, locValue) {
    return AlertDialog(
      title: Text(locValue + " Comments"),
      scrollable: true,
      contentPadding: EdgeInsets.all(1),
      content: Container(
          height: 400,
          width: 150,
          child: FutureBuilder(
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // If we got an error
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${snapshot.error} occurred',
                        style: TextStyle(fontSize: 18),
                      ),
                    );

                    // if we got our data
                  } else if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (BuildContext context, int index) {
                            List<bool> _likes =
                                List.filled(snapshot.data!.length, false);
                            return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: (snapshot.data!
                                                            .elementAt(index)
                                                        as Map)['feel'] ==
                                                    "b"
                                                ? Colors.red
                                                : (snapshot.data!.elementAt(
                                                                index)
                                                            as Map)['feel'] ==
                                                        "n"
                                                    ? Colors.yellow
                                                    : Colors.green,
                                            minimumSize: Size(10, 10),
                                            shape: CircleBorder(
                                                side: BorderSide(
                                                    color: Colors.white54)),
                                          ),
                                          child: Text(""),
                                          onPressed: () {},
                                        ),
                                        IconButton(
                                          icon: _likes[index]
                                              ? Icon(Icons.thumb_up_alt,
                                                  size: 16)
                                              : Icon(Icons.thumb_up_alt,
                                                  color: Colors.blue, size: 16),
                                          onPressed: () {
                                            _likes[index] = !_likes[index];
                                            setState(() {
                                              _likes[index];
                                            });
                                            print(_likes[index]);
                                          },
                                        ),
                                        Text(""),
                                        Container(
                                          child: Text(
                                            (snapshot.data!.elementAt(index)
                                                as Map)['user'],
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          width: 90,
                                        ),
                                        SizedBox(width: 5),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.indigo.shade300),
                                          child: Text('Show Message',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12)),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  _buildDisplayDialog(
                                                      context,
                                                      snapshot.data!
                                                          .elementAt(index)),
                                            );
                                          },
                                        ),
                                      ]),
                                ]);
                          },
                        ),
                      ],
                    );
                  }
                }
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
              future: getComments(locValue))),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
          child: const Text('Close'),
        ),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
          onPressed: () {
            Navigator.of(context).pop();
            showDialog(
                context: context,
                builder: (BuildContext context) =>
                    _buildCommentDialog(context, locValue));
          },
          child: const Text('Add Comment'),
        ),
      ],
    );
  }

  void _kickoffInitialMarkers() {
  if (dropdownValue.isEmpty) return;       // nothing to load yet
  _clearCollegeMarkers();
  _addCollegeMarkers(dropdownValue);
  _displayCurrentLocation();
}

  ////here
  void _clearCollegeMarkers() {
  setState(() {
    // keep the "Your Location" pin if you want; remove all others
    markers.removeWhere((id, _) => id.value != 'Your Location');
  });
}

  void _showPicker({
    required BuildContext context,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String? _imagePath;
  bool _containsNudity = false;
  num temp = 0;

  Future<dynamic> _onButtonPressed(image) async {
    if (image != null) {
      temp++;
      final hasNudity = await FlutterNudeDetector.detect(path: image.path);
      setState(() {
        _imagePath = image.path;
        _containsNudity = hasNudity;
      });
    }
  }

  Future getImage(
    ImageSource img,
  ) async {
    final pickedFile = await picker.pickImage(source: img, imageQuality: 100);
    XFile? xfilePick = pickedFile;
    if (xfilePick != null) {
      _onButtonPressed(pickedFile);
      String imgPath = xfilePick.path;
      if (_containsNudity || temp == 2) {
        Fluttertoast.showToast(
          msg: "Picture marked as NSFW, please try again",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER, // Also possible "TOP" and "BOTTOM"
        );
      } else {
        Fluttertoast.showToast(
          msg: "Picture confirmed",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER, // Also possible "TOP" and "BOTTOM"
        );
        galleryFile = File(pickedFile!.path);
        imgFlag = true;
        setState(() {});
      }
    } else {}
  }

  TextEditingController cmntController = TextEditingController();
  String? selectedTone;

  Widget _buildCommentDialog(BuildContext context, locValue) {
  // To store the selected tone
  return AlertDialog(
    title: const Text('Add a Comment'),
    content: Container(
      height: 370,
      width: 150,
      child: Column(
        children: <Widget>[
          TextField(
            controller: cmntController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Comment Entry',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedTone,
            hint: const Text('Select Comment Tone'),
            items: <String>['Positive', 'Negative', 'Neutral']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              selectedTone = newValue;
              setState(() {});
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade300,
            ),
            child: const Text('Select Image'),
            onPressed: () {
              _showPicker(context: context);
            },
          ),
          _imagePath == null
              ? const Text('No image has been selected')
              : Image.file(File(_imagePath!)),
        ],
      ),
    ),
    actions: <Widget>[
      // ======= ADD ENTRY =======
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo.shade300,
        ),
        onPressed: () async {
          final filter = ProfanityFilter();
          final text = cmntController.text.trim();

          // -------- Profanity check --------
          if (filter.hasProfanity(text)) {
            Fluttertoast.showToast(
              msg: "Please refrain from using profanity",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
            );
            return; // stop; do not post
          }

          // -------- Simple self-harm screen (lightweight) --------
          final selfHarmRegex = RegExp(
            r'\b(kill myself|suicide|end my life|hurt myself|self\-harm)\b',
            caseSensitive: false,
          );
          if (selfHarmRegex.hasMatch(text)) {
            Fluttertoast.showToast(
              msg:
                  "If you’re struggling, please reach out. In the US you can call or text 988 for help.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
            );
            return; // stop; do not post
          }

          // -------- Tone must be selected --------
          if (selectedTone == null) {
            Fluttertoast.showToast(
              msg: "Please select a comment tone",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
            );
            return;
          }

          // -------- Map tone to feel value --------
          String feelValue;
          switch (selectedTone) {
            case 'Positive':
              feelValue = 'g'; // green / good
              break;
            case 'Negative':
              feelValue = 'b'; // bad / red
              break;
            case 'Neutral':
            default:
              feelValue = 'n'; // neutral / yellow
          }

          // Upload image if selected
String? imageUrl;
try {
  imageUrl = await _uploadCommentImage(locValue);
} catch (e) {
  // If upload fails, keep going without image
  debugPrint('Image upload failed: $e');
}

          // -------- Post & visible times --------
          int delayInHours = 0;
          // final int delayInHours = Random().nextInt(17) + 8; // 8..24
          final DateTime postTime = DateTime.now();
          final DateTime visibleTime =
              postTime.add(Duration(hours: delayInHours));

          // -------- Write to Firestore --------
          await FirebaseFirestore.instance
              .collection('comments')
              .doc(locValue) // location doc (e.g., "Building C")
              .collection('comments')
              .add({
            'data': text,
            'user': auth?.email ?? auth?.uid,
            'feel': feelValue, // 'g' | 'b' | 'n'
            'postTime': Timestamp.fromDate(postTime),
            'visibleTime': Timestamp.fromDate(visibleTime),
            'location': locValue,
            if (imageUrl != null) 'imageUrl': imageUrl,
            // Optional: image url if you later upload to Storage:
            // 'imageUrl': uploadedImageUrl,
          });

          // -------- Reset UI and close --------
          setState(() {
            selectedTone = null;
            cmntController.clear();
            _imagePath = null;
          });
          Navigator.of(context).pop();

          Fluttertoast.showToast(
            msg: "Comment submitted!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
          );
        },
        child: const Text('Add Entry'),
      ),
      // ======= CLOSE =======
      ElevatedButton(
        onPressed: () {
          galleryFile = null;
          setState(() {
            selectedTone = null;
            cmntController.clear();
            _imagePath = null;
          });
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo.shade300,
        ),
        child: const Text('Close'),
      ),
    ],
  );
}

  Position _location = Position(
      latitude: 0,
      longitude: 0,
      speed: 0,
      timestamp: null,
      accuracy: 0,
      altitude: 0,
      speedAccuracy: 0,
      heading: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0);

  late GoogleMapController mapController;
  //this is the function to load custom map style json
  void changeMapMode(GoogleMapController mapController) {
    getJsonFile("lib/assets/map_style.json")
        .then((value) => setMapStyle(value, mapController));
  }

  //helper function
  void setMapStyle(String mapStyle, GoogleMapController mapController) {
    mapController.setMapStyle(mapStyle);
  }

  //helper function
  Future<String> getJsonFile(String path) async {
    ByteData byte = await rootBundle.load(path);
    var list = byte.buffer.asUint8List(byte.offsetInBytes, byte.lengthInBytes);
    return utf8.decode(list);
  }

  final LatLng _center = const LatLng(40.6049, -75.3775);

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  void _displayCurrentLocation() async {
    final location = await Geolocator.getCurrentPosition();
    _add(location.latitude, location.longitude, 'Your Location', true, -1);

    setState(() {
      _location = location;
    });
  }

  BitmapDescriptor getMarkerColor(double feelValue) {
    if (feelValue >= 0 && feelValue <= 0.7) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else if (feelValue <= 1.3) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    } else if (feelValue <= 2) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  void _add(double lat, double lng, String id, bool yourLoc, double feelValue) {
    String markerIdVal = id;
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: markerIdVal),
      //calls function above to get color for map
      icon: getMarkerColor(feelValue),
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              _buildPopupDialog(context, markerIdVal),
        );
      },
    );

    // The marker is added to the map
    setState(() {
      markers[markerId] = marker;
    });
  }

  Future<void> _addCollegeMarkers(String collegeName) async {
  try {
    final qs = await FirebaseFirestore.instance
        .collection("locations")
        .where("college", isEqualTo: collegeName)
        .get();

    final points = <LatLng>[];
    for (var doc in qs.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final loc = (data['location'] as List?) ?? const [0, 0];
      final name = (data['name'] ?? 'Unknown') as String;
      final lat = (loc[0] as num).toDouble();
      final lng = (loc[1] as num).toDouble();

      points.add(LatLng(lat, lng));
      _add(lat, lng, name, false, -1);
    }

    // 🔹 Recenter camera to fit all markers for this college
    if (points.isNotEmpty && mapController != null) {
      final swLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      final swLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      final neLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      final neLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

      final bounds = LatLngBounds(
        southwest: LatLng(swLat, swLng),
        northeast: LatLng(neLat, neLng),
      );

      await mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  } catch (e) {
    debugPrint("Error getting documents: $e");
  }
}

void _onMapCreated(GoogleMapController controller) {
  mapController = controller;
  _mapReady = true;
  changeMapMode(mapController);
  _kickoffInitialMarkers();    // ensures markers show on first open
}


  List<String> items = [
    "Journal",
    "Profile",
  ];

  /// List of body icon
  List<IconData> icons = [
    Icons.home,
    Icons.explore,
    Icons.settings,
    Icons.person
  ];
  int current = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Location",
        home: Scaffold(
            backgroundColor: Colors.lightGreen[100],
            appBar: AppBar(
  centerTitle: true,
  backgroundColor: Colors.indigo.shade300,
  title: const Text(
    "Home Page",
    style: TextStyle(fontWeight: FontWeight.w500),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        // Send user back to the sign-in page and clear the stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Signup()),
          (route) => false,
        );
      },
    ),
  ],
),
            body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("lib/assets/beach.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(5),
                child: Column(children: [
                  SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.all(5),
                            width: 85,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: TextButton(
                                child: Text(
                                  "Journal",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.indigo.shade300),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Journal()));
                                },
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.all(5),
                            width: 85,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: TextButton(
                                child: Text(
                                  "Activities",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.indigo.shade300),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const Dailies()));
                                },
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.all(5),
                            width: 85,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: TextButton(
                                child: Text(
                                  "Groups",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.indigo.shade300),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const Groups()));
                                },
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.all(5),
                            width: 85,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: TextButton(
                                child: Text(
                                  "Profile",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.indigo.shade300),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const Profile()));
                                },
                              ),
                            ),
                          ),
                        ],
                      )),
                  Text(
                    Random().nextInt(2) == 0
                        ? "\"You have an individual story to tell\""
                        : "\"Find happiness in the darkest times\"",
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.indigo.shade300),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Change current college:",
                          style: TextStyle(color: Colors.indigo.shade500),
                        ),
                        DropdownButton(
                          value: dropdownValue,
                          items: collegeList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          // onChanged: (String? value) {
                          //   setState(() {
                          //     dropdownValue = value!;
                          //   });
                          //   _addCollegeMarkers(value!);
                          //   _displayCurrentLocation();
                          // },
                          onChanged: (String? value) async {
  if (value == null) return;
  setState(() => dropdownValue = value);

  _clearCollegeMarkers();        // clear old pins
  await _addCollegeMarkers(value); // add new pins
  _displayCurrentLocation();     // optional: show user location
},

                        ),
                        SizedBox(
                            width: 500,
                            height: 500,
                            child: GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(
                                target: _center,
                                zoom: 11.0,
                              ),
                              markers: Set<Marker>.of(markers.values),
                            )),
                      ],
                    ),
                  ),
                ]))));
  }
}
