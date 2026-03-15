import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scout_quiz/main_quize_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() => runApp(const QuizApp());

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: Colors.blueAccent,
        // تخصيص الألوان الافتراضية للنصوص
        textTheme:  GoogleFonts.notoKufiArabicTextTheme().copyWith(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          displayLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(color: Colors.white),
        ),
        // لضمان ظهور العناوين في AppBar باللون الأبيض أيضاً
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const ConnectionScreen(),
    );
  }
}

// --- 1. شاشة الاتصال بالسيرفر ---
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: "http://192.168.1.70:5000",
  );
  bool _isConnecting = false;
  String _errorMessage = "";
  void _connectToServer() {
    if (!mounted) return; // تأكد أن الصفحة موجودة

    setState(() {
      _isConnecting = true;
      _errorMessage = "";
    });

    IO.Socket socket = IO.io(
      _urlController.text,
      IO.OptionBuilder().setTransports(['websocket']).setQuery({
        'client_type': 'checker',
      }).build(),
    );

    socket.onConnect((_) {
      // نتحقق من mounted قبل أي عملية تنقل أو تحديث واجهة
      if (mounted) {
        socket.dispose();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MainQuizHandler(serverUrl: _urlController.text),
          ),
        );
      }
    });

    socket.onConnectError((data) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = "فشل الاتصال: تأكد من العنوان أو الشبكة";
        });
        socket.dispose();
      }
    });

    // مهلة زمنية للاتصال
    Future.delayed(const Duration(seconds: 5), () {
      // هذا هو الجزء الذي سبب الخطأ؛ أضفنا التحقق من mounted
      if (mounted && _isConnecting) {
        setState(() {
          _isConnecting = false;
          _errorMessage = "انتهت مهلة الاتصال";
        });
        socket.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lan, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                "إعدادات السيرفر",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: "Server URL",
                  hintText: "http://192.168.1.x:5000",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              _isConnecting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _connectToServer,
                      child: const Text("اتصال وابدأ الكويز"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
