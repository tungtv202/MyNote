# kill port
wget https://raw.github.com/abdennour/miscs.sh/master/killport
killport 3000 

# check port running
sudo netstat -lnp

# get public IP
dig +short myip.opendns.com @resolver1.opendns.com

# show size directory, "MB"
alias ls="ls --block-size=M"
