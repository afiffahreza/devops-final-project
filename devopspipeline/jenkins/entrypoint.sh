#!/bin/bash

# Adjust permissions for Docker socket
if [ -e /var/run/docker.sock ]; then
    chown jenkins:docker /var/run/docker.sock
fi

# Execute the provided command or fall back to the default CMD
exec "$@"