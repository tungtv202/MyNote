#!/bin/bash

# How to use?
#   - 1. set Fshare Env
#   - 2. run bash commend `bash bash_getlink_fshare QVVJT9JL2B24`  (with QVVJT9JL2B24 is the key of fshare link, ex: https://www.fshare.vn/file/QVVJT9JL2B24)

# Should export fshare env first
#export FSHARE_USERNAME="TODO" # example: tungtv202@gmail.com
#export FSHARE_PASSWORD="TODO" # example: password123
#export FSHARE_APP_KEY="TODO" # example: dMnqMMZMUnN5YpvKENaEhdQQ5tynqddt
#export FSHARE_USER_AGENT="TODO"  # example: Dellxps-9500

# Get Token & SESSION

fs () {
	if [ -z "$TOKEN" ]; then 
		TOKEN_RESPONSE_CURRENT=$(curl -s --location --request POST 'https://api.fshare.vn/api/user/login' \
		--header 'Content-Type: application/json' \
		--header 'User-Agent: '"$FSHARE_USER_AGENT"'' \
		--data-raw '{
			"user_email" : "'"$FSHARE_USERNAME"'",
			"password":	"'"$FSHARE_PASSWORD"'",
			"app_key" : "'"$FSHARE_APP_KEY"'"
		}')
		TOKEN_CURRENT=$( echo "$TOKEN_RESPONSE_CURRENT" |  python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")
		SESSION_CURRENT=$( echo "$TOKEN_RESPONSE_CURRENT" |  python3 -c "import sys, json; print(json.load(sys.stdin)['session_id'])")
		export TOKEN=$TOKEN_CURRENT
		export SESSION=$SESSION_CURRENT
		echo "Fist session, TOKEN="$TOKEN "Session="$SESSION
	fi



	# Get LINK
	LINK_RESPONSE=$(curl -s --location --request POST 'https://api.fshare.vn/api/session/download' \
	--header 'Content-Type: application/json' \
	--header 'User-Agent: '"$FSHARE_USER_AGENT"'' \
	--header 'Cookie: session_id='"$SESSION"'' \
	--data-raw '{
		"zipflag" : 0,
		"url" : "'"$1"'",
		"password" : "",
		"token": "'"$TOKEN"'"
	}')
	LINK=$( echo "$LINK_RESPONSE" |  python3 -c "import sys, json; print(json.load(sys.stdin)['location'])")
	echo "Link"
	echo $2
	echo $LINK

  echo $LINK | xclip -selection clipboard
  if [[ "$2" = "v" ]]; then vlc $LINK;  fi
  if [[ "$2" = "w" ]]; then wget $LINK;  fi
}

pfs() {
  keyword=$1

  # Make the simplified curl request and store the JSON response
  response=$(curl -L -X POST "https://timfshare.com/api/v1/string-query-search?query=${keyword}" -s)

  # Extract the URL using jq
  url=$(echo "${response}" | jq -r '.data[] | select(.name | contains("'"${keyword}"'")) | .url' | head -n 1)

  # Print the URL
 if [ -n "${url}" ]; then
    echo "${url}"
	fs "${url}" v
  else
    echo "No URL"
  fi

  
}

wfs() {
  keyword=$1

  # Make the simplified curl request and store the JSON response
  response=$(curl -L -X POST "https://timfshare.com/api/v1/string-query-search?query=${keyword}" -s)

  # Extract the URL using jq
  url=$(echo "${response}" | jq -r '.data[] | select(.name | contains("'"${keyword}"'")) | .url' | head -n 1)

  # Print the URL
 if [ -n "${url}" ]; then
    echo "${url}"
	fs "${url}" w
  else
    echo "No URL"
  fi
}