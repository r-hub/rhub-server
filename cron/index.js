var CronJob = require('cron').CronJob;
var jenkins = require('jenkins');
var async = require('async');
var fs = require('fs');

var jenkins_url = process.env.JENKINS_URL;

try {
  var jenkins_pass = fs.readFileSync("/run/secrets/jenkins.pass", 'utf8')
      .trim();
  jenkins_url = jenkins_url.replace("<password>", jenkins_pass);
} catch (e) {
  console.log("No jenkins.pass secret, JENKINS_URL is used as is");
}

// Time limit to delete job
var TIME_LIMIT = 1000 /* ms */ * 60 /* s */ * 60 /* min */ * 24 * 3;
// How often to run the job reaper, once an hour, at **:42:42
var CRON_JOB_REAPER = '48 45 * * * *';

var job = new CronJob(CRON_JOB_REAPER, function() {

    console.log("Running Jenkins job reaper");
    var jen = jenkins({ baseUrl: jenkins_url, crumbIssuer: true });
    jen.job.list(function(err, data) {
	if (err) { console.log('Cannot get Jenkins job list'); return; }
	async.eachLimit(
	    data,
	    3,
	    function(job, cb) { delete_if_old(jen, job, cb); }
	);
    });

}, null, true, 'America/New_York');

function delete_if_old(jen, job, callback) {
    jen.job.get(job.name, function(err, data) {
        if (err) {
	    console.log('Cannot get Jenkins job ' + job.name);
	    return callback(null);
	}

        if (data.actions) {
	  for (i = 0; i < data.actions.length; i++) {
	    var def = data.actions[i].parameterDefinitions;
	    if (def === undefined) continue;
	    for (j = 0; j < def.length; j++) {
	      if (def[j].name == 'keep') {
		if (def[j].defaultParameterValue.value) {
		  console.log('Keeping ' + job.name);
		  return callback(null);
		}
	      }
	    }
	  }
	}

	// No builds (yet?)
	if (! data.lastBuild || ! data.lastBuild.number) {
	    return callback(null);
	}

	jen.build.get(job.name, data.lastBuild.number, function(err, data) {
	    if (err) {
		console.log('Cannot get Jenkins build ' + job.name + ' ' +
			    data.lastBuild.number);
		return callback(null);
	    }
	    var diff = new Date() - new Date(data.timestamp);
	    // about three days
	    if (diff > TIME_LIMIT) {
		return delete_job(jen, job, callback);
	    }
	    return callback(null);
	});
    });
}

function delete_job(jen, job, callback) {
    jen.job.destroy(job.name, function(err) {
	if (err) {
	    console.log('Cannot delete Jenkins job ' + job.name);
	} else {
	    console.log('Deleted Jenkins job ' + job.name);
	}
	return callback(null);
    });
}

module.exports = job;
