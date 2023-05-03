import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'cheese.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('ic_launcher');
InitializationSettings initializationSettings =
    const InitializationSettings(android: androidInitializationSettings);

final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();

enum Tasks {
  dailyCheese,
}

Future<Uint8List> _getByteArrayFromUrl(String url) async {
  final http.Response response = await http.get(Uri.parse(url));
  return response.bodyBytes;
}

sendDailyCheeseNotification(Map<String, dynamic> cheeseJson) async {
  final cheese = Cheese.fromJson(cheeseJson);

  print(cheeseJson);

  final cheeseImage =
      ByteArrayAndroidBitmap(await _getByteArrayFromUrl(cheese.imageURL));
  final BigPictureStyleInformation styleInformation =
      BigPictureStyleInformation(cheeseImage);

  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'Daily Cheese',
    'Daily Cheese',
    channelDescription: "Channel for daily cheese",
    importance: Importance.high,
    priority: Priority.high,
    largeIcon: cheeseImage,
    styleInformation: styleInformation,
  );
  NotificationDetails notifDetails =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
      0,
      "Today's cheese is: ${cheese.name}",
      'Tap to read all about it',
      notifDetails,
      payload: convert.jsonEncode(cheeseJson));
}

Future<void> fetchDailyCheese() async {
  final Uri baseUrl = Uri.https('api.illusionman1212.com', '/cheese/today');
  var res = await http.get(baseUrl);
  if (res.statusCode == 200) {
    final jsonRes = convert.jsonDecode(res.body) as Map<String, dynamic>;

    await sendDailyCheeseNotification(jsonRes['cheese']);
  } else {
    print("error while fetching daily cheese");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AndroidAlarmManager.initialize();

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse? response) async {
    selectNotificationSubject.add(response?.payload);
  });

  final now = DateTime.now().toUtc();
  Duration timeTill2PMUTC = const Duration();

  if (now.hour < 14) {
    timeTill2PMUTC = now
        .difference(DateTime.utc(now.year, now.month, now.day, 14, 0, 0))
        .abs();
  } else if (now.hour >= 14) {
    final nextDay = now.add(const Duration(days: 1));
    timeTill2PMUTC = now
        .difference(
            DateTime.utc(nextDay.year, nextDay.month, nextDay.day, 14, 0, 0))
        .abs();
  }

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  final notifLaunch =
      notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;
  final notifResponse = notificationAppLaunchDetails?.notificationResponse;

  await AndroidAlarmManager.periodic(
    const Duration(hours: 24), Tasks.dailyCheese.index, fetchDailyCheese,
    allowWhileIdle: true, rescheduleOnReboot: true, exact: true, wakeup: true,
    startAt: DateTime.now().toUtc().add(Duration(seconds: timeTill2PMUTC.inSeconds)),
  );

  runApp(Appease(
      initialRoute: notifLaunch ? CheeseDetails.routeName : '/',
      notifPayload: notifResponse?.payload));
}

class Appease extends StatelessWidget {
  final String initialRoute;
  final String? notifPayload;

  const Appease({Key? key, required this.initialRoute, this.notifPayload})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appease',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  const HomePage(title: 'Appease: Daily Cheese'),
              transitionsBuilder: (c, anim, a2, child) =>
                  FadeTransition(opacity: anim, child: child),
            );
          case CheeseDetails.routeName:
            if (initialRoute == CheeseDetails.routeName) {
              return PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const CheeseDetails(),
                  settings: RouteSettings(
                      arguments: CheeseDetailsArgs(
                          Cheese.fromJson(convert.jsonDecode(notifPayload!),
                          ),
                      ),
                  ),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
              );
            }

            return PageRouteBuilder(
              pageBuilder: (_, __, ___) => const CheeseDetails(),
              settings: RouteSettings(arguments: settings.arguments),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            );
          default:
            return null;
        }
      },
      initialRoute: initialRoute,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool fetchingRandom = false;
  bool fetchingDaily = false;

  Future<void> getAllCheeses() async {
    // TODO: get all cheeses
  }

  Future<void> getDailyCheese() async {
    setState(() {
      fetchingDaily = true;
    });

    final Uri baseUrl = Uri.https('api.illusionman1212.com', '/cheese/today');
    var res = await http.get(baseUrl);
    if (res.statusCode == 200) {
      final jsonRes = convert.jsonDecode(res.body) as Map<String, dynamic>;
      Cheese cheese = Cheese.fromJson(jsonRes['cheese']);

      setState(() {
        fetchingDaily = false;
      });

      if (!mounted) return;

      await Navigator.pushNamed(context, CheeseDetails.routeName,
          arguments: CheeseDetailsArgs(cheese));
    } else {
      print('error while getting daily cheese');
      setState(() {
        fetchingDaily = false;
      });
    }
  }

  Future<void> getRandomCheese() async {
    setState(() {
      fetchingRandom = true;
    });

    Uri uri = Uri.https('api.illusionman1212.com', '/cheese/random');
    var res = await http.get(uri);
    if (res.statusCode == 200) {
      final jsonRes = convert.jsonDecode(res.body) as Map<String, dynamic>;
      Cheese cheese = Cheese.fromJson(jsonRes['cheese']);

      setState(() {
        fetchingRandom = false;
      });

      if (!mounted) return;

      await Navigator.pushNamed(context, CheeseDetails.routeName,
          arguments: CheeseDetailsArgs(cheese));
    } else {
      print('error while getting random cheese');
      setState(() {
        fetchingRandom = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _configureSelectNotificationSubject();
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String? payload) async {
      if (payload != null) {
        final cheese = Cheese.fromJson(
            convert.jsonDecode(payload) as Map<String, dynamic>);

        await Navigator.pushNamed(context, CheeseDetails.routeName,
            arguments: CheeseDetailsArgs(cheese));
      }
    });
  }

  @override
  void dispose() {
    selectNotificationSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: Svg(
                  'assets/cheese-default.svg',
                  size: Size(MediaQuery.of(context).size.width - 150,
                      MediaQuery.of(context).size.height - 150),
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Wrap(
                    spacing: 20,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                          onPressed: fetchingDaily
                              ? null
                              : () async => await getDailyCheese(),
                          child: RichText(
                              text: TextSpan(
                            text: 'Daily cheese',
                            children: [
                              if (fetchingDaily)
                                const WidgetSpan(
                                    child: Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.black, strokeWidth: 3)),
                                ))
                            ],
                            style: const TextStyle(color: Colors.black),
                          ))),
                      ElevatedButton(
                          onPressed: fetchingRandom
                              ? null
                              : () async => await getRandomCheese(),
                          child: RichText(
                              text: TextSpan(
                            text: 'Random cheese',
                            children: [
                              if (fetchingRandom)
                                const WidgetSpan(
                                    child: Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.black, strokeWidth: 3)),
                                ))
                            ],
                            style: const TextStyle(color: Colors.black),
                          ))),
                      ElevatedButton(
                          onPressed: () => getAllCheeses(),
                          child: const Text("All cheeses")),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
