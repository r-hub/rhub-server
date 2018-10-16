var jenkins_url = process.env.JENKINS_URL ||
    'http://jenkins.rhub.me';
var jenkins = require('jenkins');
var jenkins_xml = require('../lib/jenkins_xml');
var quote = require('shell-quote').quote;

function builder(job, callback) {

    var conn = jenkins({ baseUrl: jenkins_url, crumbIssuer: true });
    add_pkg(conn, job, function(err) {
	if (err) { callback(err); return; }
	callback(null);
    })
}

function add_pkg(conn, job, callback) {

    add_jenkins_job(conn, job, function(err) {
	if (err) { console.log(err); callback(err); return; }

	build_jenkins_job(conn, job, function(err) {
	    if (err) { console.log(err); callback(err); return; }
	    callback(null);
	})
    })
}

function add_jenkins_job(conn, job, callback) {
    var job_name = jenkins_job_name(job);
    jenkins_xml(job, function(err, job_xml) {
	if (err) { callback(err); return; }
	conn.job.create(
	    job_name,
	    job_xml,
	    function(err) {
		if (err) { console.log(err); callback(err); return; }
		callback(null);
	    }
	)
    })
}

function build_jenkins_job(conn, job, callback) {
    var job_name = jenkins_job_name(job);
    var parameters = {
        'package': job.package,
        'filename': job.filename,
        'url': job.url,
        'image': job.image || "",
        'checkArgs': job.checkArgs || "",
        'envVars': flatten_env_vars(job.envVars) || "",
        'rversion': job.rversion || "r-release",
        'startPingUrl': job.builder + '/build/in-progress/' + job_name,
        'endPingUrl': job.builder + '/build',
        'build': (job.options.build || false) + '',
        'pkgname': job.pkg + ''
    };
  
    conn.job.build(
        job_name,
        { 'parameters': parameters },
        function(err) {
	    if (err) { console.log(err); callback(err); return; }
	    callback(null)
	}
    )
}

function flatten_env_vars(x) {
    if (x === null || x === undefined || x === "") return(null);
    return Object.keys(x)
        .map(function(key) {
	    var k = String(key);
	    var v = String(x[key]);
	    return quote([k]) + "=" + quote([v]); })
        .join("\n");
}

function jenkins_job_name(job) {
    return job.buildId;
}

module.exports = builder;
