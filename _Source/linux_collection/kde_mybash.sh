# PRIVATE_ENVIRONMENT_PATH template -> private_environment_template.sh 

source $PRIVATE_ENVIRONMENT_PATH

java11() {
    JAVA_HOME=$JAVA_HOME_11
}

java17() {
    JAVA_HOME=$JAVA_HOME_17
}

# Set Java17 by default
java17

PATH=$PATH:$JAVA_HOME/bin
PATH=$PATH:$MAVEN_HOME/bin

alias dcd="docker-compose down"
alias dcu="docker-compose up"

# Maven 
alias mvnfire="mvn clean install -Dmaven.javadoc.skip=true -DskipTests"

# Git
alias gitupdate="git pull origin HEAD && git submodule update"

# PC
alias sdn="sudo shutdown -h now"
alias rsn="sudo reboot -h now"

# AWS
alias s3upload="bash $S3UPLOAD_SHELL_PATH"

# mkdir && cd
mkcdir ()
{
    mkdir -p -- "$1" &&
      cd -P -- "$1"
}

source /home/tungtv/workplace/MyNote/_Source/linux_collection/bash_getlink_fshare.sh
