#!/bin/bash

# Check if Node.js and NPM are installed
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "Node.js and NPM are required but not installed. Please install them first."
    exit 1
fi

# Install or update sql-formatter
npm install -g sql-formatter
