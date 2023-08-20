#!/bin/bash
export USER=$(id -u)
export GROUP=$(id -g)
docker compose -f _docker/docker-compose.yml up -d $1 && docker attach docker-cumbuca-1