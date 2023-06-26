import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mynotification/http/web.dart';
import 'package:mynotification/models/device.dart';
import 'package:mynotification/screens/events_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Autorizado.${settings.authorizationStatus}');
    _startPushNotificationHandler(messaging);
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('Concedido provisioriamente.${settings.authorizationStatus} ');
  } else {
    print('Não Autorizado.${settings.authorizationStatus} ');
    _startPushNotificationHandler(messaging);
  }

  runApp(App());
}

void _startPushNotificationHandler(FirebaseMessaging messaging) async {
  String? token = await messaging.getToken();
  print('TOKEN:$token');
  _setPushToken(token);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Dados da mensagem em background: ${message.notification}');
    if (message.notification != null) {
      print(
          'A mensagem contém uma notificação:${message.notification!.title},${message.notification!.body}');
    }
  });
  //Background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //Terminated
  var data = await FirebaseMessaging.instance.getInitialMessage();
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('${message.notification}');
}

void showMyDialog(String message) {
  Widget okButton = OutlinedButton(
    onPressed: () => Navigator.pop(navigatorKey.currentContext!),
    child: const Text('Ok'),
  );
  AlertDialog alerta = AlertDialog(
    title: Text('Novo Plantão'),
    content: Text(message),
    actions: [
      okButton,
    ],
  );
  showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return alerta;
      });
}

void _setPushToken(String? token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? prefsToken = prefs.getString('pushToken');
  bool? prefSent = prefs.getBool('tokenSent');

  if (prefsToken != token || (prefsToken == token && prefSent == false)) {
    print('Enviando token par o servidor...');
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? brand;
    String? model;
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      print('rodando no ${androidInfo.model}');
      model = androidInfo.model;
      brand = androidInfo.brand;
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      print('rodando no ${iosInfo.model}');
      model = iosInfo.model;
      brand = 'Apple';
    }

    Device device = Device(
      brand: brand,
      model: model,
      token: token,
    );

    sendDevice(device);
  } else {
    print('Token já existente!');
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dev meetups',
      home: EventsScreen(),
      navigatorKey: navigatorKey,
    );
  }
}
