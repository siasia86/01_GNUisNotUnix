#!/bin/bas


bash script
---------------------------
echo "# gnuisnotunix" >> README.md

git init

git add README.md

git commit -m "first commit"

git branch -M main

git remote add origin git@github.com:siasia86/01_GNUisNotUnix.git

git push -u origin main

---------------------------


---------------------------

mkdir test01

cd test01

git init

git clone git@github.com:siasia86/01_GNUisNotUnix.git

---------------------------
