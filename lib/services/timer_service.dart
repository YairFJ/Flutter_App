import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

enum TimerType { none, countdown, stopwatch }

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  // Estado del temporizador
  Duration countdownDuration = const Duration();
  Duration remainingTime = const Duration();
  bool isCountdownRunning = false;
  Timer? countdownTimer;

  // Estado del cronómetro
  Duration stopwatchDuration = const Duration();
  bool isStopwatchRunning = false;
  Timer? stopwatchTimer;
  List<String> stopwatchLaps = [];

  // Tipo activo (solo uno puede estar activo a la vez)
  TimerType activeType = TimerType.none;

  // Notificaciones
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Inicializar notificaciones
  Future<void> initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(initializationSettings);
      debugPrint('Notificaciones inicializadas correctamente');
    } catch (e) {
      debugPrint('Error inicializando notificaciones: $e');
      // No lanzar el error, solo logearlo para que la app no falle
    }
  }

  // Configurar canal de notificación para Android
  Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'timer_channel',
        'Timer Notifications',
        description: 'Notifications for timer and stopwatch',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      debugPrint('Canal de notificación creado correctamente');
    } catch (e) {
      debugPrint('Error creando canal de notificación: $e');
      // No lanzar el error, solo logearlo
    }
  }

  // Iniciar temporizador
  void startCountdown(Duration duration) {
    if (activeType != TimerType.none && activeType != TimerType.countdown) {
      stopStopwatch();
    }

    countdownDuration = duration;
    remainingTime = duration;
    isCountdownRunning = true;
    activeType = TimerType.countdown;

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.inSeconds > 0) {
        remainingTime = Duration(seconds: remainingTime.inSeconds - 1);
        notifyListeners();
      } else {
        _stopCountdown();
        // Mostrar notificación solo si está disponible
        _showNotification('Timer Completed', 'Your timer has finished!');
        // También mostrar un snackbar como alternativa
        debugPrint('¡Temporizador completado!');
      }
    });

    notifyListeners();
  }

  // Pausar temporizador
  void pauseCountdown() {
    if (isCountdownRunning) {
      countdownTimer?.cancel();
      isCountdownRunning = false;
      notifyListeners();
    }
  }

  // Reanudar temporizador
  void resumeCountdown() {
    if (!isCountdownRunning && activeType == TimerType.countdown) {
      isCountdownRunning = true;
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingTime.inSeconds > 0) {
          remainingTime = Duration(seconds: remainingTime.inSeconds - 1);
          notifyListeners();
        } else {
          _stopCountdown();
          _showNotification('Timer Completed', 'Your timer has finished!');
        }
      });
      notifyListeners();
    }
  }

  // Detener temporizador
  void stopCountdown() {
    _stopCountdown();
  }

  void _stopCountdown() {
    countdownTimer?.cancel();
    isCountdownRunning = false;
    if (activeType == TimerType.countdown) {
      activeType = TimerType.none;
      // Llamar al callback de alarma si existe
      if (_onTimerComplete != null) {
        _onTimerComplete!();
      }
    }
    notifyListeners();
  }

  // Iniciar cronómetro
  void startStopwatch() {
    if (activeType != TimerType.none && activeType != TimerType.stopwatch) {
      stopCountdown();
    }

    isStopwatchRunning = true;
    activeType = TimerType.stopwatch;

    stopwatchTimer?.cancel();
    stopwatchTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      stopwatchDuration = Duration(milliseconds: stopwatchDuration.inMilliseconds + 10);
      notifyListeners();
    });

    notifyListeners();
  }

  // Pausar cronómetro
  void pauseStopwatch() {
    if (isStopwatchRunning) {
      stopwatchTimer?.cancel();
      isStopwatchRunning = false;
      notifyListeners();
    }
  }

  // Reanudar cronómetro
  void resumeStopwatch() {
    if (!isStopwatchRunning && activeType == TimerType.stopwatch) {
      isStopwatchRunning = true;
      stopwatchTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        stopwatchDuration = Duration(milliseconds: stopwatchDuration.inMilliseconds + 10);
        notifyListeners();
      });
      notifyListeners();
    }
  }

  // Detener cronómetro
  void stopStopwatch() {
    stopwatchTimer?.cancel();
    isStopwatchRunning = false;
    if (activeType == TimerType.stopwatch) {
      activeType = TimerType.none;
    }
    notifyListeners();
  }

  // Reiniciar cronómetro
  void resetStopwatch() {
    stopwatchTimer?.cancel();
    isStopwatchRunning = false;
    stopwatchDuration = const Duration();
    stopwatchLaps.clear();
    if (activeType == TimerType.stopwatch) {
      activeType = TimerType.none;
    }
    notifyListeners();
  }

  // Agregar vuelta al cronómetro
  void addLap() {
    if (isStopwatchRunning) {
      stopwatchLaps.insert(0, _formatDuration(stopwatchDuration));
      notifyListeners();
    }
  }

  // Callback para la alarma
  VoidCallback? _onTimerComplete;

  // Configurar callback de alarma
  void setTimerCompleteCallback(VoidCallback callback) {
    _onTimerComplete = callback;
  }

  // Mostrar notificación
  Future<void> _showNotification(String title, String body) async {
    try {
      await _createNotificationChannel();

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'timer_channel',
        'Timer Notifications',
        channelDescription: 'Notifications for timer and stopwatch',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notifications.show(
        0,
        title,
        body,
        platformChannelSpecifics,
      );
      debugPrint('Notificación mostrada correctamente');
    } catch (e) {
      debugPrint('Error mostrando notificación: $e');
      // No lanzar el error, solo logearlo
    }
  }

  // Formatear duración para mostrar
  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  // Obtener tiempo restante formateado
  String get remainingTimeFormatted {
    int hours = remainingTime.inHours;
    int minutes = remainingTime.inMinutes.remainder(60);
    int seconds = remainingTime.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  // Obtener tiempo del cronómetro formateado
  String get stopwatchTimeFormatted {
    return _formatDuration(stopwatchDuration);
  }

  // Verificar si hay algo activo
  bool get isAnyActive => activeType != TimerType.none;

  // Obtener el tipo activo
  TimerType get activeTimerType => activeType;

  @override
  void dispose() {
    countdownTimer?.cancel();
    stopwatchTimer?.cancel();
    super.dispose();
  }
}
