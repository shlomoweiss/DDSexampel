FROM  ubuntu-fastdds:v3.2.2
WORKDIR /main
COPY node-v22.18.0-linux-x64.tar.gz .
RUN tar -xzf node-v22.18.0-linux-x64.tar.gz && \
    mv node-v22.18.0-linux-x64 node && \
    mv node /usr/local && \
    echo 'export PATH="/usr/local/node/bin:$PATH"' > ~/.bashrc && \
    apt update && apt install -y curl cmake
RUN apt install software-properties-common -y && \
    add-apt-repository -y ppa:dotnet/backports && \
    apt-get install -y dotnet-sdk-9.0

RUN apt install software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && apt update &&\
    apt install -y python3.12 && \
    apt install python3-pip -y && \
    echo 'alias python=python3.12' >> ~/.bashrc
RUN apt install -y swig 


