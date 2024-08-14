#!/bin/bash

# === LOGS ===
# Exit immediately if a command exits with a non-zero status.
set -e
# Create logs directory if it doesn't exist
mkdir -p logs
current_date=$(date +"%Y-%m-%d_%H-%M-%S")
log_file="logs/startup_logs_$current_date.log"
# Redirect all output to the log file
exec > >(tee -a "$log_file") 2>&1
echo "Starting setup script at $(date)"

# === Poetry ===
# Set poetry to create virtual environments within the project directory (coz by default it creates in ~/.cache)
poetry config virtualenvs.in-project true
# Use the current python interpreter for the virtual environment
poetry env use $(which python)
# Install the project dependencies except the project itself
poetry install --no-root

# === Install dev dependencies ===
make dev_env

# === Frontend ===
clear
read -p "Install yarn (only needed if doing frontend dev)? (y/n): " user_input
if [ "$user_input" == "y" ]; then
    cd ./mage_ai/frontend/
    echo "Installing yarn..."
    yarn install
    cd ../..
else
    echo "Skipping yarn installation."
fi

# === Hooks ===
clear
read -p "Install github hooks? (y/n): " user_input
if [ "$user_input" == "y" ]; then
    echo "Installing hooks..."
    make install-hooks
    source .venv/bin/activate
    pre-commit install
else
    echo "Skipping hooks."
fi
# === Initialise if default_repo exists ===
# TODO: Change so user can choose the name. (Append the folder name to the end of .gitignore if user specifies a different name & cache the name)
if [ ! -d "default_repo" ]; then
    echo "'default_repo' directory does not exist. Running initialization script."
    ./scripts/init.sh default_repo
else
    echo "'default_repo' directory exists. Skipping initialization."
fi
clear

echo "Setup script completed at $(date) & logs stored at ./logs/startup_logs_$current_date.log"

read -p "Start the development environment now? (y/n): " user_input
if [ "$user_input" == "y" ]; then
    echo "Starting the development environment..."
    ./scripts/dev.sh default_repo
else
    echo "Exiting terminal."
    exit 0
fi
# Keep the shell open after the script completes (for debugging)
exec bash