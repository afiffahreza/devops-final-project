import jenkins.model.*
import hudson.security.*
import java.util.logging.Logger

def logger = Logger.getLogger("")
def jenkins = Jenkins.getInstance()

def adminUsername = System.getenv('JENKINS_ADMIN_USERNAME') ?: 'admin'
def adminPassword = System.getenv('JENKINS_ADMIN_PASSWORD') ?: 'admin'

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

// Install Prometheus plugin
def pluginManager = jenkins.getPluginManager()
def updateCenter = jenkins.getUpdateCenter()

if (!pluginManager.getPlugin("prometheus")) {
    updateCenter.updateAllSites()
    def prometheusPlugin = updateCenter.getPlugin("prometheus")
    
    if (prometheusPlugin) {
        try {
            def installFuture = prometheusPlugin.deploy()
            installFuture.get()
            jenkins.save()
            logger.info("Prometheus plugin installed successfully")
        } catch (Exception e) {
            logger.severe("Failed to install Prometheus plugin: ${e.message}")
        }
    } else {
        logger.info("Could not find Prometheus plugin in update center")
    }
} else {
    logger.info("Prometheus plugin already installed")
}

// Save configuration changes
jenkins.save()