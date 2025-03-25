import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:soundpool/soundpool.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? countdownTimer;
  Duration myDuration = const Duration();
  Duration? pausedDuration;
  bool isRunning = false;
  late List<FixedExtentScrollController> controllers;
  
  // Soundpool
  Soundpool? soundpool;
  int? soundId;

  @override
  void initState() {
    super.initState();
    controllers = [
      FixedExtentScrollController(initialItem: 0),
      FixedExtentScrollController(initialItem: 0),
      FixedExtentScrollController(initialItem: 0),
    ];
    _initSound();
  }

  Future<void> _initSound() async {
    try {
      soundpool = Soundpool.fromOptions(
        options: SoundpoolOptions(
          streamType: StreamType.alarm,
          maxStreams: 1,
        ),
      );
      
      final ByteData data = await rootBundle.load('lib/sounds/alarm.mp3');
      soundId = await soundpool?.load(data);
      debugPrint('Sonido cargado exitosamente: $soundId');
    } catch (e) {
      debugPrint('Error cargando sonido: $e');
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    for (var controller in controllers) {
      controller.dispose();
    }
    soundpool?.dispose();
    super.dispose();
  }

  Future<void> _playAlarm() async {
    try {
      if (soundpool != null && soundId != null) {
        debugPrint('Intentando reproducir sonido: $soundId');
        
        // Reproducir el sonido con volumen máximo y múltiples repeticiones
        final streamId = await soundpool!.play(
          soundId!,
          rate: 1.0,      // Velocidad normal
          repeat: 3,      // Repetir 3 veces
        );
        
        debugPrint('Sonido reproducido con streamId: $streamId');
        
        // Esperar 3 segundos y detener
        await Future.delayed(const Duration(seconds: 3));
        await soundpool!.stop(streamId);
      } else {
        debugPrint('Soundpool o soundId es null');
      }
    } catch (e) {
      debugPrint('Error reproduciendo alarma: $e');
    }
  }

  void startTimer() {
    if (isRunning || (myDuration.inSeconds == 0 && pausedDuration == null)) {
      return;
    }
    
    setState(() {
      isRunning = true;
      if (pausedDuration != null) {
        myDuration = pausedDuration!;
        pausedDuration = null;
      }
    });

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setCountDown(),
    );
  }

  void setCountDown() {
    if (!mounted) return;
    
    setState(() {
      final seconds = myDuration.inSeconds - 1;
      if (seconds < 0) {
        countdownTimer?.cancel();
        isRunning = false;
        _playAlarm(); // Reproducir alarma cuando llegue a cero
      } else {
        myDuration = Duration(seconds: seconds);
        // Actualizar los controladores
        controllers[0].jumpToItem(myDuration.inHours);
        controllers[1].jumpToItem(myDuration.inMinutes.remainder(60));
        controllers[2].jumpToItem(myDuration.inSeconds.remainder(60));
      }
    });
  }

  void pauseTimer() {
    if (!isRunning) return;
    
    countdownTimer?.cancel();
    setState(() {
      pausedDuration = myDuration;
      isRunning = false;
    });
  }

  void resetTimer() {
    countdownTimer?.cancel();
    setState(() {
      isRunning = false;
      pausedDuration = null;
      myDuration = const Duration();
      
      // Reiniciar los controladores
      for (var controller in controllers) {
        controller.jumpToItem(0);
      }
    });
  }

  Widget _buildNumberPicker(int value, int maxValue, int controllerIndex) {
    return Container(
      height: 100,
      width: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[800] // Color más claro para modo oscuro
            : Colors.grey[200], // Color original para modo claro
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListWheelScrollView.useDelegate(
        itemExtent: 60,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: isRunning ? const NeverScrollableScrollPhysics() : const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          if (!isRunning) {
            setState(() {
              switch (controllerIndex) {
                case 0:
                  myDuration = Duration(
                    hours: index,
                    minutes: myDuration.inMinutes.remainder(60),
                    seconds: myDuration.inSeconds.remainder(60),
                  );
                  break;
                case 1:
                  myDuration = Duration(
                    hours: myDuration.inHours,
                    minutes: index,
                    seconds: myDuration.inSeconds.remainder(60),
                  );
                  break;
                case 2:
                  myDuration = Duration(
                    hours: myDuration.inHours,
                    minutes: myDuration.inMinutes.remainder(60),
                    seconds: index,
                  );
                  break;
              }
            });
          }
        },
        controller: controllers[controllerIndex],
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: maxValue,
          builder: (context, index) {
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white // Color del texto para modo oscuro
                      : Colors.black, // Color del texto para modo claro
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNumberPicker(myDuration.inHours, 24, 0),
                Text(' : ', 
                  style: TextStyle(
                    fontSize: 48, 
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  )
                ),
                _buildNumberPicker(myDuration.inMinutes.remainder(60), 60, 1),
                Text(' : ', 
                  style: TextStyle(
                    fontSize: 48, 
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  )
                ),
                _buildNumberPicker(myDuration.inSeconds.remainder(60), 60, 2),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  isRunning ? Colors.orange : Colors.green,
                  myDuration.inSeconds == 0 && !isRunning
                      ? null
                      : () => isRunning ? pauseTimer() : startTimer(),
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
}
