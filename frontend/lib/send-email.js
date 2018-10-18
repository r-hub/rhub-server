
var urls = require('../lib/urls');

function send_email(mail, callback) {
  if (urls.email_mode === 'mailgun') {
    var send_email_mailgun = require('../lib/send-email-mailgun');
    send_email_mailgun(mail, callback);
  } else {
    var send_email_smtp = require('../lib/send-email-smtp');
    send_email_smtp(mail, callback);
  }
}

module.exports = send_email;
