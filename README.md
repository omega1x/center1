# center1

> `center1` is a project for combining the analytical power of
> [PostgreSQL](https://www.postgresql.org/) and
> [R-project](https://www.r-project.org/) worlds in a single optimized
> [Docker](https://hub.docker.com/)-container for further prototyping and
> in-situ analytics.

Key features:

- [PostgreSQL 18.1](https://www.postgresql.org/docs/release/18.1/)
- [R 4.2.2](https://cloud.r-project.org/src/base/R-4/) over
  [PL/R](https://github.com/postgres-plr/plr/blob/master/userguide.md)
- opinionated set of *R*-packages including but not limited to:
  - amazing [data.table](https://rdatatable.gitlab.io/data.table/)
  - brilliant [igraph](https://r.igraph.org/)
  - trending [duckdb](https://duckdb.org/)
  - author's [pipenostics](https://omega1x.github.io/pipenostics/) for
    domain-specific usage
  - and many other packages that have proven to be effective author's
    domain-specific analytic routines.

## Usage

### Compose *PostgreSQL* configuration

> &#128712; The next instuctions are appropriate inside the project directorу

Select and edit the proper configuration file from `conf`-directory or create
your own:

```bash
MY_CONF="default"  # do not specify subdirectory and extension
```

Then substitue `postgresql.conf` with the selected one:

```bash
sudo rm -f "$(pwd)/postgresql.conf"
cat "$(pwd)/conf/$MY_CONF.conf" > "$(pwd)/postgresql.conf"
```

Provide readable/writable access:

```bash
sudo chown 999:999 "$(pwd)/postgresql.conf"
```

### Locate data storage

Create an empty `pgdata`-directory for storing database data in appropriate
path:

```bash
POSTGRES_STORAGE="$(pwd)/pgdata"
sudo rm -rf "$POSTGRES_STORAGE"
mkdir "$POSTGRES_STORAGE"
```

Provide readable/writable access:

```bash
sudo chown -R 999:999 "$POSTGRES_STORAGE"
```

### Docker run

Run the fresh container:

```bash
docker run -d \
  --name center1-"$MY_CONF"-01 \
  -p 5432:5432 \
  -v "$POSTGRES_STORAGE:/var/lib/postgresql/18/docker" \
  -v "$(pwd)/postgresql.conf:/etc/postgresql/postgresql.conf" \
  docker.io/omega1x/center1:v0.01 \
  -c 'config_file=/etc/postgresql/postgresql.conf'
```

### Check connection

Check basic accessability:

```bash
PGPASSWORD="a2026" \
psql \
  --host=127.0.0.1 \
  --username=api \
  --dbname=center1 \
  -P pager=off \
  --command="SELECT true AS connection;"
```

Check
[PL/R](https://github.com/postgres-plr/plr/blob/master/userguide.md#inline-handler-)
functionality:

```bash
PGPASSWORD="a2026" \
psql \
  --host=127.0.0.1 \
  --username=api \
  --dbname=center1 \
  -P pager=off \
  --command="SELECT plr_version();"
```

> &#9888; Use your value for the
> [host](https://www.postgresql.org/docs/current/app-psql.html#APP-PSQL-OPTION-FIELD-HOST)
> parameter.

## Build image

Use the trivial way to build the image:

```bash
docker image build --tag=docker.io/omega1x/center1:v0.01 $(pwd)
```
