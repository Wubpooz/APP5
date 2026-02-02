# Scaling a Compose App

In this exercise we will learn to scale a service from Docker Compose up or down.

## Scaling a service

Any service defined in our `docker-compose.yml` can be scaled up from the
Compose API; in this context, 'scaling' means launching multiple containers for the
same service, which Docker Compose can route requests to and from.

1. Scale up the `worker` service in our Dockercoins app to have two workers
generating coin candidates, while checking the list of running containers before
and after:
```
$ docker-compose ps
$ docker-compose scale worker=2
$ docker-compose ps
```

A new worker container has appeared in your list of containers.

2. Look at the performance graph provided by the web frontend; the coin mining rate
should have doubled. Also check the logs using the logging API we learned in the last
exercise; you should see a second `worker` instance reporting.


## Investigating Bottlenecks

1. Try running `top` to inspect the system resource usage; it shoul be fairly negligible.
So, keep scaling up your workers:
```
$ docker-compose scale worker=10
$ docker-compose ps
```

2. Check your web frontend again; has going from 2 to 10 workers provided a 5x
performance increase? It seems that something else is bottlenecking our application;
any distributed application such as Dockercoins needs tooling to understand where
the bottlenecks are, so the application can be scaled intelligently.

3. Look in `docker-compose.yml` at the `rng` and `hasher` service; they're exposed
on host ports 8001 and 8002, so we can use `httping` to probe their latency.
```
$ httping -c localhost:8001
$ httping -c localhost:8002
```

`rng` on port 8001 has the much higher latency, suggesting that it might be our bottleneck.
A random number generator based on entropy won't get any better by starting more
instances on the same machine; we'll need a way to bring more nodes into our
application to scale past this, which we'll explore next.

4. For now, shut your app down:
```
$ docker-compose down
```

In this exercise, we saw how to scale up a service defined in our Compose app using
the `scale` API object. Also, we saw the need to identify bottlenecks to understand
performance of a multi-container application.