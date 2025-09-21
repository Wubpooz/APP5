#!/bin/bash
set -e

# Go to /usr/local
cd /usr/local

# Download the latest Prince generic tarball (v16.1 here)
sudo wget https://www.princexml.com/download/prince-16.1-linux-generic-x86_64.tar.gz

# Extract it
sudo tar -xzf prince-16.1-linux-generic-x86_64.tar.gz

# Enter directory
cd prince-16.1-linux-generic-x86_64

# Run installer
sudo ./install.sh

# Verify install
prince --version
