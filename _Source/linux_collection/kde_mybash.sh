# PRIVATE_ENVIRONMENT_PATH template -> private_environment_template.sh 

source $PRIVATE_ENVIRONMENT_PATH

java11() {
    export JAVA_HOME=$JAVA_HOME_11
}

java17() {
    export JAVA_HOME=$JAVA_HOME_17
}

# Set Java17 by default
java17

# export PATH=$PATH:$JAVA_HOME/bin
export PATH=$PATH:$MAVEN_HOME/bin

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


# De cai dat ksystemstats, search cac package con thieu tren Muon package manager. Keyword bat dau bang `libkf5`
# Luu y: search bang `kf5` la mot so package ko ra
# ref: https://bugs.kde.org/show_bug.cgi?id=438318#c37
# https://invent.kde.org/plasma/ksystemstats/-/tree/Plasma/5.23

# 1) You need to open the required branch of ksystemstats (in your case Plasma/5.23: https://invent.kde.org/plasma/ksystemstats/-/tree/Plasma/5.23), download its contents to your computer.
# 2) Automatically or manually apply the patch from comment #33 to the file ./plugins/lmsensors/lmsensors.cpp (comment or remove some lines).
# 3) In the root folder of the project run:
# cmake ./
# cmake --build ./
# 4) File ksystemstats_plugin_lmsensors.so will appear in the folder ./bin, it must be copied with a replacement to /usr/lib/qt/plugins/ksystemstats/ (this path is used by me, I am not sure that it is the same on all distributions) (you can backup old file).
# 5) After that, just restart System Monitor and all sensors should appear in the "Hardware sensors" category.

# This fix is simple enough, but I have to repeat all this with some Plasma updates, which is a bit depressing.
# This may not be the most proper way to do it, but it works for me.
# And if this is not the place for such explanations, please, someone write me about it, so that I don't repeat this mistake in the future.