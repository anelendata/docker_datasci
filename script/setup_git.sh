#!/bin/bash

git config --global user.name $1
git config --global user.name
git config --global user.email $2
git config --global user.email
git config --global credential.helper cache

echo "git is set. Use git clone https://... to fetch the repo"
