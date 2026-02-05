# Starting a Compose App

In this exercise, we will learn how to:
- Read a basic docker compose yaml file and understand what components it is
declaring
- Start, stop, and inspect the logs of an application defined by a docker
compose flag

## Preparing Service Images

1. Download the Dockercoins app from github:
```
$ git clone -b ee2.0 https://github.com/docker-training/orchestration-workshop.git
$ cd orchestration-workshop/dockercoins
```

This app consists of 5 services: a random number generator `rng`, a `hasher`, a
backend `worker`, a `redis` queue, and a `web` frontend; the code you just downloaded
has the source code for each process and a Dockerfile to containerize each of them.

2. Build each of the images corresponding to the `rng`, the `hasher`, `worker` and
`webui` services:
```
$ docker image build -t user/dockercoins_hasher:1.0 hasher
$ docker image build -t user/dockercoins_webui:1.0 webui
$ docker image build -t user/dockercoins_worker:1.0 worker
$ docker image build -t user/dockercoins_rng:1.0 rng
```

## Starting the App
1. Stand up the app:
```
$ docker-compose up
```
After a moment your app should be running; visit `<ip>:8000` to see the web frontend
visualizing your rate of Dockercoin mining.

2. Logs from all the runnings services are sent to STDOUT. Let's send this to the
background instead; kill the app with `CTRL+C`, sending a `SIGTERM` to all running
processes; some exit immediately, while others wait for a 10s timeout before being
killed by a subsequent `SIGKILL`. Start the app again in the background:
```
$ docker-compose up -d
```

3. Check out which containers are running thanks to Compose:
```
$ docker-compose ps
```

4. Compare this to the usual `docker container ls`; do you notice any differences?
If not, start a couple extra containers using `docker container run ...` and check
again.

## Viewing Logs

1. See logs from a Composed-managed app via:
```
$ docker-compose logs
```

2. The logging API in Compose follows the main Docker API closely. For example,
try following the tail of the logs just like you would for regular container logs:
```
$ docker-compose logs --tail=10 --follow
```

Note that when following a log, `CTRL+S` and `CTRL+Q` pauses and resumes live
following; `CTRL+C` exits follow mode as usual.

In this exercise you saw how to start a pre-defined Compose app, and how to inspect
its logs. Application logic was defined in each of the five images we used to
create containers for the app, but the manner in which those containers was created
was defined in the `docker-compose.yml` file; every aspect of how many containers
we want for each service, what networks to attach thos containers to and what other
parameters are desired, is captured in this manifest. Finally, the different elements
of Dockercoins communicated with each other via service name; the Docker daemon's
internal DNS was able to resolve traffic destined for a service, into the IP or
MAC address of the corresponding container.