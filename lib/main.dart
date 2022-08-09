import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';
import 'package:workmanager/workmanager.dart';

import 'cheese.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('ic_launcher');
InitializationSettings initializationSettings =
    const InitializationSettings(android: androidInitializationSettings);

final BehaviorSubject<String?> selectNotificationSubject =
    BehaviorSubject<String?>();

String? selectedNotificationPayload;

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

Future<bool> fetchDailyCheese() async {
  final Uri baseUrl = Uri.https('api.illusionman1212.tech', '/cheese/today');
  var res = await http.get(baseUrl);
  if (res.statusCode == 200) {
    final jsonRes = convert.jsonDecode(res.body) as Map<String, dynamic>;

    await sendDailyCheeseNotification(jsonRes['cheese']);
    return true;
  } else {
    return false;
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == Tasks.dailyCheese.name) {
      return Future.value(await fetchDailyCheese());
    }

    return Future.error(Exception("Unhandled Task: $task"));
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  Workmanager().cancelByUniqueName(Tasks.dailyCheese.name);

  final now = DateTime.now().toUtc();
  Duration timeTill12PMUTC = const Duration();

  if (now.hour < 12) {
    timeTill12PMUTC = now
        .difference(DateTime.utc(now.year, now.month, now.day, 12, 0, 0))
        .abs();
  } else if (now.hour >= 12) {
    final nextDay = now.add(const Duration(days: 1));
    timeTill12PMUTC = now
        .difference(
            DateTime.utc(nextDay.year, nextDay.month, nextDay.day, 12, 0, 0))
        .abs();
  }

  print("TTL: ${timeTill12PMUTC.inSeconds}");

  Workmanager().registerPeriodicTask(
      Tasks.dailyCheese.name, Tasks.dailyCheese.name,
      frequency: const Duration(hours: 24),
      initialDelay: Duration(seconds: timeTill12PMUTC.inSeconds));

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {
    selectedNotificationPayload = payload;
    selectNotificationSubject.add(payload);
  });

  runApp(const Appease());
}

class Appease extends StatelessWidget {
  const Appease({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appease',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: const HomePage(title: 'Appease: Daily Cheese'),
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

    final Uri baseUrl = Uri.https('api.illusionman1212.tech', '/cheese/today');
    var res = await http.get(baseUrl);
    if (res.statusCode == 200) {
      final jsonRes = convert.jsonDecode(res.body) as Map<String, dynamic>;
      Cheese cheese = Cheese.fromJson(jsonRes['cheese']);

      setState(() {
        fetchingDaily = false;
      });

      if (!mounted) return;

      Navigator.push(context,
          MaterialPageRoute<void>(builder: (context) => CheeseDetails(cheese)));
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

    Uri uri = Uri.https('api.illusionman1212.tech', '/cheese/random');
    var res = await http.get(uri);
    if (res.statusCode == 200) {
      final jsonRes = convert.jsonDecode(res.body) as Map<String, dynamic>;
      Cheese cheese = Cheese.fromJson(jsonRes['cheese']);

      setState(() {
        fetchingRandom = false;
      });

      if (!mounted) return;

      Navigator.push(context,
          MaterialPageRoute<void>(builder: (context) => CheeseDetails(cheese)));
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

        await Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (context) => CheeseDetails(cheese)),
        );
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
