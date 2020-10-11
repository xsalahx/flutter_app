import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:date_field/date_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:cloud_functions/cloud_functions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(App());
}

// ignore: must_be_immutable
class App extends StatelessWidget {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User>(
      stream: _auth.authStateChanges(),
      builder: (BuildContext context,AsyncSnapshot<User> snapshot) {
        if (snapshot.hasData){
          return Home();
        }else{
          return MaterialApp(home: Authenticate());
        }
      },
    );
  }
}

class Home extends StatelessWidget {

  final FirebaseAuth _auth = FirebaseAuth.instance;


  double amount = 0;
  String receiver = "";

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('HOME'),
          actions: [
            RaisedButton(
              onPressed: () => _auth.signOut(),
              child: Text('logout'),
            )
          ],
        ),
        body: Column(
          children: [
            StreamBuilder(
              stream: FirebaseFirestore.instance.collection("balances").doc(_auth.currentUser.uid).snapshots(),
              builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot){
                if(snapshot == null){
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return Center(
                  child: Text(snapshot.data.data().toString()),
                );
              },
            ),
            Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    hintText: "E-mail",
                  ),
                  onChanged: (val) => receiver = val,
                ),
                TextFormField(
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: "Amount",
                  ),
                  onChanged: (val) => amount = double.parse(val),
                )
              ],
            ),
            RaisedButton(
              onPressed: () async {

                final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
                  functionName: 'addMessage',
                );
                dynamic resp = await callable.call(<String, dynamic>{
                  'text': 'mobile msg',
                });

                print(resp.data);
              },
              child: Text('SEND'),
            ),
          ],
        ),
      ),
    );
  }
}


class Authenticate extends StatefulWidget {
  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  @override
  Widget build(BuildContext context) {

    String email = '';
    String password = '';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Signing UP"),
          actions: [
            RaisedButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => Register()),
                );
              },
              child: Text("Register"),
            ),
          ],
        ),
        body: Form(
          child: Column(
            children: [
              TextFormField(
                onChanged: (val) => email = val,
              ),
              TextFormField(
                onChanged: (val) => password = val,
              ),
              RaisedButton(
                onPressed: () async {
                  signInWithEmailAndPassword(email,password);
                },
                child: Text("sign up"),
              ),
              RaisedButton(
                onPressed: () async {
                  var rng = new Random.secure();
                  EthPrivateKey random = EthPrivateKey.createRandom(rng);

                  print(random.privateKey);


                  // Random random = Random.secure();
                  // BigInt privateKey = generateNewPrivateKey(random);
                  // String msg = 'Message';
                  // Uint8List hashedMsg = keccakAscii(msg);
                  // MsgSignature signed = sign(hashedMsg,intToBytes(privateKey));
                  // print('hashed msg : $hashedMsg');
                  // print(signed.r);
                  // print(signed.s);
                  // print(signed.v);
                },
                child: Text("Button"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  UserInfos userInfos = UserInfos();


  _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: userInfos.birthDate, // Refer step 1
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != userInfos.birthDate)
      setState(() {
        userInfos.birthDate = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("REGISTRATION"),
        ),
        body: Form(
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  hintText: "E-mail",
                ),
                onChanged: (val) => userInfos.email = val,
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "password",
                ),
                onChanged: (val) => userInfos.password = val,
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "First name",
                ),
                onChanged: (val) => userInfos.firstName = val,
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "Last name",
                ),
                onChanged: (val) => userInfos.lastName = val,
              ),
              DateTimeField(
                label: 'Birth date',
                mode: DateFieldPickerMode.date,
                selectedDate: userInfos.birthDate,
                lastDate: DateTime.now(),
                onDateSelected: (DateTime date) {
                  setState(() {
                    userInfos.birthDate = date;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "Country",
                ),
                onChanged: (val) => userInfos.country = val,
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "Address",
                ),
                onChanged: (val) => userInfos.address = val,
              ),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "Profession",
                ),
                onChanged: (val) => userInfos.profession = val,
              ),
              RaisedButton(
                onPressed: () async {
                  registerUserWithEmailAndPassword(userInfos);
                },
                child: Text("Register"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

void registerUserWithEmailAndPassword(userInfos) async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserCredential userCredential = await registerWithEmailAndPassword(userInfos.email, userInfos.password);

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference users = firestore.collection("users");
  CollectionReference balances = firestore.collection('balances');

  await balances.doc(userCredential.user.uid).set({
    'balance' : 0,
    'nonce' : 0,
  });

  await users.doc(userCredential.user.uid).set({
    'firstName': userInfos.firstName,
    'lastName' : userInfos.lastName,
    'birthDate' : userInfos.birthDate,
    'country': userInfos.country,
    'address': userInfos.address,
    'profession' : userInfos.profession,
  }) ;

  print("regiter");

}


class UserInfos {

  String email = "";
  String password = "";

  String firstName = "";
  String lastName = "";

  DateTime birthDate = DateTime.now();
  String country = "";
  String address = "";
  String profession = "";

}


void signInWithEmailAndPassword(String email, String password) async {
  UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password
  );
}

Future<UserCredential> registerWithEmailAndPassword(String email ,String password) async {
  UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password
  );
  return userCredential;
}


