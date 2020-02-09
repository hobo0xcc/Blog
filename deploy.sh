#!/bin/bash
cd blog
hugo -D
cd ..
git add .
git commit -m "Update"
git push origin master
