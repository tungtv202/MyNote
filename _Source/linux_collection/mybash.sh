# sudo apt install openjdk-11-jdk
#JAVA_HOME=/home/tungtv/install_and_tool/jdk-11
#JAVA_HOME=/home/tungtv/.jdks/corretto-1.8.0_322
# PATH=$PATH:$JAVA_HOME/bin
# /home/tungtv/install_and_tool/apache-maven-3.8.5
export M2_HOME=/home/tungtv/install_and_tool/apache-maven-3.8.5
export M2=$M2_HOME/bin 
export PATH=$M2:$PATH
# scala
export PATH="$PATH:/home/tungtv/.local/share/coursier/bin"  

# For mouse - scroll wheel
# sudo update-alternatives --config javac
# sudo update-alternatives --config java

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


# Getlink fshare
alias fs="bash /home/tungtv/workplace/fshare/getlink"
alias s3upload="bash /home/tungtv/workplace/MyNote/_Source/linux_collection/s3upload.sh"

# pwd and Copy to clipboard
alias pwc="pwd | xclip -selection clipboard && pwd"

# mkdir && cd
mkcdir ()
{
    mkdir -p -- "$1" &&
      cd -P -- "$1"
}

alias wo="warp-cli enable-always-on"
alias wf="warp-cli disable-always-on"
alias neofetch="neofetch --off"


#sudo service nginx stop
