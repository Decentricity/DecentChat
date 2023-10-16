#!/bin/bash

# Generate a random port between 3000 and 3999
RANDOM_PORT=$((3000 + RANDOM % 1000))

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

# Kill any existing instances of the Flask app
pkill -f "python3 app.py"

# Check if app.py exists, if not create it
if [ ! -f "app.py" ]; then
    echo "Creating app.py..."
    cat <<EOL > temp_app.py
from flask import Flask, render_template_string, request, redirect, url_for, session
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
        <input name="username" placeholder="Your Username" autocomplete="off">
        <input name="message" placeholder="Your Message" autocomplete="off">
        <button type="submit">Send</button>
    </form>
</body>
</html>
'''

@app.route('/')
def chat_room():
    return render_template_string(CHAT_HTML, messages=messages)

@app.route('/send', methods=['POST'])
def send_message():
    username = request.form.get('username', 'Anon').strip()
    message = request.form['message']
    username = "Anon" if username == "" else username

    messages.append({"user_id": username, "message": message})
    return redirect(url_for('chat_room'))

if __name__ == '__main__':
    app.run(port=PORT_TO_BE_REPLACED, debug=True)
EOL
    # Replace placeholder with actual port number
    sed "s/PORT_TO_BE_REPLACED/$RANDOM_PORT/g" temp_app.py > app.py
    rm temp_app.py
fi

# Start Flask app
echo "Starting Flask app on port $RANDOM_PORT..."
python3 app.py &

# Forward local server to the Internet using localhost.run
echo "Setting up localhost.run tunnel on port $RANDOM_PORT..."
ssh -R 80:localhost:$RANDOM_PORT ssh.localhost.run

