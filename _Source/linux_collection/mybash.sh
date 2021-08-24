
JAVA_HOME=/usr/local/jdk-11.0.2
#JAVA_HOME=/usr/local/jdk1.8.0_231
PATH=$PATH:$JAVA_HOME/bin
# For mouse - scroll wheel
alias ms="bash /home/tungtv/workplace/MyNote/_Source/linux_collection/mousewheel.sh"

# Docker
alias dcd="docker-compose down"
alias dcu="docker-compose up"

# Maven 
alias mvnfire="mvn clean install -Dmaven.javadoc.skip=true -DskipTests"

# Git
alias gitupdate="git pull origin HEAD && git submodule update"
alias gitreset="git reset --hard && git clean -fd && git submodule update --init && git submodule foreach git reset --hard"
alias gitrsmd="git submodule update --init && git submodule foreach git reset --hard"
alias gitlog="git log --graph --oneline --all"

# PC
alias sdn="sudo shutdown -h now"
alias rsn="sudo reboot -h now"
alias open="nautilus ."
. /usr/share/autojump/autojump.sh

# For keyboard RK84
echo 0 | sudo tee /sys/module/hid_apple/parameters/fnmode &> /dev/null

# Getlink fshare
alias fs="bash /home/tungtv/workplace/fshare/getlink"
alias s3upload="bash /home/tungtv/workplace/MyNote/_Source/linux_collection/s3upload.sh"
