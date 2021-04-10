#!/bin/bash
cd blog
hugo
cd ..
git add .
git commit -m "Update"
git push origin master
