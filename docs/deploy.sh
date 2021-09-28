#!/bin/bash

jekyll build -d docs
git add .
git commit -m "update"
git push origin jekyll