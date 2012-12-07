@echo off
call git pull
call git add -A source
call git commit -m "updating blog source" source
call git add -A sass
call git commit -m "updating blog source" sass
call git push -u origin master