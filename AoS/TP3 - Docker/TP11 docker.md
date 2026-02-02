# Container Port Mapping

We will now learn to:
- forward traffic from a port on the docker host to a port inside a container's
network namespace
- define ports to automatically expose in a Dockerfile

## Port Mapping at runtime

1. Run an nginx container with no special port mapping:
```
$ docker container run -d nginx
```

nginx stands a landing page at `<ip>:80`, try to visit this at your host or
container's IP, and it won't be visible; no external traffic can make it past the
linux bridge's firewall to the nginx container.

2. Now run an nginx container and map port 80 on the container to port 5000 on your
host using the `-p` flag:
```
$ docker container run -d -p 5000:80 nginx
```

Note that the syntax is: `-p [host-port]:[container-port]`.

3. Verify the port mappings with the `docker container port` command
```
$ docker container port <container id>

80/tcp -> 0.0.0.0:5000
```

4. Visit your nginx landing page at `<host ip>:5000`, e.g. using
`curl -4 localhost:5000` or with your web browser, just to confirm it's working
as expected.

## Exposing Ports from the Dockerfile

1. In addition to manual port mapping, we can expose some ports in a Dockerfile
for automatic port mapping on container startup. In a fresh directory `~/port`,
create a Dockerfile:

```
FROM nginx

EXPOSE 80
```

2. Build your image as `my_nginx`:
```
$ docker image build -t my_nginx .
```

3. Use the `-P` flag when running to map all ports mentionned in the `EXPOSE`
directive:
```
$ docker container run -d -P my_nginx
```

4. Use `docker container ls` or `docker container port` to find out what host
ports were used, and visit your nginx landing page at the appropriate ip/port.

5. Clean up your containers:
```
$ docker container rm -f $(docker container ls -qa)
```

In this exercise, we saw how to explicitly map ports from our container's network
stack onto ports of our host at runtime with the `-p` option to `docker container run`,
or more flexibly in our Dockerfile with `EXPOSE`, wich will result in the listed
ports inside our container being mapped to random available ports on our host. In
both cases, Docker is writing iptables rules to forward traffic from the host to the
appropriate port in the container's network anmespace.