FROM ubuntu:20.04
ENV TARGETARCH=linux-x64
ENV SHELL=/bin/bash 
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    wget \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common

RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb

RUN apt-get update \
    && apt-get install -y powershell \
    && pwsh

RUN apt-get update \
    && apt-get install -y dotnet-sdk-8.0 \
    && dotnet workload update \
    && dotnet workload install aspire


RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

# The following instructions are required due to a bug of Microsoft's scripts
RUN groupadd -g "10000" agent \
    && useradd -m -d /home/agent  -u "10000" -g "10000"  agent

RUN chown -R agent:agent /azp /home/agent \
    && chmod 770 /azp /home/agent

USER agent

ENTRYPOINT ["./start.sh"]
