#!/bin/bash
docker build -f _docker/Dockerfile -t andridus/challenge-cumb:v$1 . && docker --config ~/_andridus push andridus/challenge-cumb:v$1
