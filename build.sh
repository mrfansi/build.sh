#!/bin/bash

# default run package manager
prun="$(which npm) run"

# default run composer manager
crun="$(which composer)"

# npm legacy version
npm_legacy_version="6.14.4"

func_remove_log() {
  # remove build-run.log
  if [ -f "./build-run.log" ]; then
    rm -rf "./build-run.log"
  fi

  # remove build.log
  if [ -f "./build.log" ]; then
    rm -rf "./build.log"
  fi
}

func_remove_log


if [ -f "./ecosystem.config.js" ]; then
  echo "[*] Stop server PM2 first" >> "./build-run.log"
  pm2 stop "./ecosystem.config.js" &>/dev/null
fi

func_npm() {
  # check if npm command exist
  if hash npm 2>/dev/null; then

    # npm current version
    npm_version="$(npm -v)"

    echo "[*] Detected NPM version: $npm_version" >> "./build-run.log"
  else
    echo "[*] NPM not found. exit" >> "./build-run.log"
    exit
  fi
}

func_yarn() {
  # check if yarn command exist
  if hash yarn 2>/dev/null; then

    # yarn current version
    yarn_version="$(yarn -v)"

    echo "[*] Detected Yarn version: $yarn_version" >> "./build-run.log"
  else
    echo "[*] Yarn not found. Please install first" >> "./build-run.log"
    exit
  fi
}

func_php() {
  # print php version
  if hash php 2>/dev/null; then

    # php current version
    php_version=$(php -v | grep ^PHP | cut -d' ' -f2)

    echo "[*] Detected php version: $php_version" >> "./build-run.log"
  else
    echo "[*] PHP not found. Please install first" >> "./build-run.log"
    exit
  fi
}

func_composer() {
  if hash composer 2>/dev/null; then

    # composer current version
    composer_version=$(composer -V | grep ^Composer | cut -d' ' -f3)

    echo "[*] Detected composer version: $composer_version" >> "./build-run.log"
  else
    echo "[*] Composer not found. Please install first" >> "./build-run.log"
    exit
  fi
}

func_pm2() {
  if hash pm2 2>/dev/null; then

    # pm2 current version
    pm2_version=$(pm2 -v)

    echo "[*] Detected pm2 version: $pm2_version" >> "./build-run.log"
  else
    echo "[*] PM2 not found. Please install first" >> "./build-run.log"
    exit
  fi
}

func_build_log() {
  now="$(date +'%Y-%m-%d %H:%M')"
  count=$(awk 'END { print NR }' ./build.log)

  echo "[*] Build #$(($count+1)) at $now" >> "./build-run.log"
}

if [ -f "./package.json" ]; then
  echo "[*] Package.json detected" >> "./build-run.log"

  if [ -d "./node_modules" ]; then
    echo "[*] Remove node_modules" >> "./build-run.log"
    rm -rf "./node_modules"
  fi

  if [ -f "./package-lock.json" ]; then

    # check npm
    func_npm

    # Remove package-lock.json
    echo "[*] Remove package-lock.json" >> "./build-run.log"
    rm -rf "./package-lock.json"

    # Install depedencies of package.json
    echo "[*] Install depedencies of package.json using npm" >> "./build-run.log"
    npm install &> "./build.log"

  elif [ -f "./yarn.lock" ]; then

    # check yarn
    func_yarn

    # Remove yarn.lock
    echo "[*] Remove yarn.lock" >> "./build-run.log"
    rm -rf "./yarn.lock"

    # Install depedencies of package.json
    echo "[*] Install depedencies of package.json using yarn" >> "./build-run.log"
    yarn &> "./build.log"

    # Set alias command for run yarn
    echo "[*] Set alias command for run yarn" >> "./build-run.log"
    prun="$(which yarn)"
  else
    echo "[*] No package-lock.json or yarn.lock found" >> "./build-run.log"

    # check npm
    func_npm

    # Install depedencies of package.json
    echo "[*] Install depedencies of package.json using npm" >> "./build-run.log"
    npm install &> "./build.log"

  fi
fi

# check if project is NextJS
if [ -f "./next.config.js" ]; then
  echo "[*] It seems nextjs framework" >> "./build-run.log"

  # Find dist folder and remove
  if [ -f "./dist/index.js" ]; then
    echo "[*] Remove folder './dist'" >> "./build-run.log"
    rm -rf "./dist"
  fi

  # Build nextjs framework
  echo "[*] Build nextjs framework" >> "./build-run.log"
  $prun build &> "./build.log"

  # Find next-sitemap
  if [ -f "./next-sitemap.js" ]; then
    echo "[*] Build next-sitemap plugin" >> "./build-run.log"
    $prun sitemap &> "./build.log"
  fi

  # write log
  func_build_log
fi

# check if project is ReactJS
if [ -f "./node_modules/.bin/react-scripts" ]; then
  echo "[*] It seems reactjs framework"
  
  # find build folder and remove
  if [ -d "./build" ]; then
    rm -rf "./build"
  fi

  # Build reactjs framework
  echo "[*] Build reactjs framework" >> "./build-run.log"
  $prun build &> "./build.log"

  # write log
  func_build_log
fi

# check if project is Adonis
if [ -f "./ace" ]; then

  if [ -f "./env.ts" ]; then
    echo "[*] It seems adonis 5 framework" >> "./build-run.log"

    # find build folder and remove
    if [ -d "./build" ]; then
      rm -rf "./build"
    fi

    # Build adonis 5 framework
    echo "[*] Build adonis 5 framework" >> "./build-run.log"
    $prun build &> "./build.log"

    echo "[*] Copy env file into build folder" >> "./build-run.log"
    cp .env build/

    echo "[*] Clean install on build folder" >> "./build-run.log"

    if [ -f "./package-lock.json" ]; then
      ci="npm ci --production"
    elif [ -f "./yarn.lock" ]; then
      ci="yarn install --production"
    fi

    cd build/

    $ci &> "./build.log"

    cd ../

  else
    echo "[*] It seems adonis framework" >> "./build-run.log"
  fi

  # write log
  func_build_log

fi


# check if project is using PHP Language
if [ -f "./composer.json" ]; then

  # check php
  func_php

  # check composer
  func_composer

  # Find composer.lock file and remove
  if [ -f "./composer.lock" ]; then
    echo "[*] Remove composer.lock file" >> "./build-run.log"
    rm -rf "./composer.lock"
  fi

  # Find vendor folder and remove
  if [ -d "./vendor" ]; then
    echo "[*] Remove vendor folder" >> "./build-run.log"
    rm -rf "./vendor"
  fi

  # Install depedencies of composer.json
  echo "[*] Install depedencies of composer.json using composer" >> "./build-run.log"
  $crun install &> "./build.log"

  # check if project is Laravel
  if [ -f "./artisan" ]; then
    echo "[*] It seems laravel framework" >> "./build-run.log"

    artisan="$(php artisan)"

    # build javascript webpack
    echo "[*] Bundling javascript files with webpack" >> "./build-run.log"
    $prun prod &> "./build.log"

    # remove the cached bootstrap files
    echo "[*] Remove the cached bootstrap files" >> "./build-run.log"
    $artisan optimize:clear &> "./build.log"

    # write log
    func_build_log
  fi
fi


# check if running using pm2
if [ -f "./ecosystem.config.js" ]; then

  # check pm2 exist
  func_pm2

  # start or restart server
  echo "[*] Restarting server using pm2" >> "./build-run.log"
  pm2 restart ecosystem.config.js &>/dev/null
  
fi

func_remove_log

