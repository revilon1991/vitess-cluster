#!/bin/bash
set -e

# Execute the CMD from Dockerfile as PID 1
exec "$@"
