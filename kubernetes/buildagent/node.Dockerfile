FROM ubuntu:20.04

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
    software-properties-common \
    unzip

# Install OpenJDK 17
RUN apt-get install -y openjdk-17-jdk

# Set JAVA_HOME environment variable
ENV JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64

# Add JAVA_HOME to PATH
ENV PATH $JAVA_HOME/bin:$PATH

# Verify the installation
RUN java -version

RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb

RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb

RUN apt-get purge nodejs* \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends node.js \
    && node -v && npm -v \
    && npm i -g pnpm

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

WORKDIR /certificates

RUN apt-get update \
    && apt-get install -y powershell \
    && apt install -y awscli \
    && pwsh \
    &&  wget -qO /certificates/ca-bundle.pem https://{URL}/ca-bundle.pem

ENV NODE_EXTRA_CA_CERTS=/certificates/ca-bundle.pem

ENV TARGETARCH=linux-x64

# Create agent user and add to necessary groups
RUN groupadd -r chromeuser && useradd -m -d /home/agent -u 10000 -g chromeuser -G audio,video agent && \
    mkdir -p /home/agent/Downloads && \
    chown -R agent:chromeuser /home/agent

ENTRYPOINT [ "./start.sh" ]

WORKDIR /azp

COPY ./start.sh .

RUN chown -R agent:chromeuser /azp /usr/lib/node_modules /usr/bin && chmod +x start.sh

USER agent

ENTRYPOINT [ "./start.sh" ]
