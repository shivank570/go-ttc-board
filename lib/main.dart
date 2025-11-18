import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const GoBoard(),
      theme: ThemeData.dark(),
    );
  }
}

class GoBoard extends StatefulWidget {
  const GoBoard({super.key});

  @override
  State<GoBoard> createState() => _GoBoardState();
}

class _GoBoardState extends State<GoBoard> {
  bool loading = true;
  List departures = [];

  // --------------------------
  // STOP NAME MAPPING
  // --------------------------
  final Map<String, String> stopNames = {
    "99901": "Union Station",
    "99902": "East Harbour",
    "93000": "Kennedy GO",
    "93001": "Eglinton GO",
    "93002": "Scarborough GO",
    "93003": "Guildwood GO",
    "93004": "Rouge Hill GO",
  };

  // --------------------------
  // ROUTE COLORS
  // --------------------------
  Color badgeColor(String route) {
    switch (route.toUpperCase()) {
      case "LW":
        return Colors.redAccent;
      case "LE":
        return Colors.pinkAccent;
      case "ST":
        return Colors.orangeAccent;
      case "KI":
        return Colors.greenAccent;
      case "RH":
        return Colors.blueAccent;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDepartures();
  }

  // --------------------------
  // FETCH GTFS
  // --------------------------
  Future<void> fetchDepartures() async {
    setState(() => loading = true);

    try {
      final url = Uri.parse(
        "https://storage.googleapis.com/gtfs-rt-metrolinx/tripupdates.json",
      );

      final res = await http.get(url);
      final data = json.decode(res.body);

      departures = parseDepartures(data);
    } catch (e) {
      print("Error: $e");
    }

    setState(() => loading = false);
  }

  // --------------------------
  // PARSE GTFS
  // --------------------------
  List parseDepartures(dynamic data) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    List items = [];

    for (var entity in data["entity"]) {
      if (entity["trip_update"] == null) continue;

      var trip = entity["trip_update"]["trip"];
      var stops = entity["trip_update"]["stop_time_update"];
      if (stops == null) continue;

      for (var stop in stops) {
        if (stop["departure"] == null) continue;

        int dep = stop["departure"]["time"];
        int diff = dep - now;


        if (diff >= 0 && diff <= 7200) {
          items.add({
            "route": trip["route_id"] ?? "",
            "stop": stop["stop_id"] ?? "",
            "time": DateFormat("h:mm a")
                .format(DateTime.fromMillisecondsSinceEpoch(dep * 1000)),
            "minutes": diff ~/ 60,
          });
        }
      }
    }

    items.sort((a, b) => a["minutes"].compareTo(b["minutes"]));
    return items.take(20).toList();
  }

  // --------------------------
  // UI BUILD
  // --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(

                children: [
                  // ---------------------------------------------------
                  // HEADER WITH LOGO + TITLE + LIVE CLOCK
                  // ---------------------------------------------------
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // APP LOGO
                        Row(
                          children: [
                            Image.asset(
                              "assets/hybrid_app_icon.png",
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Departures  |  Départs",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // LIVE CLOCK
                        Text(
                          DateFormat("HH:mm:ss").format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // COLUMN LABELS
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: const [
                        Expanded(flex: 1, child: Text("Pltfm")),
                        Expanded(flex: 2, child: Text("Route")),
                        Expanded(flex: 4, child: Text("Direction")),
                        Expanded(flex: 2, child: Text("Time")),
                      ],
                    ),
                  ),

                  // LIST OF DEPARTURES
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: fetchDepartures,
                      child: ListView.builder(
                        itemCount: departures.length,
                        itemBuilder: (context, index) {
                          final d = departures[index];
                          final stopName =
                              stopNames[d["stop"]] ?? d["stop"];

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [

                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        "—",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),

                                    // ROUTE BADGE
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: badgeColor(d["route"]),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          d["route"],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,

                                          ),
                                        ),
                                      ),
                                    ),

                                    // STOP NAME
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 12),
                                        child: Text(
                                          stopName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // MINUTES
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        d["minutes"] == 0
                                            ? "Due"
                                            : "${d["minutes"]}",
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // SEPARATOR LINE
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
