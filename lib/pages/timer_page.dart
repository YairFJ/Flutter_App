import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Timer? countdownTimer;
  Duration myDuration = const Duration();
  Duration? pausedDuration;  // Para guardar el tiempo cuando se pausa
  bool isRunning = false;

  void startTimer() {
    if (myDuration.inSeconds == 0 && pausedDuration == null) {
      // Si no hay tiempo configurado, no hacer nada
      return;
    }
    
    setState(() {
      isRunning = true;
      if (pausedDuration != null) {
        myDuration = pausedDuration!;
        pausedDuration = null;
      }
    });

    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setCountDown(),
    );
  }

  void pauseTimer() {
    if (countdownTimer != null) {
      setState(() {
        pausedDuration = myDuration;  // Guardar el tiempo actual
        countdownTimer!.cancel();
        isRunning = false;
      });
    }
  }

  void resetTimer() {
    if (countdownTimer != null) {
      countdownTimer!.cancel();
    }
    setState(() {
      isRunning = false;
      pausedDuration = null;
      hours = 0;
      minutes = 0;
      seconds = 0;
      myDuration = const Duration(); // Esto pondrá el timer en 00:00:00
    });
  }

  void setCountDown() {
    const reduceSecondsBy = 1;
    setState(() {
      final seconds = myDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        countdownTimer!.cancel();
        isRunning = false;
        // Aquí podrías agregar algún sonido o notificación
      } else {
        myDuration = Duration(seconds: seconds);
      }
    });
  }

  void _editTime(String unit) {
    if (isRunning) return;  // No permitir editar mientras está corriendo
    
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${unit.capitalize()}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Ingrese ${unit.toLowerCase()}',
            border: const OutlineInputBorder(),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              setState(() {
                switch (unit.toLowerCase()) {
                  case 'horas':
                    hours = value.clamp(0, 23);
                    break;
                  case 'minutos':
                    minutes = value.clamp(0, 59);
                    break;
                  case 'segundos':
                    seconds = value.clamp(0, 59);
                    break;
                }
                myDuration = Duration(
                  hours: hours,
                  minutes: minutes,
                  seconds: seconds,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    
    final hours = strDigits(myDuration.inHours);
    final minutes = strDigits(myDuration.inMinutes.remainder(60));
    final seconds = strDigits(myDuration.inSeconds.remainder(60));

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeColumn('Horas', hours),
                const SizedBox(width: 8),
                Text(':', style: TextStyle(fontSize: 40, color: Colors.grey[700])),
                const SizedBox(width: 8),
                _buildTimeColumn('Minutos', minutes),
                const SizedBox(width: 8),
                Text(':', style: TextStyle(fontSize: 40, color: Colors.grey[700])),
                const SizedBox(width: 8),
                _buildTimeColumn('Segundos', seconds),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  isRunning ? Colors.orange : Colors.green,
                  () {
                    if (isRunning) {
                      pauseTimer();
                    } else {
                      startTimer();
                    }
                  },
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  Icons.refresh,
                  Colors.blue,
                  resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String label, String value) {
    return GestureDetector(
      onTap: () => _editTime(label),
      child: Column(
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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Color color, VoidCallback onPressed) {
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
