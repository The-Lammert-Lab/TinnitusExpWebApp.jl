#!/bin/bash
# just run "source load_env.sh" to have all environment added to current shell!
# load_env.sh -- thanks stack overflow:)
if [ -f .env ]; then
  set -a  # Automatically export all variables
  source .env
  set +a
else
  echo "No .env file found."
fi