# Multi-Stage Build

In this exercise, we will learn to write a Dockerfile that describes multiple
images and that can copy files from one image to the next.

## Defining a multi-stage build

1. Make a fresh folder `~/multi` to do this exercise in, and `cd` into it.

2. Add a file `hello.c` to the `multi` folder containing **Hello World** in C:

```
#include "stdio.h"

int main (void) {
    printf("Hello, world!\n");
    return 0;
}
```

3. If you have a compiler installed on your computer, try compiling and running
this application:
```
$ gcc -Wall hello.c -o hello
$ ./hello
Hello, world!
```

4. Now let's Dockerize our hello world application. Add a `Dockerfile` to the
`multi` folder with this content:

```
FROM alpine:3.5
RUN apk update && \
    apk add --update alpine-sdk
RUN mkdir /app
WORKDIR /app
COPY hello.c /app
RUN mkdir bin
RUN gcc -Wall hello.c -o bin/hello
CMD /app/bin/hello
```

5. Build the image and observe its size:
```
$ docker image build -t my-app-large .
$ docker image ls | grep my-app-large
```

6. Test the image to confirm it actually works:
```
$ docker container run my-app-large
```
It should print "hello world" in the console.

7. Update your Dockerfile to use an `AS` clause on the first line, and add a
second stanza describing a second build stage:

```
FROM alpine:3.5 AS build
RUN apk update && \
    apk add --update alpine-sdk
RUN mkdir /app
WORKDIR /app
COPY hello.c /app
RUN mkdir bin
RUN gcc -Wall hello.c -o bin/hello

FROM alpine:3.5
COPY --from=build /app/bin/hello /app/hello
CMD /app/hello
```

8. Build the image again and compare the size with the previous version:
```
$ docker image build -t my-app-small
$ docker image ls | grep 'my-app-'
```

What do you notice?

As expected the size of the multi-stage build is much smaller than the large one
since it does not contain the Alpine SDK.

9. Finally, make sure the app actually works:
```
$ docker container run --rm my-app-small
```

## Building Intermediate Images

In the previous step, we took our compiled executable from the first build stage,
but that image wasn't tagged as a regular image we can use to start container with,
only the final `FROM` statement generated a tagged image. In this step, we'll see
how to persist whichever build stage we like.

1. Build an image from the `build` stage in your Dockerfile using the `--target`
flag:
```
$ docker image build -t my-build-stage --target build .
```

Notice all its layers are pulled from the cache; even though the build stage wasn't
tagged originally, its layer are nevertheless persisted in the cache.

2. Run a container from this image and make sure it yields the expected result:
```
$ docker container run -it --rm my-build-stage /app/bin/hello
```

3. List your images again to see the size of `my-build-stage`compared to the small
version of the app.


In this exercise, we created a Dockerfile defining multiple build stages. Being
able to take artifacts like compiled binaries from one image and insert them into
another allows you to create very lightweight images that do not include developer
tools or other unenecessary components in your production-ready images, just like
how you probably have separate build and run environments for your software. This
will resul in containers that start faster, and are less vulnerable to attack.