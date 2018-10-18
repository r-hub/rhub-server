
var urls = require('../lib/urls');

function send_email_mailgun(mail, callback) {
  var mailgun = require('mailgun-js')(
    { apiKey: urls.mailgun_api_key, domain: urls.mailgun_domain });
  mailgun.messages().send(mail, callback);
}

module.exports = send_email_mailgun;
