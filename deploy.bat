@echo off
cd hugo
hugo
cd ..
git checkout master
git add -A
git commit -m "auto"
git subtree push --prefix hugo/public origin gh-pages