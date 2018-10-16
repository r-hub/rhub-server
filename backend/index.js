var debug = require('debug');
var builder = require('./lib/builder');
var amqp = require('amqplib');

var broker_url = process.env.RABBITMQ_URL;

function run(q) {

  return amqp.connect(broker_url).then(function(conn) {
	process.once('SIGINT', function() { conn.close(); });
	return conn.createChannel().then(function(ch) {
	    var ok = ch.assertQueue(q, {durable: true});
	    ok = ok.then(function() { ch.prefetch(1); });
	    ok = ok.then(function() {
		ch.consume(q, doWork, {noAck: false});
	    });
	    return ok;

	    function doWork(msg) {
		var msg_obj = JSON.parse(msg.content.toString());
		console.log("STARTED: " + msg_obj);

		builder(msg_obj, function(error) {
		    if (!error) {
			console.log("DONE: " + msg_obj.package);
			ch.ack(msg);
		    } else {
			console.log("ERROR: " + msg_obj.package);
		    }
		})
	    }
	})
    })
}

function run_robust(q) {
  var q2 = q;

  function run_loop() {
    run(q2).catch(function(err) {
      console.log(err);
      console.log("Waiting 1 sec and trying again");
      setTimeout(run_loop, 1000);
    });
  }

  run_loop();
}

module.exports = run_robust;
