var fs = require('fs');
var mustache = require('mustache');
var xml_encode = require('../lib/xml_encode');

var artifacts = process.env.RHUB_ARTIFACTS || "ssh";

function jenkins_xml(job, callback) {

    // For the transition, we don't have ostype
    var os = job.ostype || 'Linux';
    os = os.toLowerCase();
    var template = './templates/job-' + os + '.xml';

    fs.readFile(
	template,
	'utf8',
	function(err, template) {
	    if (err) { console.log(err); callback(err); return; }

	    fs.readFile(
		'./templates/commands-' + os + '.txt',
		'utf8',
		function(err, command) {
		    if (err) { console.log(err); callback(err); return; }
		    var macos_version =
			job.platforminfo["macos-version"] || "";
		    var r_version = job.platforminfo["rversion"] || 'r-release';
		    var data = { 'commands': xml_encode(command),
				 'email': xml_encode(job.email),
				 'macos-version': xml_encode(macos_version),
				 'r-version': xml_encode(r_version) };

		    if (artifacts == "ssh") {
		      fs.readFile('./templates/job-ssh-publish.txt',
				  'utf8',
				  function(err, ssh) {
				    if (err) {
				      console.log(err);
				      return callback(err);
				    }
				    data['ssh-publish'] = xml_encode(ssh);
				    var res = mustache.render(template, data);
				    callback(null, res);
				  })
		    } else {
		      data['ssh-publish'] = '';
		      var res = mustache.render(template, data);
		      callback(null, res);
		    }
		}
	    )
	}
    )
}

module.exports = jenkins_xml;
