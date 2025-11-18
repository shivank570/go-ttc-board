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

  @override
  void initState() {
    super.initState();
    fetchDepartures();
  }

  Future<void> fetchDepartures() async {
    setState(() => loading = true);

    try {
      final jsonUrl = Uri.parse(
        "https://storage.googleapis.com/gtfs-rt-metrolinx/tripupdates.json",
      );

      final res = await http.get(jsonUrl);
      final data = json.decode(res.body);

      departures = parseDepartures(data);
    } catch (e) {
      print("Error fetching GTFS-RT: $e");
    }

    setState(() => loading = false);
  }

  List parseDepartures(dynamic data) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    List parsed = [];

    for (var entity in data["entity"]) {
      if (entity["trip_update"] == null) continue;

      var trip = entity["trip_update"]["trip"];
      var stops = entity["trip_update"]["stop_time_update"];
      if (stops == null) continue;

      for (var stop in stops) {
        if (stop["departure"] == null) continue;

        int dep = stop["departure"]["time"];
        int diff = dep - now;

        // show only departures in next 2 hours
        if (diff >= 0 && diff <= 7200) {
          parsed.add({
            "route": trip["route_id"] ?? "",
            "stop": stop["stop_id"] ?? "",
            "time": DateFormat("h:mm a").format(
              DateTime.fromMillisecondsSinceEpoch(dep * 1000),
            ),
            "minutes": diff ~/ 60
          });
        }
      }
    }

    parsed.sort((a, b) => a["minutes"].compareTo(b["minutes"]));
    return parsed.take(20).toList();
  }

  Color badgeColor(String route) {
    switch (route.toUpperCase()) {
      case "LW":
        return Colors.redAccent;
      case "ST":
        return Colors.orange;
      case "LE":
        return Colors.pink;
      case "KI":
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: const Text(
                      "Departures   |   Départs",
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Column headers
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    child: Row(
                      children: const [
                        Expanded(flex: 1, child: Text("Pltfm")),
                        Expanded(flex: 2, child: Text("Route")),
                        Expanded(flex: 4, child: Text("Direction")),
                        Expanded(flex: 2, child: Text("Time")),
                      ],
                    ),
                  ),
                  // List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: fetchDepartures,
                      child: ListView.builder(
                        itemCount: departures.length,
                        itemBuilder: (context, index) {
                          final d = departures[index];

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    // Platform (placeholder)
                                    const Expanded(
                                      flex: 1,
                                      child: Text("—"),
                                    ),
                                    // Route badge
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: badgeColor(d["route"]),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          d["route"],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Direction (here using stop ID for now)
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: Text(
                                          d["stop"],
                                          style: const TextStyle(fontSize: 17),
                                        ),
                                      ),
                                    ),
                                    // Time
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        d["minutes"] == 0
                                            ? "Due"
                                            : "${d["minutes"]}",
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.yellow.shade500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // separator
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                height: 1,
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
