#!/bin/sh
# Check ssh key is not exist then create new ssh key
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "tungtv202@gmail.com" -N "" -f ~/.ssh/id_ed25519
    echo "=========================================================="
    echo "=========================================================="
    echo "Copy this key to github: https://github.com/tungtv202/tungtv202.github.io/settings/keys"
    cat ~/.ssh/id_ed25519.pub
    echo "=========================================================="
    echo "=========================================================="
    sleep 30
fi

cd MyNote
git pull
cd ..
rsync -av --progress MyNote/. source/_posts/. --exclude .git \
    --exclude .gitignore --exclude README.md --exclude deploy.sh \
    --exclude _Source --exclude tung_explorer.png --exclude refresh.sh
hexo clean
hexo generate

# Must setting git ssh key first
hexo deploy
sleep 120