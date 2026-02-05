# Creating Images with Dockefiles

## Writing and Building a Dockerfile

1. Create a folder called `myimage`, and a text file called `Dockerfile` within
that folder. In `Dockerfile`, include the following instructions:

```
FROM centos:7
RUN yum update -y
RUN yum install -y wget
```

This serves as a recipe for an image based on `centos:7`, that has all its
default packages updated and wget installed on top.

2. Build your image with the build command:
```
$ docker image build -t myimage .
```

You’ll see a long build output - we’ll go through the meaning of this output in a
demo later. For now, everything is good if it ends with `Successfully tagged myimage:latest`.

3. Verify that your new image exists with docker image ls, then use it to run a
container and wget something from within that container.

4. It’s also possible to pipe in a Dockerfile from STDIN; try rebuilding your
image with the following:

```
$ cat Dockerfile | docker image build -t myimage -f - .
```

(This is useful when reading a Dockerfile from a remote location with `curl`, for example).

## Using the Build Cache

In the previous step, the second time you built your image should have completed
immediately, with each step save the first reporting `using cache`. Cached build
steps will be used until a change in the Dockerfile is found by the builder.

- Open your Dockefile and add another `RUN` step at the end to install `vim`
- Build the image again as above; which steps is the cache used for?
- Build the image again; which steps use the cache this time?
- Swap the order of the two `RUN` commands for installing `wget` and `vim` in
the Dockerfile, and build one last time. Which steps are cached this time?

## Using the `history` Command

1. The `docker image history` command allows us to inspect the build cache
history of an image. Try it with your new image:

```
$ docker image history myimage:latest
```

Note the image id of the layer built for the `yum update` command.

2. Replace the two `RUN` commands that installed `wget` and `vim` with a single
command:

```
...
RUN yum install -y wget vim
```

3. Build the image again, and run `docker image history` on this new image. How
has the history changed?

In this exercise, we’ve seen how to write a basic Dockerfile using `FROM` and `RUN`
commands, some basics of how image caching works, and seen the `docker image history`
command. Using the build cache e ectively is crucial for images that involve
lengthy compile or download steps; in general, moving commands that change
frequently as late as possible in the Dockerfile will minimize build times.
We’ll see some more speci c advice on this later in this lesson.