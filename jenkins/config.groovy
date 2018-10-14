
import jenkins.model.Jenkins
import jenkins.model.JenkinsLocationConfiguration
import jenkins.security.s2m.*

def env = System.getenv()

// Disable CLI remoting
Jenkins.instance.getDescriptor("jenkins.CLI").get().setEnabled(false)

// Set Jenkins root url
jlc = JenkinsLocationConfiguration.get()
jlc.setUrl(env.JENKINS_ROOT_URL)
jlc.save()

// Turn on agent to master security subsystem
Jenkins.instance.injector.getInstance(AdminWhitelistRule.class)
    .setMasterKillSwitch(false);
Jenkins.instance.save()

// Enable CSRF Protection
import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.model.Jenkins

def instance = Jenkins.instance
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))
instance.save()
