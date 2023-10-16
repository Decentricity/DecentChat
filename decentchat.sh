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
    #!/bin/bash
    cat <<EOL > app.py
from flask import Flask, render_template_string, request, redirect, url_for, jsonify
import random

app = Flask(__name__)
messages = []

CHAT_HTML = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Decentricity's Anonymous Chat Room</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script>
        function refreshChat() {
            $.getJSON("/messages", function(data) {
            var chatList = $("#chat-list");
            if (chatList.length > 0) {
                chatList.empty();
                data.forEach(function(msg) {
                    chatList.append('<li><strong>' + msg.user_id + '</strong>: ' + msg.message + '</li>');
            });
        }
    });
}


        $(document).ready(function() {
            $("#send-button").click(function(e) {
                e.preventDefault();
                const username = $("#username").val() || "Anon";
                const message = $("#message").val();

                $.post("/send", { username: username, message: message }, function() {
                    $("#message").val("");
                    refreshChat();
                });
            });

            refreshChat();
            setInterval(refreshChat, 2000);
        });
    </script>
</head>
<body>
    <h1>Welcome to the Anonymous Chat Room!</h1>
    <ul id="chat-list">
    </ul>
    <form>
        <input id="username" name="username" placeholder="Username" autocomplete="off">
        <input id="message" name="message" placeholder="Message" autocomplete="off">
        <button id="send-button" type="submit">Send</button>
    </form>
</body>
</html>'''

@app.route('/')
def chat_room():
    return CHAT_HTML

@app.route('/send', methods=['POST'])
def send_message():
    username = request.form.get('username', 'Anon').strip() or "Anon"
    message = request.form.get('message').strip()

    messages.append({"user_id": username, "message": message})
    return jsonify(success=True)

@app.route('/messages')
def get_messages():
    return jsonify(messages)

if __name__ == '__main__':
    app.run(port=3690, debug=True)
EOL
fi

# Start Flask app
echo "Starting Flask app..."
python3 app.py &

# Forward local server to the Internet using localhost.run
echo "Setting up localhost.run tunnel..."
ssh -R 80:localhost:3690 ssh.localhost.run
