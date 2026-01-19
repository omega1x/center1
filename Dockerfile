ARG PG_MAJOR=18

FROM postgres:${PG_MAJOR}.1-bookworm

ARG PG_MAJOR
ARG CRAN_URL=http://mirror.fcaglp.unlp.edu.ar/CRAN/
ARG PG_DB=center1

LABEL name="postgres${PG_MAJOR}-${PG_DB}" \
      description="PostgreSQL with PL/R for prototyping and in-situ analytics" \
      license="GPL-3.0-or-later" \
      author="Yuri Possokhov <omega1x@gmail.com>"


# Install utils, base R and its tools

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    wget \
    libopenblas0-pthread \
    littler \
    r-cran-docopt \
    r-cran-littler \
    r-base \
    r-base-dev \
    r-base-core \
    r-recommended \
    postgresql-${PG_MAJOR}-plr \
    && chown root:staff "/usr/local/lib/R/site-library" \
    && chmod g+ws "/usr/local/lib/R/site-library" \
    && ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
    && ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
    && ln -s /usr/lib/R/site-library/littler/examples/installBioc.r /usr/local/bin/installBioc.r \
    && ln -s /usr/lib/R/site-library/littler/examples/installDeps.r /usr/local/bin/installDeps.r \
    && ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
    && ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

ENV POSTGRES_PASSWORD=Zxc12 \
    POSTGRES_DB=${PG_DB} \
    R_HOME=/usr/lib/R \
    LD_LIBRARY_PATH=/usr/lib/R/lib:${LD_LIBRARY_PATH}

# Install the required CRAN-packages

RUN <<EOT
#!/usr/bin/env Rscript
  
  # Package installation:
  install.packages(
    c(
      "bit",
      "bit64",
      "brew",
      "checkmate",
      "CHNOSZ",
      "cpp11",
      "curl",
      "dbscan",
      "data.table",
      "DBI",
      "digest",
      "duckdb",
      "e1071",
      "EigenR",
      "flint",
      "fractaldim",
      "gld",
      "glue",
      "gsl",
      "httr2",
      "igraph",
      "ipaddress",
      "iapws",
      "IAPWS95",
      "jsonlite",
      "lightgbm",
      "lme4",
      "lubridate",
      "mlpack",
      "nloptr",
      "PolynomF",
      "purrr",
      "RcppTOML",
      "readxl",
      "rollama",
      "RPostgres",
      "rstan",
      "spls",
      "stringi",
      "suntools",
      "torch",
      "uuid",
      "xgboost",
      "xml2",
      "yaml"
    ), repos="http://mirror.fcaglp.unlp.edu.ar/CRAN/"
  )
  install.packages("pipenostics", repos="https://omega1x.r-universe.dev")
EOT

# Database initializers. 1. Simple extension creation

COPY <<-EOT /docker-entrypoint-initdb.d/01-init_plr.sql
    CREATE EXTENSION IF NOT EXISTS plr;  -- in center1

    \\c template1
    CREATE EXTENSION IF NOT EXISTS plr;  -- in all others
EOT

# Database initializers. 2. Schema and role-model configuration

COPY <<-EOT /docker-entrypoint-initdb.d/02-init_base.sh
#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username "\$POSTGRES_USER" --dbname "\$POSTGRES_DB" <<-EOSQL

    -- Creating read-only user
    CREATE USER reader WITH PASSWORD 'r2026';
    GRANT CONNECT ON DATABASE "\$POSTGRES_DB" TO reader;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO reader;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO reader;

    -- Creating user for external api
    CREATE USER api WITH PASSWORD 'a2026';
    GRANT CONNECT, TEMPORARY ON DATABASE "\$POSTGRES_DB" TO api;
    
    GRANT SELECT, INSERT, UPDATE, REFERENCES ON ALL TABLES IN SCHEMA public TO api;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, REFERENCES ON TABLES TO api; 

    GRANT TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA public TO api;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO api;
EOSQL
EOT

RUN chmod +x /docker-entrypoint-initdb.d/02-init_base.sh

