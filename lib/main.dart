import 'dart:collection';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:leave_tracker/login.dart';
import 'package:leave_tracker/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(LeaveTracker());
}

class LeaveTracker extends StatefulWidget {
  LeaveTracker({Key key}) : super(key: key);

  @override
  _LeaveTrackerState createState() => _LeaveTrackerState();
}

class _LeaveTrackerState extends State<LeaveTracker> {
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((_prefs) {
      setState(() {
        prefs = _prefs;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leave Tracker',
      theme: ThemeData(
        brightness: (prefs != null && prefs.getBool('dark') == true)
            ? Brightness.dark
            : Brightness.light,
        primarySwatch: Colors.blue,
      ),
      home: Tracker(),
    );
  }
}

class Tracker extends StatefulWidget {
  Tracker({Key key, this.email}) : super(key: key);
  final String email;

  @override
  _TrackerState createState() => _TrackerState(email);
}

class _TrackerState extends State<Tracker> {
  _TrackerState(this.email);

  SharedPreferences prefs;
  String email;
  CalendarController _calendarController;
  Map<DateTime, List> events = {};
  List<Map<dynamic, dynamic>> employees = [], managers = [];
  List<Map> onLeave = [];
  Map<dynamic, dynamic> currentEmployee;

  listenForEvents() async {
    var ref = FirebaseDatabase.instance.reference().child('events');
    ref.onValue.listen((onData) {
      setState(() {
        var _events = onData.snapshot.value ?? {};
        if (_events.isNotEmpty) {
          _events.keys.forEach((_dt) {
            if (_events[_dt] is List) {
              events[DateTime.parse(_dt)] = _events[_dt].sublist(1);
            } else {
              events[DateTime.parse(_dt)] = List.from(_events[_dt].values);
            }
          });
        }
      });
    });
  }

  getEmployees() async {
    var ref = FirebaseDatabase.instance.reference().child('employees');
    var snapshot = await ref.once();
    var _employees = snapshot.value.sublist(1);
    employees = _employees.cast<Map<dynamic, dynamic>>().toList();
    if (email != null) {
      currentEmployee =
          employees.where((employee) => employee['email'] == email).first;
    }
    setState(() {});
  }

  getManagers() async {
    var ref = FirebaseDatabase.instance.reference().child('managers');
    var snapshot = await ref.once();
    managers = List<Map<dynamic, dynamic>>.from(snapshot.value.sublist(1));
    if (managers == null) managers = [];
    setState(() {});
  }

  getManagerByEmail(String email) {
    return managers.where((manager) => manager['email'] == email).first;
  }

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    getManagers();
    getEmployees();
    listenForEvents();
    SharedPreferences.getInstance().then((_prefs) {
      setState(() {
        prefs = _prefs;
        if (prefs.containsKey('email')) {
          email = prefs.getString('email');
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Login()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  String initials(String name) {
    var splits = name.split(' ');
    if (splits.length == 1) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return "${splits[0][0]}${splits[1][0]}".toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentEmployee == null)
      return Scaffold(
          body: Center(
              child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator())));
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Tracker'),
        actions: <Widget>[
          FlatButton(
            textColor: Colors.white,
            child: Text(prefs.getBool('dark') == true ? 'LIGHT' : 'DARK'),
            onPressed: () async {
              await prefs.setBool('dark', !(prefs.getBool('dark') == true));
              runApp(LeaveTracker());
            },
          ),
          FlatButton(
            textColor: Colors.white,
            child: Text('LOGOUT'),
            onPressed: () async {
              await prefs.clear();
              await prefs.setBool('dark', false);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Login()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
          child: Column(
              children: <Widget>[
        currentEmployee != null && currentEmployee.keys.length != 0
            ? Padding(
                padding: EdgeInsets.only(top: 30, bottom: 10),
                child: Text(
                  "Welcome ${currentEmployee['name']}!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ))
            : Container(
                height: 0,
                width: 0,
              ),
        new Builder(builder: (BuildContext context) {
          return TableCalendar(
            events: events,
            builders: CalendarBuilders(
                markersBuilder: (context, date, events, holidays) {
              final children = <Widget>[];
              if (events.isNotEmpty) {
                children.add(
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                        alignment: Alignment.center,
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            color: Colors.yellow, shape: BoxShape.circle),
                        child: Text(events.length.toString())),
                  ),
                );
              }
              return children;
            }),
            calendarStyle: CalendarStyle(
                selectedColor: Colors.blue, todayColor: Colors.green),
            headerStyle: HeaderStyle(
                centerHeaderTitle: true, formatButtonVisible: false),
            availableCalendarFormats: {CalendarFormat.month: 'Month'},
            calendarController: _calendarController,
            onDaySelected: (DateTime _dt, List _onLeave) {
              if (_onLeave.length == 0) {
                setState(() {
                  onLeave = [];
                });
                Scaffold.of(context).showSnackBar(SnackBar(
                  duration: Duration(seconds: 1),
                  content: Text('Everyone\'s available!'),
                ));
              } else {
                setState(() {
                  onLeave = _onLeave.cast<Map<dynamic, dynamic>>();
                });
              }
            },
          );
        }),
      ]..addAll(onLeave.map((obj) => ListTile(
                  title: Text(obj['name'] + ' is on leave.'),
                  onTap: () {
                    showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) {
                          var manager = getManagerByEmail(obj['manager']);
                          return SimpleDialog(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              children: <Widget>[
                                Text(
                                  'Reason',
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(obj['reason']),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Manager Info',
                                  style: TextStyle(fontSize: 18),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text("${manager['name']}"),
                                SizedBox(
                                  height: 5,
                                ),
                                Text("${manager['email']}")
                              ]);
                        });
                  },
                  leading:
                      CircleAvatar(child: Text(initials(obj['name'])))))))),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ScheduleLeave(currentEmployee: currentEmployee)),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
