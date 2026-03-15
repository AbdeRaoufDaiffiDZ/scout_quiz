// --- واجهة الهاتف (Phone View) ---

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// --- 4. واجهة الهاتف مع ميزة إضافة الأسئلة ---
class PhoneView extends StatelessWidget {
  final Map<String, dynamic> gameState;
  final IO.Socket socket;
  const PhoneView({super.key, required this.gameState, required this.socket});

  void _showAddQuestionDialog(BuildContext context) {
    final qController = TextEditingController();
    final aControllers = List.generate(4, (_) => TextEditingController());
    int correctIdx = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qController,
                decoration: const InputDecoration(labelText: "السؤال"),
              ),
              ...List.generate(
                4,
                (i) => Row(
                  children: [
                    Radio(
                      value: i,
                      groupValue: correctIdx,
                      onChanged: (v) =>
                          setModalState(() => correctIdx = v as int),
                    ),
                    Expanded(
                      child: TextField(
                        controller: aControllers[i],
                        decoration: InputDecoration(labelText: "خيار ${i + 1}"),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  socket.emit('add_question', {
                    "question": qController.text,
                    "answers": aControllers.map((e) => e.text).toList(),
                    "correct": correctIdx,
                  });
                  Navigator.pop(context);
                },
                child: const Text("إضافة"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var question = gameState['questions'][gameState['current_index']];
    bool isLocked = gameState['status'] != 'idle';

    return Scaffold(
      appBar: AppBar(
        title: Text("تحكم - سؤال ${gameState['current_index'] + 1}"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddQuestionDialog(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ListView(
                    children: List.generate(
                      4,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: gameState['selected'] == i
                                ? (gameState['status'] == 'waiting'
                                      ? Colors.yellow[700]
                                      : (i == question['correct']
                                            ? Colors.green
                                            : Colors.red))
                                : Colors.grey[850],
                          ),
                          onPressed: isLocked
                              ? null
                              : () => socket.emit('submit_answer', {'index': i}),
                          child: Text(
                            question['answers'][i],
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (gameState['status'] == 'revealed')
                  ElevatedButton(
                    onPressed: () => socket.emit('next_question'),
                    child: const Text("السؤال التالي"),
                  ),
                    
                /// داخل العمود (Column) في PhoneView
                if (gameState['status'] == 'idle' &&
                    gameState['timer_started'] == false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(82, 255, 172, 64),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () =>
                          socket.emit('start_timer'), // إرسال أمر البدء
                      icon: const Icon(Icons.timer),
                      label: const Text(
                        "ابدأ عداد الوقت الآن",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
