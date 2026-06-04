

# Replace <YOUR_BOT_TOKEN> with your actual bot token from BotFather on Telegram
BOT_TOKEN="6302963671:AAFKnL8W31TjqbeEW4A_ZnenA6fShf1nNWc"
# Replace <CHAT_ID> with the ID of the chat you want to send the message to (user or group chat)
CHAT_ID=6275438853
# The message to be sent as the first command-line argument
MESSAGE="Something done"

if [ -z "$1" ]; then
    echo "send noti with default message"
else
    MESSAGE="$1"
fi

# Telegram API URL for sending messages
URL="https://api.telegram.org/bot$BOT_TOKEN/sendMessage"

# Send the message using curl
curl -s -X POST "$URL" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE"

echo "Message sent: $MESSAGE"
