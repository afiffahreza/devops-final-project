FROM jenkins/jenkins:lts

USER root

RUN curl -L -o /tmp/corretto.tar.gz https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz && \
    mkdir -p /opt/corretto21 && \
    tar -xzf /tmp/corretto.tar.gz -C /opt/corretto21 --strip-components=1 && \
    rm /tmp/corretto.tar.gz

ENV JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
ENV PATH="$JAVA_HOME/bin:$PATH"

# Add GH key to known hosts
RUN mkdir -p /var/jenkins_home/.ssh && \
    ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts && \
    chmod 644 /var/jenkins_home/.ssh/known_hosts && \
    chown -R jenkins:jenkins /var/jenkins_home/.ssh

COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

USER jenkins

