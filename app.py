from flask import Flask, render_template, request, redirect, url_for, session

app = Flask(__name__)
app.secret_key = 'your_secret_key'

def check_winner(board, player):
    win_combinations = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],  # rows
        [0, 3, 6], [1, 4, 7], [2, 5, 8],  # columns
        [0, 4, 8], [2, 4, 6]              # diagonals
    ]
    return any(all(board[i] == player for i in combo) for combo in win_combinations)

def is_draw(board):
    return all(cell != '' for cell in board)

@app.route('/')
def index():
    if 'board' not in session:
        session['board'] = [''] * 9
        session['turn'] = 'X'
        session['winner'] = ''
    return render_template('index.html', board=session['board'], turn=session['turn'], winner=session['winner'])

@app.route('/move/<int:cell>')
def move(cell):
    if session['board'][cell] == '' and session['winner'] == '':
        session['board'][cell] = session['turn']
        if check_winner(session['board'], session['turn']):
            session['winner'] = f"Player {session['turn']} wins!"
        elif is_draw(session['board']):
            session['winner'] = "It's a draw!"
        else:
            session['turn'] = 'O' if session['turn'] == 'X' else 'X'
    return redirect(url_for('index'))

@app.route('/reset')
def reset():
    session.pop('board', None)
    session.pop('turn', None)
    session.pop('winner', None)
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True)
