import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'dart:convert' as convert;

import 'cheese.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('ic_launcher');
InitializationSettings initializationSettings =
    const InitializationSettings(android: androidInitializationSettings);

enum Tasks {
  dailyCheese,
}

void selectNotification(String? payload) async {
  if (payload != null) {
    final cheese =
        Cheese.fromJson(convert.jsonDecode(payload) as Map<String, dynamic>);
    print(cheese.name);
  }

  // TODO: navigate to cheese page
  // await Navigator.push(
  //     context,
  //     MaterialPageRoute<void>(builder: (context) => SecondScreen(payload)),
  // );
}

Future<Uint8List> _getByteArrayFromUrl(String url) async {
  final http.Response response = await http.get(Uri.parse(url));
  return response.bodyBytes;
}

sendDailyCheeseNotification(Map<String, dynamic> cheeseJson) async {
  final cheese = Cheese.fromJson(cheeseJson);

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

Future<bool> getDailyCheese() async {
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
      return Future.value(await getDailyCheese());
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

  final now = DateTime.now().toUtc();
  Duration timeTill3AMUTC = const Duration();

  if (now.hour < 3) {
    timeTill3AMUTC =
        now.difference(DateTime(now.year, now.month, now.day, 3, 0, 0)).abs();
  } else if (now.hour >= 3) {
    final nextDay = now.add(const Duration(days: 1));
    timeTill3AMUTC = now
        .difference(DateTime(nextDay.year, nextDay.month, nextDay.day, 3, 0, 0))
        .abs();
  }

  Workmanager().registerPeriodicTask(
      Tasks.dailyCheese.name, Tasks.dailyCheese.name,
      frequency: const Duration(hours: 24),
      initialDelay: Duration(seconds: timeTill3AMUTC.inSeconds));

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: selectNotification);

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
  showAllCheeses() {
    // TODO: get all cheeses
  }

  getRandomCheese() {
    // TODO: get random cheese
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
                          child: const Text("Random cheese"),
                          onPressed: () => getRandomCheese()),
                      ElevatedButton(
                          child: const Text("All cheeses"),
                          onPressed: () => showAllCheeses()),
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
