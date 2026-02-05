# Database Volumes

## Launching Postgres

1. Download a postgres image, and look at its history to determine its default
volume usage.

```
$ docker pull postgres:9
$ docker image inspect postgres:9
```

You should see a `Volume` block like the above, indicating that those paths in
the container filesystem will get volumes automatically mounted to them when a
container is started based on this image.

2. Set up a running instance of postgres container:
```
$ docker container run --name some-postgres \
    -v db_backing:/var/lib/postgresql/data \
    -e POSTGRES_PASSWORD=mysecretpassword \
    -d postgres:9
```

Notice the explicit mount, `-v db_backing:/var/lib/postgresql/data`; if we had'nt
done this, a randomly named volume would have been mounted to the container's
`/var/lib/postgresql/data`. Naming the volume explicitly is a best practice that
will become useful when we start mounting this volume in multiple containers.

## Writing on the database

1. The `psql` command line interface comes packaged with the postgres image; spawn
it as a child process in your postgres container interactively, to create a
postgres terminal:

```
$ docker container exec \
    -it some-postgres psql -U postgres
```

2. Create an arbitrary table in the database:

```
postgres=# CREATE TABLE CATICECREAM(COAT TEXT, ICECREAM TEXT);
postgres=# INSERT INTO CATICECREAM VALUES('calico', 'strawberry');
postgres=# INSERT INTO CATICECREAM VALUES('tabby', 'lemon');
```

Double check you created the table you expected, and then quit this container:
```
postgres=# SELECT * FROM CATICECREAM;
...
postgres=# \q
```

3. Delete the postgres container:

```
$ docker container rm -f some-postgres
```

4. Create a new postgres container, mounting the `db_backing` volume just like
last time:
```
$ docker container run \
    --name some-postgres \
    -v db_backing:/var/lib/postgresql/data \
    -d postgres:9
```

5. Reconnect a `psql` interface to your database, also like before:
```
$ docker container exec \
    -it some-postgres psql -U postgres
```

6. List the content of the `CATICECREAM` table:
```
postgres=# SELECT * FROM CATICECREAM
```

The contents of the database have survived the deletion and recreation of the
database container; this would not have been true if the database was keeping its
data in the writable container layer. As above, use `\q` to quit the postgres
prompt.

## Running Multiple Database Container

1. Create another postgres runtime, mounting the same backing volume:
```
$ docker container run \
    --name another-postgres \
    -v db_backing:/var/lib/postgresql/data \
    -d postgres:9
```

2. Create another postgres interactive prompt, pointing at this new postgres
container:
```
$ docker container exec \
    -it another-postgres psql -U postgres
```

Whenever data needs to live longer than the lifecycle of a container, it should
be pushed out to a volume outside the container's filesystem, numerous popular
databases are containerized using this pattern. In addition to making sure the
data survives container deletion, this pattern allows us to share data among
multiple containers, so multiple database instances can access the same
underlying data.