# Running & Inspecting Containers
By the end of this exercise, you should be able to:
- Start a container
- List running and stopped containers

## Running Containers 
1. First, let’s start a container, and observe the output:

```
$ docker container run centos:7 echo "hello world"
Unable to find image 'centos:7' locally
7: Pulling from library/centos
256b176beaff: Pull complete
Digest: sha256:6f6d986d425aeabdc3a02cb61c02abb2e78e57357e92417d6d58332856024faf
Status: Downloaded newer image for centos:7
hello world
```

The centos:7 part of the command indicates the image we want to use to define 
this container; it defines a private filesystem for the container. 
`echo "hello world"` is the process we want to execute inside the kernel 
namespaces created when we use docker container run.
Since we’ve never used the `centos:7` image before,  first Docker downloads it, 
and then runs our `echo "hello world"` process inside a contianer, sending the 
`STDOUT` stream of that process to our terminal by default.

2. Now create another container from the same image, and run a different process 
inside of it

```
$ docker container run centos:7 ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 14:28 ?        00:00:00 ps -ef
```

No download this time, and we can see that our containerized process 
(`ps -ef` in this case) is PID 1 inside the container.

3. Try doing ps -ef at the host prompt and see what process is PID 1 here.

## Listing Containers

1. Try listing all your currently running containers:

```
[centos@node-0 ~]$ docker container ls
```

There’s nothing listed, since the containers you ran executed a single command, 
and shut down when finished.

2. List stopped as well as running containers with the `-a` flag:

```
$ docker container ls -a

CONTAINER ID  IMAGE     COMMAND                 CREATED             STATUS
a525daef85ab  centos:7  "ps -ef"                About a minute ago  Exited (0) About a minute ago
db6aabba5157  centos:7  "echo 'hello world'"    3 minutes ago       Exited (0) 3 minutes ago
```

We can see our exited containers this time, with a time and exit code in the STATUS column

**Where did those names come from?** We truncated the above output table, but in yours 
you should also see a NAMES column with some funny names. All containers have 
names, which in most Docker CLI commands can be substituted for the container ID 
as we’ll see in later exercises. By default, containers get a randomly generated 
name of the form `<adjective>_<scientist / technologist>`, but you can choose a 
name explicitly with the `--name`  flag in docker container run.

3. Clean up all containers using this command:

```
$ docker container rm -f $(docker container ls -aq)
```