#!/bin/bash
git pull
git add -A source
git commit -a -m "updating blog source"
git push -u origin master
rake generate && rake deploy
