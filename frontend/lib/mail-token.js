
var multiline = require('multiline');
var send_email =  require('../lib/send-email');

var text_body = multiline(function() { /*
Dear R package developer!

This is your verification code for your r-hub check submission:

${code}

If you haven't submitted anything to r-hub, please ignore this email.

Please reply to this email or contact support@rhub.io if you have
questions.

Sincerely,
The r-hub team

*/ });

function mail_token(email, token, callback) {

    var mail = {
	from: '"r-hub builder" <support@rhub.io>',
	to: email,
	subject: 'r-hub check email validation',
	text: text_body.replace("${code}", token)
    };

    send_email(mail, function(error, info) {
        if (error) {
	    console.log(error);
	    return callback(error);
	}
	console.log('Message sent: ' + info.response);
	callback(null, info.response);
    });
}

module.exports = mail_token;
