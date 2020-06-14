import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:leave_tracker/main.dart';
import 'package:share/share.dart';

class ScheduleLeave extends StatefulWidget {
  final Map<dynamic, dynamic> currentEmployee;
  ScheduleLeave({@required this.currentEmployee});
  @override
  _ScheduleLeaveState createState() => _ScheduleLeaveState();
}

class _ScheduleLeaveState extends State<ScheduleLeave> {
  DateTime _when;
  List<Map<dynamic, dynamic>> managers = [];
  Map<dynamic, dynamic> selectedManager = {};
  TextEditingController _reason = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  initState() {
    super.initState();
    getManagers();
  }

  getManagers() async {
    var ref = FirebaseDatabase.instance.reference().child('managers');
    var snapshot = await ref.once();
    var _managers = snapshot.value.sublist(1);
    managers = _managers.cast<Map<dynamic, dynamic>>().toList();
    setState(() {});
  }

  scheduleLeave() async {
    var ref = FirebaseDatabase.instance.reference().child('events');
    var newEvent = ref
        .child(_when.toIso8601String().substring(0, 10))
        .child(widget.currentEmployee['id'].toString());
    newEvent.update(({
      'name': widget.currentEmployee['name'],
      'reason': _reason.text,
      'manager': selectedManager['email']
    }));
  }

  static const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  formattedDate(DateTime when) {
    return "${when.day.toString().padLeft(2, '0')} ${months[when.month]}, ${when.year}";
  }

  @override
  Widget build(BuildContext context) {
    var tomorrow = DateTime.parse(DateTime.now()
        .add(Duration(days: 1))
        .toIso8601String()
        .substring(0, 10));

    return Scaffold(
      appBar: AppBar(title: Text('Schedule Leave')),
      body: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              ListTile(
                  title: FormField(validator: (val) {
                if (val == null) {
                  return "Date needed!";
                }
                return null;
              }, builder: (FormFieldState<dynamic> state) {
                return RaisedButton.icon(
                  icon: Icon(
                    Icons.date_range,
                    size: 16,
                  ),
                  textColor: state.hasError ? Colors.red : Colors.blue,
                  color: Colors.white,
                  elevation: 5,
                  label: Text(
                      _when == null ? 'CHOOSE THE DATE' : formattedDate(_when)),
                  onPressed: () async {
                    _when = await showDatePicker(
                        context: context,
                        initialDate: tomorrow,
                        firstDate: tomorrow,
                        lastDate: DateTime(2101));
                    state.setValue(_when);
                    setState(() {});
                  },
                );
              })),
              ListTile(
                  title: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: DropdownButtonFormField<String>(
                        value: selectedManager['email'],
                        hint: Text('Select Manager'),
                        validator: (val) {
                          if (val == null) {
                            return "Select the manager!";
                          }
                          return null;
                        },
                        items: managers.map((Map<dynamic, dynamic> value) {
                          return DropdownMenuItem<String>(
                            value: value['email'],
                            child: Text(value['name']),
                          );
                        }).toList(),
                        onChanged: (_) {
                          setState(() {
                            selectedManager = managers
                                .where((manager) => manager['email'] == _)
                                .first;
                          });
                        },
                      ))),
              ListTile(
                  title: TextFormField(
                controller: _reason,
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Reason should not be empty!';
                  }
                  return null;
                },
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                    hintText: 'What is the reason for the leave?'),
              )),
              ListTile(
                  title: SizedBox(
                      width: double.infinity,
                      child: RaisedButton(
                        color: Colors.blue,
                        textColor: Colors.white,
                        child: Center(
                          child: Text(
                            'POST LEAVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            scheduleLeave();
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return SimpleDialog(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      children: <Widget>[
                                        Text(
                                          'Scheduled successfully.',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        RaisedButton(
                                          color: Colors.deepPurple,
                                          textColor: Colors.white,
                                          child: Text('Share on Slack'),
                                          onPressed: () {
                                            Share.share(
                                                "I will be on leave on ${formattedDate(_when)}",
                                                subject: 'Intimation of Leave');
                                          },
                                        ),
                                        RaisedButton(
                                            color: Colors.red,
                                            textColor: Colors.white,
                                            onPressed: () async {
                                              final Email email = Email(
                                                body:
                                                    "I will be on leave on ${formattedDate(_when)}",
                                                subject: 'Intimation of Leave',
                                                recipients: [
                                                  selectedManager['email']
                                                ],
                                                isHTML: false,
                                              );

                                              await FlutterEmailSender.send(
                                                  email);
                                            },
                                            child: Text('Email')),
                                        RaisedButton(
                                          color: Colors.blue,
                                          textColor: Colors.white,
                                          child: Text('Home'),
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        Tracker()));
                                          },
                                        )
                                      ]);
                                });
                          }
                        },
                      )))
            ],
          )),
    );
  }
}
