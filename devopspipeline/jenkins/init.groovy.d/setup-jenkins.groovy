import jenkins.model.*
import hudson.security.*
import java.util.logging.Logger
import jenkins.model.Jenkins
import jenkins.install.InstallState

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

    logger.info("Admin user created successfully")
} catch (Exception e) {
    logger.severe("Failed to create admin user: ${e.message}")
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