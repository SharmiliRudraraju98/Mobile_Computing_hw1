import 'dart:math';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_app/home.dart';
import 'package:mobile_app/main.dart';
import 'package:image_picker/image_picker.dart';

class Groups extends StatelessWidget {
  const Groups({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController cmntController = TextEditingController();
  TextEditingController descController = TextEditingController();
  //group examples
  var _groupList = [
    [
      "First group :)", 
      "Public", 
      "leh3003@wellcoach.org",
      "my first group, seeing how it works"
    ],
    [
      "Bookstores!!",
      "Public",
      "mat202@wellcoach.org",
      "A group for all who love bookstores!!"
    ],
    [
      "Libraries enjoyers",
      "Public",
      "lem111@wellcoach.org",
      "I like books. Do you?"
    ]
  ];
  var _groupEntry = [false, false, false];
  var _pubpriv = false;

Widget _buildPopupDialog(BuildContext context) {
  // local state for the dialog only
  String visibilityValue = _pubpriv ? 'Private' : 'Public';

  return StatefulBuilder(
    builder: (dialogCtx, setStateSB) {
      return AlertDialog(
        title: const Text('Group Creation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: cmntController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Group Name',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: null,
              controller: descController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 8),

            // Visibility dropdown that rebuilds inside the dialog
            Row(
              children: [
                const Text('Visibility:  '),
                DropdownButton<String>(
                  value: visibilityValue,
                  items: const [
                    DropdownMenuItem(value: 'Public',  child: Text('Public')),
                    DropdownMenuItem(value: 'Private', child: Text('Private')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setStateSB(() {
                      visibilityValue = v; // updates the dialog UI immediately
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
            child: const Text('Create'),
            onPressed: () {
              final name = cmntController.text.trim();
              final desc = descController.text.trim();
              if (name.isEmpty) return;

              // persist selection back to the page state if you want
              setState(() => _pubpriv = (visibilityValue == 'Private'));

              final creatorEmail = auth?.email ?? 'unknown@wellcoach.org';

              setState(() {
                _groupList.add([
                  name,
                  visibilityValue,   // use the dialog’s current value
                  creatorEmail,
                  desc,
                ]);
                _groupEntry.add(false);
              });

              cmntController.clear();
              descController.clear();
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Created "$name" ($visibilityValue)')),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
            child: const Text('Close'),
            onPressed: () {
              cmntController.clear();
              descController.clear();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  Widget _buildGroupDialog(BuildContext context, index) {
    return AlertDialog(
      title: const Text('Group Description'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_groupList[index][3],
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            setState(() {
  _groupEntry[index] = true;
});
Navigator.of(context).pop();
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Joined "${_groupList[index][0]}"')),
);

          },
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
          child: const Text('Join'),
        ),
        ElevatedButton(
          onPressed: () {
            // your codes begin here
            Navigator.of(context).pop();


            // end
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Location",
        home: Scaffold(
            backgroundColor: Colors.lightGreen[100],
            body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("lib/assets/mountain.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen.shade300,
                              minimumSize: Size(64, 64),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50.0),
                                  side: BorderSide(
                                      color: Colors.lightGreen.shade300)),
                            ),
                            child: Icon(
                              Icons.home,
                              size: 30.0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Home()),
                              );
                            },
                          ),
                          SizedBox(width: 60),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade300),
                            child: const Text('Create a Group'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    _buildPopupDialog(context),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Existing Groups",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.indigo.shade300),
                      ),
                      SizedBox(height: 20),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                                height: 30,
                                width: 380,
                                alignment: Alignment.center,
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                          width: 95,
                                          child: Text(
                                            "Name",
                                            style: TextStyle(
                                                color: Colors.indigo.shade500),
                                          )),
                                      Container(
                                          width: 75,
                                          child: Text(
                                            "Visibility",
                                            style: TextStyle(
                                                color: Colors.indigo.shade500),
                                          )),
                                      Container(
                                          width: 110,
                                          child: Text(
                                            "Creator",
                                            style: TextStyle(
                                                color: Colors.indigo.shade500),
                                          )),
                                      Container(width: 95, child: Text("")),
                                    ])),
                          ]),
                      Divider(color: Colors.black),
                      Expanded(
                          child: SizedBox(
                        height: 200.0,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _groupList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Container(
                                      height: 70,
                                      width: 380,
                                      alignment: Alignment.center,
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                                width: 95,
                                                child: Text(
                                                  _groupList[index][0],
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors
                                                          .indigo.shade500),
                                                )),
                                            Container(
                                                width: 50,
                                                child: Text(
                                                  _groupList[index][1],
                                                  style: TextStyle(
                                                      color: Colors
                                                          .indigo.shade500),
                                                )),
                                            Container(
                                                width: 110,
                                                child: Text(
                                                  _groupList[index][2],
                                                  style: TextStyle(
                                                      color: Colors
                                                          .indigo.shade500),
                                                )),
                                            Container(
                                              width: 95,
                                              child: _groupEntry[index] == false
                                                  ? _groupList[index][1] ==
                                                          "Public"
                                                      ? ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .indigo
                                                                          .shade300),
                                                          child: Text(
                                                              'Join Group',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize:
                                                                      12)),
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (BuildContext
                                                                      context) =>
                                                                  _buildGroupDialog(
                                                                      context,
                                                                      index),
                                                            );
                                                          },
                                                        )
                                                      : ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .indigo
                                                                          .shade300),
                                                          child:
                                                              Icon(Icons.check),
                                                          onPressed: () => {},
                                                        )
                                                  : ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  Colors.indigo
                                                                      .shade300),
                                                      child: Icon(Icons.check),
                                                      onPressed: () => {},
                                                    ),
                                            )
                                          ])),
                                ]);
                          },
                        ),
                      ))
                    ],
                  ),
                )))));
  }
}