#!/bin/bash

echo "#################################"
echo "#### Update bower ###############"
echo "#################################"

# Enable tracing and exit on first failure
set -xe
# Normalize working dir to script dir
cd `dirname $0`

SCRIPT_DIR=`pwd`

# export so that node.js can read those env settings
export TMP_DIR=../../tmp
export BUILD_DIR=../../build

NEW_VERSION=`cat $BUILD_DIR/version.txt`

REPOS=(
  angular           \
  angular-animate   \
  angular-cookies   \
  angular-i18n      \
  angular-loader    \
  angular-mocks     \
  angular-route     \
  angular-resource  \
  angular-sanitize  \
  angular-scenario  \
  angular-touch     \
)

#
# clone repos
#
for repo in "${REPOS[@]}"
do
  echo "-- Cloning bower-$repo"
  git clone git@github.com:angular/bower-$repo.git $TMP_DIR/bower-$repo
done


#
# move the files from the build
#

for repo in "${REPOS[@]}"
do
  if [ -f $BUILD_DIR/$repo.js ] # ignore i18l
    then
      echo "-- Updating files in bower-$repo"
      cd $TMP_DIR/bower-$repo
      git reset --hard HEAD
      git checkout master
      git fetch --all
      git reset --hard origin/master
      cd $SCRIPT_DIR
      cp $BUILD_DIR/$repo.* $TMP_DIR/bower-$repo/
  fi
done

# move i18n files
cp $BUILD_DIR/i18n/*.js $TMP_DIR/bower-angular-i18n/

# move csp.css
cp $BUILD_DIR/angular-csp.css $TMP_DIR/bower-angular


#
# get the old version number
#

OLD_VERSION=$(node -e "console.log(require(process.env.TMP_DIR+'/bower-angular/bower').version)" | sed -e 's/\r//g')
echo $OLD_VERSION
echo $NEW_VERSION

#
# update bower.json
# tag each repo
#

for repo in "${REPOS[@]}"
do
  echo "-- Updating version in bower-$repo from $OLD_VERSION to $NEW_VERSION"
  cd $TMP_DIR/bower-$repo
  sed -i '' -e "s/$OLD_VERSION/$NEW_VERSION/g" bower.json
  git add -A

  echo "-- Committing, tagging and pushing bower-$repo"
  git commit -m "v$NEW_VERSION"
  git tag v$NEW_VERSION
  git push origin master
  git push origin v$NEW_VERSION
  cd $SCRIPT_DIR
done
