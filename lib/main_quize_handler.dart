import 'package:flutter/material.dart';
import 'package:scout_quiz/pc_sccreen.dart';
import 'package:scout_quiz/phone_screen.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class MainQuizHandler extends StatefulWidget {
  final String serverUrl;
  const MainQuizHandler({super.key, required this.serverUrl});

  @override
  State<MainQuizHandler> createState() => _MainQuizHandlerState();
}

class _MainQuizHandlerState extends State<MainQuizHandler>
    with TickerProviderStateMixin {
  late IO.Socket socket;
  Map<String, dynamic> gameState = {};
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    socket = IO.io(
      widget.serverUrl,
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.on('sync_data', (data) {
      if (mounted) {
        setState(() {
          gameState = data;

          // العداد يعمل فقط إذا كانت الحالة idle وتم إعطاء أمر البدء من السيرفر
          if (gameState['status'] == 'idle' &&
              gameState['timer_started'] == true) {
            if (!_timerController.isAnimating) {
              _timerController.reverse(from: 1.0);
            }
          } else {
            // إذا لم يبدأ التوقيت بعد أو تم اختيار إجابة، نتوقف ونثبت عند رقم 15
            _timerController.stop();
            if (gameState['status'] == 'idle' &&
                gameState['timer_started'] == false) {
              _timerController.value = 1.0; // إعادة الشكل لـ 15 ثانية كاملة
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (gameState.isEmpty)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return PCView(
            gameState: gameState,
            socket: socket,
            timerController: _timerController,
          );
        } else {
          return PhoneView(gameState: gameState, socket: socket);
        }
      },
    );
  }
}
