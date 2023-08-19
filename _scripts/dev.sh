#!/bin/bash
docker compose -f _docker/docker-compose.yml up -d $1 && docker attach docker-cumbuca-1