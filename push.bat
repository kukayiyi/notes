@echo off
echo Begining add changes.
git add ./*
echo add successful

echo;
echo Begining commit changes to local repository.
git commit -m "my note"
echo commit successful

echo;
echo Begining push changes to the server
git push note master
echo push successful

echo;
echo All commands have been executed
echo;

pause