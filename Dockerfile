ARG POSTGRES_BASE_IMAGE=postgres:18-bookworm
FROM ${POSTGRES_BASE_IMAGE}

COPY docker/init/ /docker-entrypoint-initdb.d/
COPY sql/ /course/sql/
COPY scripts/ /course/scripts/
COPY legacy/ /course/legacy/
