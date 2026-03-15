
// --- واجهة الكمبيوتر (PC View) ---
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// --- 3. واجهة الكمبيوتر (نفس الكود السابق مع تعديلات طفيفة) ---
class PCView extends StatelessWidget {
  final Map<String, dynamic> gameState;
  final IO.Socket socket;
  final AnimationController timerController;

  const PCView({super.key, required this.gameState, required this.socket, required this.timerController});

  Color _getTimerColor(double value) => value > 0.6 ? Colors.green : (value > 0.3 ? Colors.orange : Colors.red);

  @override
  Widget build(BuildContext context) {
    var question = gameState['questions'][gameState['current_index']];
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerCircle(),
                const SizedBox(height: 50),
                Text(question['question'], style: const TextStyle(fontSize: 45, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white.withOpacity(0.03),
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => _buildDisplayOption(i, question)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: timerController,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200, height: 200,
            child: CircularProgressIndicator(
              value: timerController.value,
              strokeWidth: 12,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor(timerController.value)),
            ),
          ),
          Text("${(timerController.value * 15).ceil()}", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDisplayOption(int i, dynamic q) {
    Color color = Colors.white10;
    if (gameState['selected'] == i) {
      if (gameState['status'] == 'waiting') color = Colors.yellow[700]!;
      if (gameState['status'] == 'revealed') color = (i == q['correct']) ? Colors.green : Colors.red;
    }
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      child: Text(q['answers'][i], style: const TextStyle(fontSize: 22), textAlign: TextAlign.center),
    );
  }
}