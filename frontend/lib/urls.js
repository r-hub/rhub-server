
require('dotenv').config();

var urls = {
    'jenkins': process.env.JENKINS_URL || 'http://jenkins.url',
    'validemail_url':
      process.env.DOKKU_REDIS_GREEN_URL ||
      process.env.DOKKU_REDIS_PURPLE_URL ||
      process.env.REDIS_EMAIL_URL,
    'logdb': process.env.LOGDB_URL || 'http://logdb.url',

    // Email settings
    'email_mode': process.env.RHUB_EMAIL_MODE || 'mailgun',
    'mailgun_api_key': process.env.MAILGUN_API_KEY || 'key',
    'mailgun_domain': process.env.MAILGUN_DOMAIN || 'rhub.io',
    'smtp_server': process.env.RHUB_SMTP_SERVER,
    'smtp_username': process.env.RHUB_SMTP_USERNAME,
    'smtp_password': process.env.RHUB_SMTP_PASSWORD,
    'smtp_port': process.env.RHUB_SMTP_PORT || 25,
    // TLS required by default, set to 'false' (w/o quotes) to disable
    'smtp_tls_required': ! (process.env.RHUB_SMTP_TLS_REQUIRED === 'false')
};

module.exports = urls;
