## init.groovy.d/setup-jenkins.groovy
    Contains the setup script. Will load jobs created by the script below

## workflows/gh_pipeline.groovy
    Initializes the job declaratively written in Jenkinsfile. Put tasks in there.
    Contains code to poll (for now) GitHub for changes

## plugins.txt
    List of plugins to add to jenkins. Will probably need more later

## jenkins.Dockerfile
    Added commands to configure the jenkins container

## Jenkinsfile
    A declarative spec for jenkins jobs run when a change is detected.
