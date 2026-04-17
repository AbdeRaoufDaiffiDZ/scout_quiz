import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';

class PCView extends StatefulWidget {
  final Map<String, dynamic> gameState;
  final IO.Socket socket;
  final AnimationController timerController;

  const PCView({
    super.key,
    required this.gameState,
    required this.socket,
    required this.timerController,
  });

  @override
  State<PCView> createState() => _PCViewState();
}

class _PCViewState extends State<PCView> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _timerPlayer =
      AudioPlayer(); // Dedicated player for timer to avoid cutting off music
  String? _lastStatus;
  int? _lastSelected;
  int _lastTickValue = 15; // Track the last second played

  @override
  void initState() {
    super.initState();
    // Listen to the timer controller to trigger sounds
    widget.timerController.addListener(_handleTimerSound);
  }

  @override
  void dispose() {
    widget.timerController.removeListener(_handleTimerSound);
    _audioPlayer.dispose();
    _timerPlayer.dispose();
    super.dispose();
  }

  void _handleTimerSound() {
  // Check if an answer has already been selected or the timer is finished/revealed
  // This stops the ticking sound immediately upon selection
  if (widget.gameState['selected'] != null || 
      widget.gameState['status'] == 'revealed' || 
      widget.timerController.value == 0) {
    _timerPlayer.stop();
    return; 
  }

  int currentTime = (widget.timerController.value * 15).ceil();

  if (currentTime != _lastTickValue && currentTime > 0) {
    _lastTickValue = currentTime;
      _playTimerSound('sounds/tick.mp3');

    // if (currentTime <= 3) {
    //   _playTimerSound('sounds/timer_warning.mp3');
    // } else {
    // }
  }
}


  Future<void> _playTimerSound(String path) async {
    // Use a separate player so the "tick" doesn't stop the "Correct/Wrong" music
    await _timerPlayer.play(AssetSource(path), volume: 0.5);
  }

  // Logic to play sound based on game state changes
  void _handleSound(Map<String, dynamic> gameState) {
    final status = gameState['status'];
    final selected = gameState['selected'];
    final currentIndex = gameState['current_index'];
    final question = gameState['questions'][currentIndex];

    // 1. Yellow Sound: Triggered when a choice is made (waiting status)
    if (status == 'waiting' && selected != null && selected != _lastSelected) {
      _playSound('sounds/select_yellow.mp3');
    }
    // 2. Green/Red Sound: Triggered when results are revealed
    else if (status == 'revealed' && _lastStatus != 'revealed') {
      if (selected == question['correct']) {
        _playSound('sounds/correct_green.mp3');
      } else {
        _playSound('sounds/wrong_red.mp3');
      }
    }

    _lastStatus = status;
    _lastSelected = selected;
  }

Future<void> _playSound(String path) async {
  // When playing a result sound (Correct/Wrong), stop the timer player too
  await _timerPlayer.stop(); 
  await _audioPlayer.stop();
  await _audioPlayer.play(AssetSource(path));
}

  Color _getTimerColor(double value) =>
      value > 0.6 ? Colors.green : (value > 0.3 ? Colors.orange : Colors.red);

  @override
  Widget build(BuildContext context) {
    // Check for sound triggers every time the widget builds with new state
    _handleSound(widget.gameState);

    var question =
        widget.gameState['questions'][widget.gameState['current_index']];

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
                Text(
                  question['question'],
                  style: const TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white.withOpacity(0.03),
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => _buildDisplayOption(i, question),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle() {
    return AnimatedBuilder(
      animation: widget.timerController,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: widget.timerController.value,
              strokeWidth: 12,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTimerColor(widget.timerController.value),
              ),
            ),
          ),
          Text(
            "${(widget.timerController.value * 15).ceil()}",
            style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
Widget _buildDisplayOption(int i, dynamic q) {
  Color color = Colors.white10;
  final bool isSelected = widget.gameState['selected'] == i;
  final bool isCorrect = i == q['correct'];
  final String status = widget.gameState['status'];

  if (status == 'waiting' && isSelected) {
    // While waiting for reveal, highlight selection yellow
    color = Colors.yellow[700]!;
  } 
  else if (status == 'revealed') {
    if (isCorrect) {
      // Always show the correct answer as green
      color = Colors.green;
    } else if (isSelected && !isCorrect) {
      // If the user selected this and it was wrong, show red
      color = Colors.red;
    }
  }

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(15),
      // Optional: Add a border to the user's selection to make it stand out
      border: isSelected && status == 'revealed' 
          ? Border.all(color: Colors.white, width: 2) 
          : null,
    ),
    child: Text(
      q['answers'][i],
      style:  TextStyle(
        fontSize: 22, 
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    ),
  );
}
}
