# Introduction to Container Networking

We will now learn how to:
- Create docker bridge networks and attach containers to them
- Design networks of containers that can successfully resolve each other via
DNS and reach each other accros Docker software defined network.

## Inspecting the Default Bridge

1. See what networks are present on your host:
```
$ docker network ls
```

You should have entries for `host`, `none` and `bridge`.

2. Find some metadata about the default bridge network:
```
$ docker network inspect bridge
```

Note especially the private subnet assigned by Docker's driver to this network.
The first IP in this range is used as the network's gatewauy, and the rest will
be assigned to containers as they join the network.

3. See similar info from common networking tools (this will probably work only
for those on Linux):
```
$ ip addr
```
Note the `bridge` network's gateway corresponds to the IP of `docker0` in this list.
`docker0` is the linux bridge itself, while `bridge` is the name of the default
Docker network that uses that bridge.

4. Use `brctl` to see connections to the `docker0` bridge:
```
$ brctl show docker0
```

At the moment, there are no connections to `docker0`.

## Connecting Containers to `docker0`

1. Start a container and reexamine the network; the container is listed as
connected to the network, wirh an IP address assigned to it from the bridge
network's subnet:
```
$ docker container run --name u1 -dt centos:7
$ docker network inspect bridge
```

2. Inspect the network interfaces with the `ip` and `brctl` again, now that you
have a container running:
```
$ ip addr
$ brctl show docker0
```

`ip addr` indicates a veth endpoint has been created and plugged into the
`docker0` bridge, as indicated by `master docker0`, and that it is connected to
device index 4 in this case (indicated by the `@if4` suffix to the veth device
name above). Similarly, `brctl` now shows this veth connection on `docker0` (notice
that the ID for the veth connection matches in both utilities).

3. Launch a bash shell in your container, and look for the `eth0` device therein:
```
$ docker container exec -it u1 bash
rot@11da9b7db065 /]# yum install -y iproute
rot@11da9b7db065 /]# ip addr
...
```
We see that the `eth0` device in this namespace is in fact the device that the veth
connection in the host namespace indicated it was attached to, and vice versa -
`eth0@if5` indicates it is plugged into networking interface number 5, which we
saw above was the other end of the veth connction. Docker has created a veth
connection with one end in the host's `docker0` bridge, and the other providing
the `eth0` device in the container.

## Defining Additional Bridge Networks

In the last stap we investigated the default bridge network, let's try making our
own. User defined bridge networks work exactly the same as the default one, but
provide DNS lookup by container name, and are firewalled from other networks by
default.

1. Create a bridge network by using the bridge driver with `docker network create`:
```
$ docker network create --driver bridge my_bridge
```

2. Launch a container connected to your new network via the `--network` flag:
```
$ docker container run --name=u2 --network=my_bridge -dt centos:7
```

3. Use the `inspect` command to investigate the network settings of this container:
```
$ docker container inspect u2
```

`my_bridge` should be listed under the `Networks` key.

4. Launch another container, this time interactively:
```
$ docker container run --name=u3 --network=my_bridge -it centos:7
```

5. From inside container `u3`, ping `u2` by name: `ping u2`. The ping succeeds,
since Docker is able to resolve container names when they are attached to a custom
network.

6. Try starting a container on the default network, and pinging `u1` by nameL
```
$ docker container run centos:7 ping u1

ping: u1: Name or service not known
```
The ping fails; even though the containers are both attached to the `bridge` network,
Docker does not provide name lookup on this default network. Try the same command
again, but using `u1`'s IP address instead of name, and you should be successful.

7. Finally, try pinging `u1` by IP, this time from container `u2`:
```
$ docker container exec u2 ping <u1 IP>
```

The ping fails, since the containers reside on different networks, all Docker
networks are firewalled from each other by default.

8. Clean up your containers and networks:
```
$ docker container rm -f $(docker container ls -qa)
$ docker network rm my_bridge
```

In this exercise, you explored the fundamentals of container networking. The
key takewaway is that *containers on separate networks are firewalled from each
other by default*. This should be leveraged as much as possible to harden your
application; if two containers don't need to talk to each other, put them on a
separate networks.

You also explored a number of API objects:
- `docker network ls` list all networks on the host
- `docker network inspect <network name>` gives more detailed info about the named
network
- `docker network create --driver <driver> <network name>` creates a new network
using the specified driver; so far, we've only seen the `bridge` driver, for
creating a linux bridge based network.
- `docker network connect <network name> <container name or id>` connects the
specified container to the specified network after the container is running; the
`--network` flag in `docker container run` achieves the same result at container
launch.
- `docker container inspect <container name or id>` yields among other things,
information about the networks the specified container is connected to.
