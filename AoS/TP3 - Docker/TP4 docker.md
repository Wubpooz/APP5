# Starting, Stopping, Inspecting and Deleting Containers

## Starting and Restarting Containers

1. Start by running a container in the background, and check that it’s really running:

```
$ docker container run -d centos:7 ping 8.8.8.8
$ docker container ls
```

2. Stop the container using docker container stop, and check that the container
is indeed stopped:

```
$ docker container stop <container ID>
$ docker container ls -a
```

Note that the stop command takes a few seconds to complete. `docker container stop`
first sends a `SIGTERM` to the PID 1 process inside a container, asking it to shut
down nicely; it then waits 10 seconds before sending a `SIGKILL` to kill it off,
ready or not. The exit code you see (137 in this case) is the exit code returned
by the PID 1 process (ping) upon being killed by one of these signals.

3. Start the container again with `docker container start`, and attach to it at
the same time with the `-a` flag:

```
$ docker container start -a <container ID>
```

As you saw previously, this brings the container from the `Exited` to the `Up`
state; in this case, we’re also attaching to the PID 1 process.

4. Detach and stop the container with `CTRL+C`, then restart the container
without attaching and follow the logs starting from 10 lines previous.

5. Finally, stop the container with `docker container kill`:

```
$ docker container kill <container ID>
```

Unlike `docker container stop`, `container kill` just sends the `SIGKILL` right away - no grace period.

## Inspecting a Container

1. Start your ping container again, then inspect the container details using
`docker container inspect`:

```
$ docker container start <container ID>
$ docker container inspect <container ID>
```

You get a big blob of JSON describing the container’s config, metadata and state.

2. Find the container’s IP and long ID in the JSON output of `inspect`.
If you know the key name of the property you’re looking for, try piping to `grep`:

```
$ docker container inspect <container ID> | grep IPAddress
```

The output should look similar to this:

```
"SecondaryIPAddresses": null,
"IPAddress": "<Your IP Address>"
```

3. Now try grepping for `Cmd`, the PID 1 command being run by this container.
`grep`’s simple text search doesn’t always return helpful results:

```
$ docker container inspect <container ID> | grep Cmd
[
```

4. Another way to filter this JSON is with the `--format` flag. Syntax follows
Go’s text/template package: http://golang.org/pkg/text/template/.
For example, to find the `Cmd` value we tried to `grep` for above, instead try:

```
$ docker container inspect --format='{{.Config.Cmd}}' <container ID>
```

This time, we get a the value of the `Config.Cmd` key from the inspect JSON.

5. Keys nested in the JSON returned by docker container inspect can be chained
together in this fashion.
Try modifying this example to return the IP address you grepped for previously.

6. Finally, we can extract all the key/value pairs for a given object using the
json function:

```
$ docker container inspect --format='{{json .Config}}' <container ID>
```

Try adding `| jq` to this command to get the same output a little bit easier to read.

## Deleting Containers

1. Start three containers in background mode, then stop the first one.

2. List only exited containers using the `--filter` flag we learned earlier, and
the option `status=exited`.

3. Delete the container you stopped above with `docker container rm`, and do the
same listing operation as above to confirm that it has been removed:

```
$ docker container rm <container ID>
$ docker container ls ...
```

4. Now do the same to one of the containers that’s still running; notice
`docker container rm` won’t delete a container that’s still running, unless we
pass it the force flag `-f`. Delete the second container you started above:

```
$ docker container rm -f <container ID>
```

5. Try using the `docker container ls` flags we learned previously to remove
the last container that was run, or all stopped containers. Recall that you can
pass the output of one shell command `cmd-A` into a variable of another command
`cmd-B` with syntax like `cmd-B $(cmd-A)`.

6. When done, clean up any containers you may still have:
```
$ docker container rm -f $(docker container ls -aq)
```

In this exercise, you explored the lifecycle of a container, particularly in
terms of stopping and restarting containers. Keep in mind the behavior of
`docker container stop`, which sends a `SIGTERM`, waits a grace period, and
then sends a `SIGKILL` before forcing a container to stop; this two step process
is designed to give your containers a chance to shut down ‘nicely’: dump their
state to a log, finish a database transaction, or do whatever your application
needs them to do in order to exit without causing additional problems. Make sure
you bear this in mind when designing containerized software.
Also keep in mind the `docker container inspect` command we saw, for examining
container metadata, state and con g; this is often the first place to look when
trying to troubleshoot a failed container.