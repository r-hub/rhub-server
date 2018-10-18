
var urls = require('../lib/urls');
var nodemailer = require('nodemailer');

function send_email_smtp(mail, callback) {
  if (! urls.smtp_server) { return callback("No mail server"); }

  var config = {
    host: urls.smtp_server,
    port: urls.smtp_port,
    secure: urls.smtp_tls_required
  }

  if (!! urls.smtp_username || !! urls.smtp_password) {
    config.auth = {
      user: urls.smtp_username || '',
      pass: urls.smtp_password || '' };
  }

  var transporter = nodemailer.createTransport(config);
  transporter.sendMail(mail, callback);
}

module.exports = send_email_smtp;
