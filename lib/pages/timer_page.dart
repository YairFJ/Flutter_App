import 'package:flutter/material.dart';
import 'dart:async';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  int hours = 0;
  int minutes = 0;
  int seconds = 0;
  Timer? timer;
  bool isRunning = false;
  int remainingSeconds = 0;
  int totalSeconds = 0;

  void startTimer() {
    totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
    if (totalSeconds <= 0) return; // Evitar iniciar si no hay tiempo configurado

    remainingSeconds = totalSeconds;

    setState(() {
      isRunning = true;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds <= 0) {
          stopTimer();
        } else {
          remainingSeconds--;
        }
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  String formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromARGB(255, 82, 81, 81),
                  width: 8,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Marcadores de tiempo
                  ...List.generate(12, (index) {
                    final angle = index * 30 * (3.14159 / 180);
                    return Transform.rotate(
                      angle: angle,
                      child: Transform.translate(
                        offset: const Offset(0, -120),
                        child: Container(
                          width: 4,
                          height: 15,
                          color: const Color.fromARGB(255, 82, 81, 81),
                        ),
                      ),
                    );
                  }),
                  // Círculo de progreso
                  
                  // Selector de tiempo o marcador de cuenta regresiva
                  if (!isRunning)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberPicker(
                          value: hours,
                          maxValue: 23,
                          label: 'Horas',
                          onChanged: (value) => setState(() => hours = value),
                        ),
                        _buildNumberPicker(
                          value: minutes,
                          maxValue: 59,
                          label: 'Minutos',
                          onChanged: (value) => setState(() => minutes = value),
                        ),
                        _buildNumberPicker(
                          value: seconds,
                          maxValue: 59,
                          label: 'Segundos',
                          onChanged: (value) => setState(() => seconds = value),
                        ),
                      ],
                    )
                  else
                    Text(
                      formatTime(remainingSeconds),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isRunning ? stopTimer : startTimer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                isRunning ? 'Detener' : 'Iniciar',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required int maxValue,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: const Color.fromARGB(255, 117, 117, 117)),
          ),
          SizedBox(
            height: 70,
            width: 50,
            child: ListWheelScrollView(
              itemExtent: 40,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: onChanged,
              controller: FixedExtentScrollController(initialItem: value),
              children: List.generate(
                maxValue + 1,
                (index) => Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
