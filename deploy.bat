@echo off
cd hugo
hugo
cd ..
git subtree push --prefix hugo/public origin gh-pages