#!/bin/bash
cd zola
zola build --output-dir ../docs
cd ..
git add -A
git commit -m "update"
git push origin master
