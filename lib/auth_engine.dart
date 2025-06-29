import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as console;

import 'package:shared_preferences/shared_preferences.dart';


class UserProfile {
  /// USER-PROF-VARS
  String? name, uid, location, phone, pic, fcm, coc;
  bool? completed = false, waiting_order = false;
  double? tokens;
  int? no_orders;
  List<int> liked = [];
  List<String> selfVouchers = [];

  /*
  * When ever you want to add a firestore value for the user profile that is readable from the shared_preferences and firestore, you should add them in the VARS-area
  * and then to the toJson(), and then to the fromJson()
  * */
  Map<String, dynamic> toJson() => {
    'n' : name, 'tok' : tokens, 'p' : phone, 'loc' : location, 'pic' : pic, 'comp' : completed, 'fcm' : fcm, 'liked' : liked, 'no_orders' : no_orders,
    'waiting_order' : waiting_order, 'coc' : coc
  };

  Map<String, dynamic> toJsonPref()  {
    return toJson()..addAll({'uid' : uid});
  }

  void fromInstance() {
    final   currUser = FirebaseAuth.instance.currentUser!;
    name =  currUser.displayName!;
    pic  =  currUser.photoURL!;
    uid  =  currUser.uid;
  }

  Future<void> saveToPref() async {
    final pref = await SharedPreferences.getInstance();
    pref.setString('data', jsonEncode(toJsonPref()));
    return;
  }

  void fromJson({required Map<String, dynamic> data, bool? pref}) {
    liked.clear();
    selfVouchers.clear();
    name = data['n'];
    pic = data['pic'];
    location = data['loc'];
    tokens = data['tok'];
    phone = data['p'];
    completed = data['comp'];
    waiting_order = data['waiting_order'];
    no_orders = data['no_orders'];
    coc = data['coc'];
    final likedPlaceholder = data['liked'] as List<dynamic>;
    // final selfVouchersPlaceholder = data['self-vouchers'] as List<dynamic>;

    // for(final item in selfVouchersPlaceholder) {
    //   selfVouchers.add(item as String);
    // }

    for(final item in likedPlaceholder) {
      liked.add(item as int);
    }

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

  /*
   * a tailor-made simple function to update the self-vouchers on the firestore-client side, whether remove or add, it's called from [addSelfVoucher, removeVoucher]
   */
  // Future<void> updateVouchersInCloud() async {
  //   await FirebaseFirestore.instance.collection('app-users').doc(uid).set({'self-vouchers' : selfVouchers}, SetOptions(merge: true));
  //   await saveToPref();
  // }

  Future<void> loadVouchers() async {
    final _ref = FirebaseFirestore.instance.collection('app-users').doc(uid);
    final firestoreRes = await _ref.get();
    try {
      selfVouchers = List<String>.from(firestoreRes.get('self-vouchers') ?? []);
    } catch (err) {
      _ref.set({'self-vouchers' : <String>[]}, SetOptions(merge: true));
      selfVouchers = <String>[];
    }
  }

  /*
   * if the selfVouchers already contains the voucher return (this case is simply impossible, but why not), else add it to the string list and then call (updateVouchersInCloud)
   * Removed this future, since the voucher string code is updated from the server-side to the firestore collection directly
   * only keeping removeVoucher, and added the loadVouchers to load the vouchers from the firestore
   */ 
  // Future<void> addSelfVoucher(String voucher) async {
  //   if (selfVouchers.contains(voucher)) return;
  //   selfVouchers.add(voucher);
  //   updateVouchersInCloud();
  // }

  /*
  * if the vouchers are empty (which is also semi-impossible case) return, else search and remove, then call db-update
  * */
  Future<void> removeVoucher(String voucher) async {
    if (selfVouchers.isEmpty) return;
    selfVouchers.remove(voucher);
    FirebaseFirestore.instance.collection('app-users').doc(uid).update({
      'self-vouchers' : FieldValue.arrayRemove([voucher])
    });
  }

  /*
  * takes the json format of all the user data [toJson()] (with out updating the FCM since the fcm automatically updates on each launch) and then merge all the changes
  * */
  Future<void> saveToCloud() async {
    final uploadData = toJson();
    uploadData.remove('fcm');
    FirebaseFirestore.instance.collection('app-users').doc(uid).set(uploadData, SetOptions(merge: true));
  }

  /*
   * get all the data for the user using the user id from the firestore side, then fill the data in the class using the method fromJson()
   */
  Future<void> fromCloud() async {
    final cloudData = await FirebaseFirestore.instance.collection('app-users').doc(uid!).get();
    fromJson(data: cloudData.data()!, pref: false);
  }

  /*
   * Update the fcm token on every launch of the app
   */
  Future<void> updateFCM(String? fcm) async {
    FirebaseFirestore.instance.collection('app-users').doc(uid).set({'fcm' : fcm}, SetOptions(merge: true));
  }

  Future<void> update({
    String? name,
    String? pic,
    String? location,
    String? phone,
    String? coc,
    double? tokens,
    int? no_orders,
    bool? completed,
    bool? waiting_order,
    bool? mergeNull
  }) async {
    final mN = mergeNull ?? false;
    if (name          != null || mN) this.name = name;
    if (pic           != null || mN) this.pic = pic;
    if (location      != null || mN) this.location = location;
    if (phone         != null || mN) this.phone = phone;
    if (tokens        != null || mN) this.tokens = tokens;
    if (completed     != null || mN) this.completed = completed;
    if (no_orders     != null || mN) this.no_orders = no_orders;
    if (waiting_order != null || mN) this.waiting_order = waiting_order;
    if (coc != null) this.coc = coc;
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
      // userProfile.update(completed: true);

      return AuthResult(userProfile.completed! ? CheckResult.SUCCESS : CheckResult.FIRST_TIME, 'IF FIRST_TIME user profile value for completed is false ${userProfile.completed}');
    } catch (err) {
      print('ERROR ---> $err');
      return AuthResult(CheckResult.ERROR, '${err}');
    }
  }

