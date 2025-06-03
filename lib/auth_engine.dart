


import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as console;

import 'package:shared_preferences/shared_preferences.dart';


class UserProfile {
  String? name, uid, location, phone, pic, fcm;
  bool completed = false;
  double? tokens;
  int? no_orders;
  List<int> liked = [];

  Map<String, dynamic> toJson() => {
    'n' : name, 'tok' : tokens, 'p' : phone, 'loc' : location, 'pic' : pic, 'comp' : completed, 'fcm' : fcm, 'liked' : liked, 'no_orders' : no_orders
  };

  Map<String, dynamic> toJsonPref()  {
    return toJson()..addAll({'uid' : uid});
  }

  void fromInstance() {
    final currUser = FirebaseAuth.instance.currentUser!;
    name = currUser.displayName!;
    pic = currUser.photoURL!;
    uid = currUser.uid;
  }

  Future<void> saveToPref() async {
    final pref = await SharedPreferences.getInstance();
    pref.setString('data', jsonEncode(toJsonPref()));

    return;
  }

  void fromJson({required Map<String, dynamic> data, bool? pref}) {
    liked.clear();
    name = data['n'];
    pic = data['pic'];
    location = data['loc'];
    tokens = data['tok'];
    phone = data['p'];
    completed = data['comp'];
    no_orders = data['no_orders'];
    final likedPlaceholder = data['liked'] as List<dynamic>;
    for(final item in likedPlaceholder) liked.add(int.parse('$item'));
    if(pref != null && pref) uid = data['uid'];
  }

  Future<bool> changeLiked(int id) async {
    bool r = false;
    for (int i=0;i<liked.length;++i) {
      if (liked[i] == id) {
        r = true;
        liked.removeAt(i);
        break;
      }
    }

    if (!r) {
      liked.add(id);
    }

    FirebaseFirestore.instance.collection('app-users').doc(uid).set({'liked' : liked}, SetOptions(merge: true));
    await saveToPref();

    return r;
  }

  Future<void> loadFromPref() async{
    final pref = await SharedPreferences.getInstance();
    final data = jsonDecode(pref.getString('data')!);
    fromJson(data: data, pref: true);
  }

  Future<void> saveToCloud() async {
    final uploadData = toJson();
    uploadData.remove('fcm');
    FirebaseFirestore.instance.collection('app-users').doc(uid).set(uploadData, SetOptions(merge: true));
  }

  Future<void> fromCloud() async {
    final cloudData = await FirebaseFirestore.instance.collection('app-users').doc(uid!).get();
    fromJson(data: cloudData.data()!, pref: false);
  }

  Future<void> updateFCM(String? fcm) async {
    FirebaseFirestore.instance.collection('app-users').doc(uid).set({'fcm' : fcm}, SetOptions(merge: true));
  }

  Future<void> update({String? name, String? pic, String? location, String? phone, double? tokens, int? no_orders, bool? completed}) async {
    if (name != null) this.name = name;
    if (pic != null) this.pic = pic;
    if (location != null) this.location = location;
    if (phone != null) this.phone = phone;
    if (tokens != null) this.tokens = tokens;
    if (completed != null) this.completed = completed;
    if (no_orders != null) this.no_orders = no_orders;

    await saveToPref();
    await saveToCloud();
  }
}

enum CheckResult {
  SUCCESS,
  FIRST_TIME,
  ERROR
}

class AuthResult {
  late CheckResult status;
  late String content;

  AuthResult(this.status, this.content);
}

class AuthEngine {
  final instance = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final userProfile = UserProfile();

  Future<AuthResult> checkLogin() async {
    try {
      if (instance.currentUser == null) {
        return AuthResult(CheckResult.ERROR, 'CURRENT USER NULL');
      }

      final pref = await SharedPreferences.getInstance();

      if (!pref.containsKey('data')) {
        return AuthResult(CheckResult.ERROR, 'PREF DATA DOES NOT EXIST');
      }

      await userProfile.loadFromPref();

      return AuthResult(userProfile.completed ? CheckResult.SUCCESS : CheckResult.FIRST_TIME, 'DONE');
    } catch (err) {
      return AuthResult(CheckResult.ERROR, '${err}');
    }
  }

  Future<AuthResult> loginFacebook() async {
    try {
      final response = await FacebookAuth.instance.login(permissions: ['public_profile']);

      if (response.status == LoginStatus.success) {
        final accessToken = response.accessToken;
        final userData = await FacebookAuth.instance.getUserData();
      }

      // return AuthResult(userProfile.completed ? CheckResult.SUCCESS : CheckResult.FIRST_TIME, '');
      return AuthResult(CheckResult.ERROR, '---- TEST ----');
    } catch (err) {
      return AuthResult(CheckResult.ERROR, '$err');
    }
  }

  Future<AuthResult> loginGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final signInResult = await googleSignIn.signIn();
      final auth = await signInResult!.authentication;
      final cred = GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken);
      await instance.signInWithCredential(cred);

      userProfile.fromInstance();

      console.log('USER PROFILE ---> ${userProfile.uid}');

      final cloudData = await firestore.collection('app-users').doc(userProfile.uid!).get();
      console.log('CLOUD DATA ---> ${cloudData.exists}');

      if (!cloudData.exists) {
        await userProfile.saveToCloud();
        return AuthResult(CheckResult.FIRST_TIME, '');
      }

      await userProfile.fromCloud();
      return AuthResult(userProfile.completed ? CheckResult.SUCCESS : CheckResult.FIRST_TIME, '$signInResult');
    } catch(err) {
      return AuthResult(CheckResult.ERROR, '$err');
    }
  }


  static void showLocalNotification(RemoteMessage message) async {
    final path = await getApplicationDocumentsDirectory();

    console.log('PATH ---> $path');
    String lang = 'AR';
    try {
      File saveFile = File('${path.path}/icon_primary.png');
      if (!(await saveFile.exists())) {
        final Uri imageUrl = Uri.parse(
            'https://www.route-65-dashboard.com/logo.png');
        final imageResponse = await http.get(imageUrl);
        await saveFile.writeAsBytes(imageResponse.bodyBytes);
      }

      File langFile = File('${path.path}/language.config');
      lang = await langFile.readAsString();
    } finally {}

    AndroidNotificationDetails? androidDetails;
    try {
      File saveFile = File('${path.path}/notifications_primary.jgp');
      if(true){
        final Uri imageUrl = Uri.parse(message.notification!.android!.imageUrl!);
        final imageResponse = await http.get(imageUrl);
        await saveFile.writeAsBytes(imageResponse.bodyBytes);

        androidDetails = AndroidNotificationDetails(
            'channel_id',
            'channel_name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap('${path.path}/notifications_primary.jgp'),
              largeIcon: FilePathAndroidBitmap('${path.path}/icon_primary.png'),
            )
        );
      }
    } catch (e) {
      console.log('creating normal notification without image --> ${e}');
      androidDetails = AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
      );
    }

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    List<dynamic> titles = [], bodies = [];

    titles = jsonDecode(message.notification!.title!);
    bodies = jsonDecode(message.notification!.body!);

    FlutterLocalNotificationsPlugin().show(
      message.notification.hashCode,
      titles[lang == 'ar' ? 1 : 0],
      bodies[lang == 'ar' ? 1 : 0],
      notificationDetails,
    );
  }
}

class PhoneNumberFormatter{
  static Map<String, String> mapping = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };
}