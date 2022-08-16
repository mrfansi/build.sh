#!/bin/bash

# program
cnpm="$(which npm)"
cyarn="$(which yarn)"
ccomposer="$(which composer)"
cphp="$(which php)"
cpm2="$(which pm2)"

# default run package manager
prun="$($cnpm) run"

func_logs() {

  # remove folder logs
  if [ -d "./logs" ]; then
    rm -rf "./logs"
  fi
  mkdir "./logs"
}

func_npm() {
  # check if npm command exist
  if type $cnpm &>/dev/null; then

    # npm current version
    npm_version="$($cnpm -v)"

    echo "[*] Detected NPM version: $npm_version" >> "./logs/build.log"
  else
    echo "[*] NPM not found. Please install first" >> "./logs/build.log"
    exit
  fi
}

func_yarn() {
  # check if yarn command exist
  if type $cyarn &>/dev/null; then

    # yarn current version
    yarn_version="$(yarn -v)"

    echo "[*] Detected Yarn version: $yarn_version" >> "./logs/build.log"
  else
    echo "[*] Yarn not found. Please install first" >> "./logs/build.log"
    exit
  fi
}

func_php() {
  # print php version
  if type $cphp &>/dev/null; then

    # php current version
    php_version=$($cphp -v | grep ^PHP | cut -d' ' -f2)

    echo "[*] Detected PHP version: $php_version" >> "./logs/build.log"
  else
    echo "[*] PHP not found. Please install first" >> "./logs/build.log"
    exit
  fi
}

func_composer() {
  if type $ccomposer &>/dev/null; then

    # composer current version
    composer_version=$($ccomposer -V | grep ^Composer | cut -d' ' -f3)

    echo "[*] Detected composer version: $composer_version" >> "./logs/build.log"
  else
    echo "[*] Composer not found. Please install first" >> "./logs/build.log"
    exit
  fi
}

func_pm2() {
  if type $cpm2 &>/dev/null; then

    # pm2 current version
    pm2_version=$($cpm2 -v)

    echo "[*] Detected pm2 version: $pm2_version" >> "./logs/build.log"
  else
    echo "[*] PM2 not found. Please install first" >> "./logs/build.log"
    exit
  fi
}

func_build_log() {
  now="$(date +'%Y-%m-%d %H:%M')"

  echo "[*] Build completed at $now" >> "./logs/build.log"
}

func_logs

if [ -f "./ecosystem.config.js" ]; then
  echo "[*] Stop server PM2 first" >> "./logs/build.log"
  $cpm2 stop "./ecosystem.config.js" &>/dev/null
fi

if [ -f "./package.json" ]; then
  echo "[*] Package.json detected" >> "./logs/build.log"

  if [ -d "./node_modules" ]; then
    echo "[*] Remove node_modules" >> "./logs/build.log"
    rm -rf "./node_modules"
  fi

  if [ -f "./package-lock.json" ]; then

    # check npm
    func_npm

    # Remove package-lock.json
    echo "[*] Remove package-lock.json" >> "./logs/build.log"
    rm -rf "./package-lock.json"

    # Install depedencies of package.json
    echo "[*] Install depedencies of package.json using npm" >> "./logs/build.log"
    $cnpm install &> "./logs/npm.log"

  elif [ -f "./yarn.lock" ]; then

    # check yarn
    func_yarn

    # Remove yarn.lock
    echo "[*] Remove yarn.lock" >> "./logs/build.log"
    rm -rf "./yarn.lock"

    # Install depedencies of package.json
    echo "[*] Install depedencies of package.json using yarn" >> "./logs/build.log"
    $cyarn &> "./logs/yarn.log"

    # Set alias command for run yarn
    echo "[*] Set alias command for run yarn" >> "./logs/build.log"
    prun="$($cyarn)"
  else
    echo "[*] No package-lock.json or yarn.lock found" >> "./logs/build.log"

    # check npm
    func_npm

    # Install depedencies of package.json
    echo "[*] Install depedencies of package.json using npm" >> "./logs/build.log"
    $cnpm install &> "./logs/npm.log"

  fi
fi

# check if project is NextJS
if [ -f "./next.config.js" ]; then
  echo "[*] It seems nextjs framework" >> "./logs/build.log"

  # Find dist folder and remove
  if [ -f "./dist/index.js" ]; then
    echo "[*] Remove folder './dist'" >> "./logs/build.log"
    rm -rf "./dist"
  fi

  # Build nextjs framework
  echo "[*] Build nextjs framework" >> "./logs/build.log"
  $prun build &> "./logs/nextjs.log"

  # Find next-sitemap
  if [ -f "./next-sitemap.js" ]; then
    echo "[*] Build next-sitemap plugin" >> "./logs/build.log"
    $prun sitemap &> "./logs/next-sitemap.log"
  fi

  # write log
  func_build_log
fi

# check if project is ReactJS
if [ -f "./node_modules/.bin/react-scripts" ]; then
  echo "[*] It seems reactjs framework" >> "./logs/build.log"
  
  # find build folder and remove
  if [ -d "./build" ]; then
    rm -rf "./build"
  fi

  # Build reactjs framework
  echo "[*] Build reactjs framework" >> "./logs/build.log"
  $prun build &> "./logs/reactjs.log"

  # write log
  func_build_log
fi

# check if project is Adonis
if [ -f "./ace" ]; then

  if [ -f "./env.ts" ]; then
    echo "[*] It seems adonis 5 framework" >> "./logs/build.log"

    # find build folder and remove
    if [ -d "./build" ]; then
      rm -rf "./build"
    fi

    # Build adonis 5 framework
    echo "[*] Build adonis 5 framework" >> "./logs/build.log"
    $prun build &> "./logs/adonis5.log"

    echo "[*] Copy env file into build folder" >> "./logs/build.log"
    cp .env build/

    echo "[*] Clean install on build folder" >> "./logs/build.log"

    if [ -f "./package-lock.json" ]; then
      ci="$cnpm ci --production"
    elif [ -f "./yarn.lock" ]; then
      ci="$cyarn install --production"
    fi

    cd build/

    $ci &> "./logs/adonis5-production.log"

    cd ../

  else
    echo "[*] It seems adonis framework" >> "./logs/build.log"
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
    echo "[*] Remove composer.lock file" >> "./logs/build.log"
    rm -rf "./composer.lock"
  fi

  # Find vendor folder and remove
  if [ -d "./vendor" ]; then
    echo "[*] Remove vendor folder" >> "./logs/build.log"
    rm -rf "./vendor"
  fi

  # Install depedencies of composer.json
  echo "[*] Install depedencies of composer.json using composer" >> "./logs/build.log"
  $ccomposer install &> "./logs/composer.log"

  # check if project is Laravel
  if [ -f "./artisan" ]; then
    echo "[*] It seems laravel framework" >> "./logs/build.log"

    artisan="$($cphp artisan)"

    # build javascript webpack
    echo "[*] Bundling javascript files with webpack" >> "./logs/build.log"
    $prun prod &> "./logs/laravel.log"

    # remove the cached bootstrap files
    echo "[*] Remove the cached bootstrap files" >> "./logs/build.log"
    $artisan optimize:clear &> "./logs/laravel.log"

    # write log
    func_build_log
  fi
fi


# check if running using pm2
if [ -f "./ecosystem.config.js" ]; then

  # check pm2 exist
  func_pm2

  # start or restart server
  echo "[*] Restarting server using pm2" >> "./logs/build.log"
  pm2 restart ecosystem.config.js &>/dev/null
  
fi