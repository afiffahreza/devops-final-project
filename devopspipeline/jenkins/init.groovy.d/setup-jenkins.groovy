import jenkins.model.*
import jenkins.install.InstallState
import hudson.security.*
import java.util.logging.Logger
import jenkins.model.Jenkins
import jenkins.install.InstallState
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import groovy.json.JsonSlurper
import hudson.model.*
import hudson.plugins.sonar.*
import com.cloudbees.plugins.credentials.CredentialsScope
import jenkins.model.GlobalConfiguration

def logger = Logger.getLogger("")
def jenkins = Jenkins.getInstance()

def adminUsername = System.getenv('JENKINS_ADMIN_USERNAME') ?: 'admin'
def adminPassword = System.getenv('JENKINS_ADMIN_PASSWORD') ?: 'admin'



println "--> Loaded Jenkins plugins:"
Jenkins.instance.pluginManager.plugins.each { plugin ->
    println "    ${plugin.getShortName()} (${plugin.getVersion()})"
}


// Explicitly create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
try {
    // Create admin user
    // TODO: use environment variables
    hudsonRealm.createAccount(adminUsername, adminPassword)
    jenkins.setSecurityRealm(hudsonRealm)

    // Set full control authorization strategy
    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    jenkins.setAuthorizationStrategy(strategy)

    logger.info("Admin user created successfully with username: ${adminUsername}")
} catch (Exception e) {
    logger.severe("Failed to create admin user: ${e.message}")
}

// === 1. Create SonarQube token credential ===
def SONARQUBE_URL = "http://sonarqube:9000"
def ADMIN_USER = "admin"
def ADMIN_PASS = "DevopsSonar1."
def TOKEN_NAME = "jenkins"

// Wait for SonarQube to be ready
sleep(20000)

def changePassword = ["bash", "-c", """
  curl -u admin:admin -X POST http://localhost:9000/api/users/change_password -d "login=admin" -d "previousPassword=admin" -d "password=${ADMIN_PASS}"
"""].execute().text

def tokenJson = ["bash", "-c", """
  curl -s -u ${ADMIN_USER}:${ADMIN_PASS} -X POST ${SONARQUBE_URL}/api/user_tokens/generate -d "name=${TOKEN_NAME}"
"""].execute().text

def tokenResp = new JsonSlurper().parseText(tokenJson)
def token = tokenResp.token

if (token) {
    println "✅ Token created: ${token}"

    def creds = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        "sonarqube",
        "Auto-created SonarQube token",
        Secret.fromString(token)
    )

    def credentialsStore = jenkins.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
    credentialsStore.addCredentials(Domain.global(), sonarTokenCreds)
    println "🔐 Token added to Jenkins credentials."

// === 2. Configure SonarQube installation ===
    def sonarName = "sonarqube"
    def sonarInstExists = false

    def sonarDescriptor = SonarGlobalConfiguration.get()
    def sonarInstallations = sonarDescriptor.getInstallations()

    sonarInstallations.each {
    if (it.getName() == sonarName) {
        sonarInstExists = true
    }

    if (!sonarInstExists) {
        println "[INFO] Adding SonarQube installation..."
        def newInst = new SonarInstallation(
            sonarName,
            SONARQUBE_URL,
            sonarqube,
            "",
            "",
            "",
            false,
            ""
        )

        def updatedList = sonarInstallations as List
        updatedList.add(newInst)
        sonarDescriptor.setInstallations(updatedList.toArray(new SonarInstallation[0]))
        sonarDescriptor.save()
    } else {
        println "[INFO] SonarQube installation already exists"
    }

println "[INFO] === SonarQube Configuration Complete ==="
}

} else {
    println "❌ Failed to create token. Response: ${tokenJson}"
}

try {
    jenkins.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
    logger.info("Jenkins setup wizard marked as completed")
} catch (Exception e) {
    logger.warning("Could not complete setup wizard: ${e.message}")
}

def workflowScript = new File("/var/jenkins_home/workflows/gh_pipeline.groovy")
if (workflowScript.exists()) {
    println "--> Loading job workflows from: ${workflowScript}"
    evaluate workflowScript
} else {
    println "--> No workflow job script found"
}

// Save configuration changes
jenkins.save()