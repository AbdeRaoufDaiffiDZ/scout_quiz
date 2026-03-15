import eventlet
eventlet.monkey_patch()

from flask import Flask
from flask_socketio import SocketIO, emit
import json
import os
import time

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

DATA_FILE = "quiz_data.json"

# بيانات افتراضية إذا كان الملف غير موجود
initial_data = {
    "current_index": 0,
    "timer_started": False, # إضافة هذا المتغير
    "selected": None,
    "status": "idle", # idle, waiting, revealed
    "questions": [
        {"question": "ما هي عاصمة الجزائر؟", "answers": ["تلمسان", "الجزائر", "وهران", "عنابة"], "correct": 1},
        {"question": "ما هو رمز الأكسجين؟", "answers": ["H", "C", "O", "N"], "correct": 2}
    ]
}

def load_data():
    if not os.path.exists(DATA_FILE):
        with open(DATA_FILE, "w") as f: json.dump(initial_data, f)
    with open(DATA_FILE, "r") as f: return json.load(f)

def save_data(data):
    with open(DATA_FILE, "w") as f: json.dump(data, f)

@socketio.on('connect')
def handle_connect():
    emit('sync_data', load_data())

@socketio.on('submit_answer')
def handle_answer(data):
    state = load_data()
    state['selected'] = data['index']
    state['status'] = 'waiting' # اللون الأصفر
    save_data(state)
    emit('sync_data', state, broadcast=True)

    # انتظر 5 ثوانٍ (المنطق الزمني في السيرفر لضمان التزامن)
    socketio.sleep(5)
    
    state['status'] = 'revealed' # اللون الأخضر/الأحمر
    save_data(state)
    emit('sync_data', state, broadcast=True)
    
@socketio.on('add_question')
def handle_add_question(data):
    state = load_data()
    # إضافة السؤال الجديد لقائمة الأسئلة
    state['questions'].append({
        "question": data['question'],
        "answers": data['answers'],
        "correct": data['correct']
    })
    save_data(state)
    emit('sync_data', state, broadcast=True) # تحديث جميع الأجهزة بالقائمة الجديدة


@socketio.on('start_timer') # تغيير اسم الحدث ليكون عاماً
def handle_start_timer():
    state = load_data()
    state['timer_started'] = True
    save_data(state)
    emit('sync_data', state, broadcast=True)

@socketio.on('next_question')
def handle_next():
    state = load_data()
    if state['current_index'] < len(state['questions']) - 1:
        state['current_index'] += 1
        state['selected'] = None
        state['status'] = 'idle'
        state['timer_started'] = False # إعادة التصفير للسؤال التالي
        save_data(state)
        emit('sync_data', state, broadcast=True)
        
if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000)