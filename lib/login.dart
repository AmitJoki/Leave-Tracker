import 'package:flutter/material.dart';
import 'package:leave_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => new _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _email = TextEditingController();
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
    return new Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              child: Stack(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.fromLTRB(15.0, 110.0, 0.0, 0.0),
                    child: Text('Hello',
                        style: TextStyle(
                            fontSize: 80.0, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(16.0, 175.0, 0.0, 0.0),
                    child: Text('There',
                        style: TextStyle(
                            fontSize: 80.0, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(220.0, 175.0, 0.0, 0.0),
                    child: Text('.',
                        style: TextStyle(
                            fontSize: 80.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                  )
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 35.0, left: 20.0, right: 20.0),
              child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        validator: (email) {
                          Pattern pattern =
                              r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                          RegExp regex = new RegExp(pattern);
                          if (!regex.hasMatch(email))
                            return 'Enter valid email';
                          else if (!new RegExp(r'[1-5]@coda.global',
                                  caseSensitive: false)
                              .hasMatch(email)) {
                            return email + ' is not registered.';
                          } else
                            return null;
                        },
                        controller: _email,
                        decoration: InputDecoration(
                            labelText: 'EMAIL',
                            helperText: 'Hint: [1 to 5]@coda.global',
                            labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue))),
                      ),
                      SizedBox(height: 20.0),
                      TextFormField(
                        validator: (password) {
                          if (password.isEmpty)
                            return 'Password cannot be empty!';
                          else if (password != 'CODA') {
                            return 'Invalid credentials';
                          } else
                            return null;
                        },
                        decoration: InputDecoration(
                            labelText: 'PASSWORD',
                            helperText: 'Hint: CODA',
                            labelStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.blue))),
                        obscureText: true,
                      ),
                      SizedBox(height: 40.0),
                      SizedBox(
                          width: double.infinity,
                          child: RaisedButton(
                            color: Colors.blue,
                            textColor: Colors.white,
                            child: Center(
                              child: Text(
                                'LOGIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState.validate()) {
                                prefs.setString(
                                    'email', _email.text.toLowerCase());
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Tracker(
                                            email: _email.text.toLowerCase(),
                                          )),
                                );
                              }
                            },
                          )),
                    ],
                  )),
            )
          ],
        ));
  }
}
