FROM jenkins/jenkins:lts

ARG DOCKER_GID=123

USER root

# Add GH key to known hosts
RUN mkdir -p /var/jenkins_home/.ssh && \
    ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts && \
    chmod 644 /var/jenkins_home/.ssh/known_hosts && \
    chown -R jenkins:jenkins /var/jenkins_home/.ssh

COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

ENV MAVEN_VERSION=3.9.6
ENV MAVEN_HOME=/opt/maven

RUN curl -fsSL https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -o /tmp/maven.tar.gz && \
    mkdir -p $MAVEN_HOME && \
    tar -xzf /tmp/maven.tar.gz -C $MAVEN_HOME --strip-components=1 && \
    rm /tmp/maven.tar.gz

# Install Docker CLI so Jenkins can run docker exec/run
RUN apt-get update && \
    apt-get install -y docker.io && \
    groupadd messagebus || true && \
    usermod -aG messagebus jenkins

RUN curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose && docker-compose version

# Install Python and pipx
RUN apt-get update && \
    apt-get install -y --fix-broken python3 python3-pip python3-venv pipx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Update PATH
ENV PIPX_HOME=/var/jenkins_home/.local/bin
ENV PATH="$PIPX_HOME:$MAVEN_HOME/bin:$PATH"

# Add pipx execution permissions
RUN mkdir -p $PIPX_HOME && \
    chmod -R 755 $PIPX_HOME && \
    chown -R jenkins:jenkins $PIPX_HOME

RUN mkdir -p /zap-logs

USER jenkins

# Ensure pipx in PATH
RUN pipx ensurepath

# Install Ansible
RUN pipx install --include-deps ansible

