import jenkins.model.Jenkins
import hudson.plugins.git.BranchSpec
import hudson.plugins.git.GitSCM
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition

import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey
import hudson.triggers.SCMTrigger

def GH_REPO_URL = System.getenv("GH_REPO_URL")
def GH_DEPLOY_KEY = new String(System.getenv("GH_DEPLOY_KEY").decodeBase64())

def githubCredsId = "github-deploy-key"
def jobName = "GitHubPipeline"
def instance = Jenkins.getInstance()

if (!GH_REPO_URL || !GH_DEPLOY_KEY) {
    println "-->  GH_REPO_URL or GH_DEPLOY_KEY environment variables not set"
    return
}

def credsStore = SystemCredentialsProvider.getInstance().getStore()
def existingCred = credsStore.getCredentials(Domain.global()).find { it.id == githubCredsId }

if (!existingCred) {
    println "--> Adding SSH deploy key credential"

    def sshCred = new BasicSSHUserPrivateKey(
        CredentialsScope.GLOBAL,
        githubCredsId,
        "git",
        new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(GH_DEPLOY_KEY),
        null,
        "GitHub Deploy Key"
    )

    credsStore.addCredentials(Domain.global(), sshCred)
} else {
    println "--> SSH credential '${githubCredsId}' already exists"
}

def existingJob = instance.getItem(jobName)
if (!existingJob) {
    println "--> Creating pipeline job: ${jobName}"

    def job = instance.createProject(WorkflowJob, jobName)

    def scm = new GitSCM(
        GitSCM.createRepoList(GH_REPO_URL, githubCredsId),
        [new BranchSpec("*/master")],
        false, [], null, null, []
    )

    def definition = new CpsScmFlowDefinition(scm, "devopspipeline/jenkins/Jenkinsfile")
    job.setDefinition(definition)
    
    // Polling webhook
    // job.addTrigger(new GitHubPushTrigger())
    def scmTrigger = new SCMTrigger("* * * * *")
    job.addTrigger(scmTrigger)
    job.setQuietPeriod(0)
    job.save()

    println "--> Job '${jobName}' created successfully"
} else {
    println "--> Job '${jobName}' already exists"
}
