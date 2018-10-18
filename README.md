
# R-hub Server 0.9

This repository contains a Docker Compose project, that describes
most of R-hub's services.

## Deploy R-hub locally

For testing and development you can simply deploy the project on your
computer, using Docker Compose. Try this first.

1. To make email notifications work, you'll have to configure R-hub's SMTP
settings. You can connect to an SMTP server, or use mailgun. For mailgun,
you need to set the `RHUB_EMAIL_MODE` variable to `mailgun`, and also set
the `MAILGUN_DOMAIN` and `MAILGUN_API_KEY` variables in the
[.env](.env) file. You can create a mailgun account at
<https://mailgun.com>. See <https://mailgun.com/pricing> for prices.
Currently each month the first 10,000 emails are free and
after that you pay at most $0.50 for 1,000 emails. To use an SMTP server,
see the [.env](.env) file. You need to set `RHUB_EMAIL_MODE` to `smtp` and
also set the `RHUB_SMTP_SERVER` variable. If you need need authentication
set `RHUB_SMTP_USERNAME` and `RHUB_SMTP_PASSWORD`.

1. By default the R-hub frontend will run on port 80 of 127.0.0.1. Make
sure this port is available on your machine. Note that by default
Docker will bind to 0.0.0.0:80, so all network interfaces.

1. Invoke `docker-compose` to deploy the project. This will download
multiple Docker images, so it might take a couple of minutes for the
first time.

1. `docker-compose logs --tail=100 -f` will show the logs of all services.

1. Point your web browser to <http://127.0.0.1>. Select "Advanced".
Select a Linux platform to build on (others are not implemented yet).

1. You'll need to authenticate yourself, either via GitHub, or an email
challenge. For GitHub authentication you must be the package maintainer,
you must have a GitHub account, and your package maintainer address must
be your primary address on GitHub. For email authentication, you must have
set up your mailgun environment variables.

1. After successful authentication, the build should start. Builds might
need to download additional Docker containers, so for each platform the
first build might take longer.

## Deploy R-hub remotely

Remote deployment is mostly similar to local, but some more preparation
is needed:

1. You'll need the IP address or hostname of the machine that will run
R-hub. If you deploy via `docker-machine`, then `docker-machine ip` prints
the IP address.

1. You need to create a GitHub OAuth App to make GitHub authentication
work. Go to <https://github.com/settings/developers> and create your
application. (Or create it under a GitHub organization.) It is important
that you set the _Authorization callback URL_ to
`<baseurl>/login/github/callback`.

1. After this, take the Client ID and Client Secret of the GitHub app,
and set the `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` environment
variables in the [.env](.env) file accordingly.

1. In the [.env](.env) file set the `RHUB_BUILDER_EXTERNAL_URL` variable to
the URL of the R-hub frontend. Also set `RHUB_ARTIFACTS_URL` to
`<baseurl>/artifacts/`.

1. Follow the instructions of the local deployment.

## Services

Short explanation on what the various services do.

### `frontend`

The node.js web app you interact with via the browser or the rhub R package.
It receives jobs, and puts them into a message queue. It stores the uploads.
It is also responsible for sending the status emails.

### `queue`

The RabbitMQ queue that stores submissions between the frontend and Jenkins.
For a local deployment, you can access it on port 3003, using an appropriate
RabbitMQ client.

### `backend`

node.js app that picks up submissions from the queue and creates Jenkins
jobs for them.

### `redis`

Database to store web sessions and authenticated emails (for the command
line app). For a local deployment you can access it directly with a Redis
client, e.g. `redis-cli`, on port 3001.

### `logdb`

CouchDB database that stores the jobs and also the check results. For a
local deployment you can access it directly via a web browser on port 3002.
Go to <http://localhost:3002> or <http://localhost:3002/_utils>.

### `logdb-seed`

Temporary container to add the design document to the `logdb` service.

### `jenkins`

Jenkins CI. For a local deployment you can access it at
<http://localhost:8080>. Manual configuration changes persist, as long as
you keep its Docker Volume, called `jenkins-data`.

### `linux-builder`

Jenkins Swarm node, that starts and manages containers for Linux builds.
It binds to the Docker socket, so it can start sibling containers for the
builds.

### `cron`

Container to run periodic maintanance tasks. Currently it cleans up old
Jenkins jobs.

### `nginx`

Connects the host machine with the frontend app.

## Current caveats

* You need to do your own backups. All data is persisted on Docker Volumes.
See the Docker manuals on backing up Volumes. The current volumes are:
   - `uploads-data`: the raw uploaded packages. These are only needed until
   the build starts.
   - `session-data`: web session data, and validated email data (created
   via the R package).
   - `log-data`: build logs.
   - `queue-data`: the message queue that stores the job before it is
   transfered to Jenkins.
   - `jenkins-data`: all files of Jenkins.
   - `artifacts-data`: the build artifact files.

* You need to do your own cleanup. If you don't want to keep anything,
you can stop R-hub and delete all volumes. Otherwise see
issue [#13](https://github.com/gaborcsardi/rhub-server/issues/13) for
things you might want to clean up. (Jenkins jobs are already cleaned up
by the cron service).

* The frontend is open, so if you want to deploy R-hub on an open host,
you might want to add authentication to it. This can be done by updating
the nginx service.

* We only tested this version locally on macOS and on DigitalOcean via
`docker-machine`.

## License

MIT @ R Consortium
