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
    int seconds = (milliseconds / 1000).floor() % 60;
    int minutes = (milliseconds / 60000).floor() % 60;
    int hours = (milliseconds / 3600000).floor();

    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');

    final hours = strDigits((milliseconds / 3600000).floor());
    final minutes = strDigits(((milliseconds / 60000).floor()) % 60);
    final seconds = strDigits(((milliseconds / 1000).floor()) % 60);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeColumn('Horas', hours),
                        const SizedBox(width: 8),
                        Text(
                          ':',
                          style: TextStyle(fontSize: 40, color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 8),
                        _buildTimeColumn('Minutos', minutes),
                        const SizedBox(width: 8),
                        Text(
                          ':',
                          style: TextStyle(fontSize: 40, color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 8),
                        _buildTimeColumn('Segundos', seconds),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        isRunning ? Icons.pause : Icons.play_arrow,
                        isRunning ? Colors.orange : Colors.green,
                        isRunning ? stopTimer : startTimer,
                      ),
                      const SizedBox(width: 20),
                      _buildControlButton(
                        Icons.refresh,
                        Colors.blue,
                        resetTimer,
                      ),
                      const SizedBox(width: 20),
                      _buildControlButton(
                        Icons.flag,
                        Colors.purple,
                        isRunning ? addLap : null,
                      ),
                    ],
                  ),
                  if (laps.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Container(
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
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, Color color, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(24),
      ),
      child: Icon(icon, size: 32, color: Colors.white),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
} 