  static Future<void> signOut() async {
    FirebaseAuth.instance.signOut();
    GoogleSignIn().signOut();
    final pref = await SharedPreferences.getInstance();
    pref.clear();
    return;
  }

  // Future<AuthResult> loginFacebook() async {
  //   try {
  //     final response = await FacebookAuth.instance.login(permissions: ['public_profile']);

  //     if (response.status == LoginStatus.success) {
  //       final accessToken = response.accessToken;
  //       final userData = await FacebookAuth.instance.getUserData();
  //     }

  //     // return AuthResult(userProfile.completed ? CheckResult.SUCCESS : CheckResult.FIRST_TIME, '');
  //     return AuthResult(CheckResult.ERROR, '---- TEST ----');
  //   } catch (err) {
  //     return AuthResult(CheckResult.ERROR, '$err');
  //   }
  // }

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
      print('from cloud --> completed ? ${userProfile.completed}');
      return AuthResult(userProfile.completed! ? CheckResult.SUCCESS : CheckResult.FIRST_TIME, '$signInResult');
    } catch(err) {
      return AuthResult(CheckResult.ERROR, '$err');
    }
  }

  static String appChannelId    = 'route_65_channel',
                appChannelName  = 'Route 65 App Channel';


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
      lang = (await langFile.readAsString()).toUpperCase();
    } finally {}

    AndroidNotificationDetails? androidDetails;
    DarwinNotificationDetails? iosDetails;
    try {
      File saveFile = File('${path.path}/notifications_primary.jgp');

      final Uri imageUrl = Uri.parse(message.notification!.android!.imageUrl!);
      final imageResponse = await http.get(imageUrl);
      await saveFile.writeAsBytes(imageResponse.bodyBytes);

      androidDetails = AndroidNotificationDetails(
          appChannelId,
          appChannelName,
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap('${path.path}/notifications_primary.jgp'),
            largeIcon: FilePathAndroidBitmap('${path.path}/icon_primary.png'),
          )
      );

      iosDetails = DarwinNotificationDetails(

      );
    } catch (e) {
      console.log('creating normal notification without image --> ${e}');
      androidDetails = AndroidNotificationDetails(
          appChannelId,
          appChannelName,
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
    final langIndex = lang == 'AR' ? 1 : 0;

    FlutterLocalNotificationsPlugin().show(
      message.notification.hashCode,
      titles[langIndex],
      bodies[langIndex],
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