FROM jenkins/jenkins:lts

# Add GH key to known hosts
RUN mkdir -p /var/jenkins_home/.ssh && \
    ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts && \
    chmod 644 /var/jenkins_home/.ssh/known_hosts && \
    chown -R jenkins:jenkins /var/jenkins_home/.ssh

COPY jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt



