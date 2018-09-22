@echo off
cd hugo
hugo
cd ..
git chackout master
git add -A
git commit -m "auto"
git subtree push --prefix hugo/public origin gh-pages