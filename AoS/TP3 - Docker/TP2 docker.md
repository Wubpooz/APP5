# Interactive Containers

## Writing to Containers

1. Create a container using the centos:7 image, and connect to its bash shell
in interactive mode using the `-i` flag (also the `-t`  flag, to request a
TTY connection):

```
$ docker container run -it centos:7 bash
```

2. Explore your container’s filesystem with ls, and then create a new  le:

```
[root@2b8de2ffdf85 /]# ls -l
[root@2b8de2ffdf85 /]# echo 'Hello there...' > test.txt
[root@2b8de2ffdf85 /]# ls -l
```

3. Exit the connection to the container
```
[root@2b8de2ffdf85 /]# exit
```

4. Try finding the file you created on your computer. Is it there ?

5. Run the same command as above to start a container in the same way:
```
$ docker container run -it centos:7 bash
```
Try  finding your `test.txt`  file inside this new container; it is nowhere to
be found. Exit this container for now in the same way you did above.


## Reconnecting to Containers

1. We’d like to recover the information written to our container in the  first
example, but starting a new container didn’t get us there; instead,
we need to restart our original container, and reconnect to it.
List all your stopped containers:

```
$ docker container ls -a
CONTAINER ID  IMAGE     COMMAND  CREATED                STATUS                         ...
cc19f7e9aa91  centos:7  "bash"   About a minute ago     Exited (0) About a minute ago  ...
2b8de2ffdf85  centos:7  "bash"   2 minutes ago          Exited (0) About a minute ago  ...
...
```

2. We can restart a container via the container `ID` listed in the  first column.
Use the container ID for the  first `centos:7` container you created with bash as its command
(see the CREATED column above to make sure you’re choosing the first bash container you ran):

```
$ docker container start <container ID>
$ docker container ls

CONTAINER ID  IMAGE     COMMAND  CREATED         STATUS         ...
2b8de2ffdf85  centos:7  "bash"   5 minutes ago   Up 21 seconds  ...
```

Your container status has changed from `Exited` to `Up`, via `docker container start`.

3. Run `ps -ef` inside the container you just restarted using Docker’s `exec` command
(`exec` runs the specified process as a child of the PID 1 process inside the container):

```
$ docker container exec <container ID> ps -ef
```

What process is PID 1 inside the container? Find the PID of that process on the
host machine by using:

```
$ docker container top <container ID>
```

4. Launch a bash shell in your running container with `docker container exec`:

```
$ docker container exec -it <container ID> bash
```

5. List the contents of the container’s filesystem again with `ls -l`; your
`test.txt` should be where you left it.

Exit the container again by typing `exit`.

## Using Container Listing Options

1. In the last step, we saw how to get the short container ID of all our
containers using docker container `ls -a`. Try adding the `--no-trunc`  flag to
see the entire container ID:
```
$ docker container ls -a --no-trunc
```

2. This long ID is the same as the string that is returned after starting a
container with docker container run. List only the container ID using the `-q` flag:

```
$ docker container ls -a -q
```

3. List the last container to have been created using the `-l` flag:

```
$ docker container ls -l
```

4. Finally, you can also filter results with the `--filter` flag; for example,
try filtering by exit code:
```
$ docker container ls -a --filter "exited=0"
```
The output of this command will list the containers that have exited successfully.

5. Clean up with:
```
$ docker container rm -f $(docker container ls -aq)
```