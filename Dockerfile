FROM  ubuntu-fastdds:v3.2.2
RUN apt update && apt install -y curl  cmake && \
     mkdir /main && \
    cd main && cp /mnt/node-v22.18.0-linux-x64.tar.gz . && \
    tar -xzf node-v22.18.0-linux-x64.tar.gz && \
    mv node-v22.18.0-linux-x64 node && \
    mv node /usr/local && echo 'export PATH="/usr/local/node/bin:$PATH"' >  ~/.bashrc && \
    source ~/.bashrc && \
    npm install -g node-gyp
WORKDIR /main