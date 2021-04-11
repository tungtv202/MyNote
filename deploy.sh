rm -rf  ../tungtv202.github.io/source/_posts/*
cp -rf . ../tungtv202.github.io/source/_posts/.
rm -rf ../tungtv202.github.io/source/_posts/_Source
rm -rf ../tungtv202.github.io/source/_posts/.idea
rm -rf ../tungtv202.github.io/source/_posts/_Source
rm ../tungtv202.github.io/source/_posts/README.md
rm ../tungtv202.github.io/source/_posts/deploy.sh
cd ../tungtv202.github.io/
hexo clean
hexo deploy
