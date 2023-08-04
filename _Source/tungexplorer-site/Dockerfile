FROM node:lts-bookworm

RUN apt-get update && apt-get install git -y && apt-get install rsync -y

RUN npm install hexo-cli -g
RUN hexo init tungexplorer && cd tungexplorer && npm install

WORKDIR /tungexplorer

RUN npm install hexo-deployer-git --save \
    && npm install hexo-filter-mermaid-diagrams --save \
    && npm install hexo-generator-search --save \
    && npm install hexo-wordcount --save

# Copy hexo theme
COPY ./3-hexo /tungexplorer/themes/3-hexo
COPY refresh.sh /tungexplorer/refresh.sh

COPY ./_config.yml /tungexplorer/_config.yml
RUN rm -rf /tungexplorer/source/_posts/*
RUN git clone https://github.com/tungtv202/MyNote.git
RUN rsync -av --progress MyNote/. source/_posts/. --exclude .git \
    --exclude .gitignore --exclude README.md --exclude deploy.sh \
    --exclude _Source --exclude tung_explorer.png

# Id git
RUN git config --global user.email "tungtv202@gmail.com"
RUN git config --global user.name "tungtv202-server"

# Hexo build
RUN chmod +x refresh.sh
ENTRYPOINT ["sh","/tungexplorer/refresh.sh"]
