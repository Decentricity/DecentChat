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
from flask import Flask, render_template_string, request, jsonify

app = Flask(__name__)
messages = []

CHAT_HTML = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Decentricity's Anonymous Chat Room</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script>
        function refreshChat() {
            $.getJSON("/messages", function(data) {
                let chatList = "";
                data.messages.forEach(function(message) {
                    chatList += "<li><strong>" + message.user_id + "</strong>: " + message.message + "</li>";
                });
                $("#chat-list").html(chatList);
            });
        }

        $(document).ready(function() {
            refreshChat();
            $("#send-button").click(function() {
                let username = $("#username").val().trim() || "Anon";
                let message = $("#message").val().trim();
                $.post("/send", { "username": username, "message": message }, function() {
                    $("#message").val("");
                    refreshChat();
                });
            });
        });
    </script>
</head>
<body>
    <h1>DecentChat, the Anonymous Sovereign Chat Room</h1>
    <ul id="chat-list"></ul>
    <input id="username" type="text" placeholder="Your Username" autocomplete="off">
    <input id="message" type="text" placeholder="Your Message" autocomplete="off">
    <button id="send-button">Send</button>
</body>
</html>
'''

@app.route('/')
def chat_room():
    return render_template_string(CHAT_HTML)

@app.route('/send', methods=['POST'])
def send_message():
    username = request.form.get('username', 'Anon').strip() || "Anon"
    message = request.form['message'].strip()
    messages.append({"user_id": username, "message": message})
    return jsonify({"status": "ok"})

@app.route('/messages', methods=['GET'])
def get_messages():
    return jsonify({"messages": messages})

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
