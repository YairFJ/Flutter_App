import 'package:flutter/material.dart';
import 'dart:async';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  int milliseconds = 0;
  Timer? timer;
  bool isRunning = false;
  List<String> laps = [];

  void startTimer() {
    timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        milliseconds += 10;
      });
    });
    setState(() {
      isRunning = true;
    });
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      milliseconds = 0;
      isRunning = false;
      laps.clear();
    });
  }

  void addLap() {
    setState(() {
      laps.insert(0, formatTime(milliseconds));
    });
  }

  String formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).floor() % 100;
    int seconds = (milliseconds / 1000).floor() % 60;
    int minutes = (milliseconds / 60000).floor() % 60;
    int hours = (milliseconds / 3600000).floor();

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundreds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Spacer(flex: 8),
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 8,
                ),
              ),
              child: Center(
                child: Text(
                  formatTime(milliseconds),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: isRunning ? stopTimer : startTimer,
                  child: Text(
                    isRunning ? 'Detener' : 'Iniciar',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: resetTimer,
                  child: const Text(
                    'Reiniciar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: isRunning ? addLap : null,
                  child: const Text(
                    'Vuelta',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: laps.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      'Vuelta ${laps.length - index}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: Text(
                      laps[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
} 