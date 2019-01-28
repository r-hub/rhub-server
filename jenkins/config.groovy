
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

// Quiet period
instance = Jenkins.getInstance()
instance.setQuietPeriod(0)

// Env vars
import hudson.EnvVars;
import hudson.slaves.EnvironmentVariablesNodeProperty;
import hudson.slaves.NodeProperty;
import hudson.slaves.NodePropertyDescriptor;
import hudson.util.DescribableList;
import jenkins.model.Jenkins;

public createGlobalEnvironmentVariables(String key, String value) {

  Jenkins instance = Jenkins.getInstance();

  DescribableList<NodeProperty<?>, NodePropertyDescriptor> globalNodeProperties =
    instance.getGlobalNodeProperties();
  List<EnvironmentVariablesNodeProperty> envVarsNodePropertyList =
     globalNodeProperties.getAll(EnvironmentVariablesNodeProperty.class);

  EnvironmentVariablesNodeProperty newEnvVarsNodeProperty = null;
  EnvVars envVars = null;

  if (envVarsNodePropertyList == null || envVarsNodePropertyList.size() == 0) {
    newEnvVarsNodeProperty =
      new hudson.slaves.EnvironmentVariablesNodeProperty();
    globalNodeProperties.add(newEnvVarsNodeProperty);
    envVars = newEnvVarsNodeProperty.getEnvVars();
  } else {
    envVars = envVarsNodePropertyList.get(0).getEnvVars();
  }
  envVars.put(key, value)
  instance.save()
}

createGlobalEnvironmentVariables('PS4','+R-HUB-R-HUB-R-HUB')

// Create Folders
def jobs_str = '''
<com.cloudbees.hudson.plugins.folder.Folder plugin="cloudbees-folder@6.7">
  <description>User submitted builds.</description>
  <properties/>
  <folderViews class="com.cloudbees.hudson.plugins.folder.views.DefaultFolderViewHolder">
    <views>
      <hudson.model.AllView>
        <owner class="com.cloudbees.hudson.plugins.folder.Folder" reference="../../../.."/>
        <name>All</name>
        <filterExecutors>false</filterExecutors>
        <filterQueue>false</filterQueue>
        <properties class="hudson.model.View$PropertyList"/>
      </hudson.model.AllView>
    </views>
    <tabBar class="hudson.views.DefaultViewsTabBar"/>
  </folderViews>
  <healthMetrics>
    <com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
      <nonRecursive>false</nonRecursive>
    </com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
  </healthMetrics>
  <icon class="com.cloudbees.hudson.plugins.folder.icons.StockFolderIcon"/>
</com.cloudbees.hudson.plugins.folder.Folder>
'''
def jobs_stream = new ByteArrayInputStream(jobs_str.getBytes())
Jenkins.instance.createProjectFromXML('Jobs', jobs_stream)

def manage_str = '''
<com.cloudbees.hudson.plugins.folder.Folder plugin="cloudbees-folder@6.7">
  <description>Internal jobs for  R-hub.</description>
  <properties/>
  <folderViews class="com.cloudbees.hudson.plugins.folder.views.DefaultFolderViewHolder">
    <views>
      <hudson.model.AllView>
        <owner class="com.cloudbees.hudson.plugins.folder.Folder" reference="../../../.."/>
        <name>All</name>
        <filterExecutors>false</filterExecutors>
        <filterQueue>false</filterQueue>
        <properties class="hudson.model.View$PropertyList"/>
      </hudson.model.AllView>
    </views>
    <tabBar class="hudson.views.DefaultViewsTabBar"/>
  </folderViews>
  <healthMetrics>
    <com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
      <nonRecursive>false</nonRecursive>
    </com.cloudbees.hudson.plugins.folder.health.WorstChildHealthMetric>
  </healthMetrics>
  <icon class="com.cloudbees.hudson.plugins.folder.icons.StockFolderIcon"/>
</com.cloudbees.hudson.plugins.folder.Folder>
'''
def manage_stream = new ByteArrayInputStream(manage_str.getBytes())
Jenkins.instance.createProjectFromXML('Management', manage_stream)
