# How to use?
#   - 1. set Fshare Env
#   - 2. run bash commend `bash bash_getlink_fshare QVVJT9JL2B24`  (with QVVJT9JL2B24 is the key of fshare link, ex: https://www.fshare.vn/file/QVVJT9JL2B24)

# Should export fshare env first
export FSHARE_USERNAME="TODO" # example: tungtv202@gmail.com
export FSHARE_PASSWORD="TODO" # example: password123
export FSHARE_APP_KEY="TODO" # example: dMnqMMZMUnN5YpvKENaEhdQQ5tynqddt
export FSHARE_USER_AGENT="TODO"  # example: Dellxps-9500
export FSHARE_BEAR_TOKEN="TODO"  # example: efdf39c90189abfbff339ae344c28db5f78c2885

# Get Token & SESSION
export TOKEN_RESPONSE=$(curl -s --location --request POST 'https://api.fshare.vn/api/user/login' \
--header 'Content-Type: application/json' \
--header 'User-Agent: '"$FSHARE_USER_AGENT"'' \
--data-raw '{
	"user_email" : "'"$FSHARE_USERNAME"'",
	"password":	"'"$FSHARE_PASSWORD"'",
	"app_key" : "'"$FSHARE_APP_KEY"'"
}')

export TOKEN=$( echo "$TOKEN_RESPONSE" |  python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")
export SESSION=$( echo "$TOKEN_RESPONSE" |  python3 -c "import sys, json; print(json.load(sys.stdin)['session_id'])")

# Get LINK
export LINK_RESPONSE=$(curl -s --location --request POST 'https://api.fshare.vn/api/session/download' \
--header 'Content-Type: application/json' \
--header 'User-Agent: '"$FSHARE_USER_AGENT"'' \
--header 'Authorization: Bearer '"$FSHARE_BEAR_TOKEN"'' \
--header 'Cookie: session_id='"$SESSION"'' \
--data-raw '{
	"zipflag" : 0,
	"url" : "https://www.fshare.vn/file/'"$1"'",
	"password" : "",
	"token": "'"$TOKEN"'"
}')
export LINK=$( echo "$LINK_RESPONSE" |  python3 -c "import sys, json; print(json.load(sys.stdin)['location'])")
echo $LINK

if [ "$2" == "v" ]; then
 vlc $LINK
fi

if [ "$2" == "w" ]; then
 wget $LINK
fi
