#!/bin/bash

# Check if SSH is installed
if ! command -v ssh &> /dev/null; then
    echo "SSH is not installed. Installing..."
    sudo apt update
    sudo apt install -y openssh-client
fi

# Check for existing SSH keys
if [ ! -f "~/.ssh/id_rsa" ]; then
    echo "No SSH keys found. Generating..."
    ssh-keygen -t rsa -b 4096
fi

# Start SSH agent and add key
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

# Check if Flask is installed
if ! command -v flask &> /dev/null; then
    echo "Flask is not installed. Installing..."
    pip3 install Flask
fi

# Check if app.py exists, if not create it
if [ ! -f "app.py" ]; then
    echo "Creating app.py..."
    cat <<EOL > app.py
from flask import Flask, render_template_string, request, redirect, url_for, session
import random
import os

app = Flask(__name__)
app.secret_key = os.urandom(24)
messages = []

CHAT_HTML = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Decentricity's Anonymous Chat Room</title>
</head>
<body>
    <h1>Welcome to the Anonymous Chat Room!</h1>
    <ul>
        {% for message in messages %}
            <li><strong>{{ message.user_id }}</strong>: {{ message.message }}</li>
        {% endfor %}
    </ul>
    <form method="post" action="/send">
        <input name="message" autocomplete="off">
        <button type="submit">Send</button>
    </form>
</body>
</html>
'''

@app.route('/')
def chat_room():
    if 'user_id' not in session:
        session['user_id'] = str(random.randint(1000000, 9999999))
    return render_template_string(CHAT_HTML, messages=messages)

@app.route('/send', methods=['POST'])
def send_message():
    message = request.form['message']
    messages.append({"user_id": session['user_id'], "message": message})
    return redirect(url_for('chat_room'))

if __name__ == '__main__':
    app.run(port=3000, debug=True)
EOL
fi

# Start Flask app
echo "Starting Flask app..."
python3 app.py &

# Forward local server to the Internet using localhost.run
echo "Setting up localhost.run tunnel..."
ssh -R 80:localhost:3000 ssh.localhost.run
