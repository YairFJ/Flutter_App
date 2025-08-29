import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Duration myDuration = const Duration();
  Duration? pausedDuration;
  late List<FixedExtentScrollController> controllers;
  

  @override
  void initState() {
    super.initState();
    controllers = [
      FixedExtentScrollController(initialItem: 0),
      FixedExtentScrollController(initialItem: 0),
      FixedExtentScrollController(initialItem: 0),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Configurar callback de alarma en el TimerService
    try {
      final timerService = Provider.of<TimerService>(context, listen: false);
      timerService.setTimerCompleteCallback(_onTimerCompleteUI);
      debugPrint('Callback de alarma configurado correctamente');
    } catch (e) {
      debugPrint('Error configurando callback de alarma: $e');
    }
  }

  // Callback para completar temporizador que solo actualiza la UI, el sonido lo maneja TimerService
  void _onTimerCompleteUI() {
    if (!mounted) return;
    _autoRefreshTimer();
  }

  // Método para refrescar automáticamente el temporizador
  void _autoRefreshTimer() {
    setState(() {
      pausedDuration = null;
      myDuration = const Duration();
      
      // Reiniciar los controladores
      for (var controller in controllers) {
        controller.jumpToItem(0);
      }
    });
    
    debugPrint('Temporizador refrescado automáticamente');
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  

  void startTimer() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    
    // Validar que haya tiempo configurado
    if (myDuration.inSeconds == 0 && pausedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configura un tiempo antes de iniciar'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (timerService.isCountdownRunning) {
      return;
    }
    
    if (pausedDuration != null) {
      timerService.startCountdown(pausedDuration!);
      pausedDuration = null;
    } else {
      timerService.startCountdown(myDuration);
    }
    
    // Asegurar que la duración se sincronice inmediatamente
    setState(() {
      myDuration = timerService.remainingTime;
    });
  }

  void pauseTimer() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    
    if (timerService.isCountdownRunning) {
      pausedDuration = timerService.remainingTime;
      timerService.pauseCountdown();
      
      // Mantener la duración sincronizada
      setState(() {
        myDuration = pausedDuration!;
      });
    }
  }

  void resetTimer() {
    final timerService = Provider.of<TimerService>(context, listen: false);
    timerService.stopCountdown(silent: true);
    
    setState(() {
      pausedDuration = null;
      myDuration = const Duration();
      
      // Reiniciar los controladores
      for (var controller in controllers) {
        controller.jumpToItem(0);
      }
    });
    
    // Mostrar mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Temporizador reseteado'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildNumberPicker(int value, int maxValue, int controllerIndex) {
    final timerService = Provider.of<TimerService>(context);
    final isRunning = timerService.isCountdownRunning;
    
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
    
    return Consumer<TimerService>(
      builder: (context, timerService, child) {
        // Sincronizar la duración mostrada con el temporizador
        if (timerService.isCountdownRunning) {
          myDuration = timerService.remainingTime;
          // Actualizar los controladores de los pickers para que muestren el tiempo correcto
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              controllers[0].jumpToItem(myDuration.inHours);
              controllers[1].jumpToItem(myDuration.inMinutes.remainder(60));
              controllers[2].jumpToItem(myDuration.inSeconds.remainder(60));
            }
          });
        } else if (timerService.activeTimerType == TimerType.none && pausedDuration != null) {
          // Si está pausado, mostrar el tiempo pausado
          myDuration = pausedDuration!;
        }
        // Si no hay temporizador activo, permitir que el usuario configure el tiempo
        // No hacer auto-refresh automático que interfiera con la configuración
        
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
                // El indicador se eliminó para permitir configurar el tiempo libremente
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      timerService.isCountdownRunning ? Icons.pause : Icons.play_arrow,
                      timerService.isCountdownRunning ? Colors.orange : Colors.green,
                      myDuration.inSeconds == 0 && !timerService.isCountdownRunning
                          ? null
                          : () => timerService.isCountdownRunning ? pauseTimer() : startTimer(),
                      tooltip: timerService.isCountdownRunning ? 'Pausar' : 'Iniciar',
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(
                      Icons.refresh,
                      Colors.blue,
                      resetTimer,
                      tooltip: 'Resetear',
                    ),

                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton(IconData icon, Color color, VoidCallback? onPressed, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(24),
        ),
        child: Icon(icon, size: 32, color: Colors.white),
      ),
    );
  }
}
