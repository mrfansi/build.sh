#!/bin/bash

# default run package manager
prun="$(which npm) run"

# default run composer manager
crun="$(which composer)"

func_npm() {
  # check if npm command exist
  if [! command -v npm &>/dev/null ]; then
    echo "[*] NPM not found. exit"
    exit
  else
    version=$(npm -v)
    echo "[*] Detected NPM version: $version"
  fi
}

func_yarn() {
  # check if yarn command exist
  if [! command -v yarn &>/dev/null]; then
    echo "[*] Yarn not found. Please install first"
    exit
  else
    version=$(yarn -v)
    echo "[*] Detected Yarn version: $version"
  fi
}

func_php() {
  # print php version
  if [! command -v php &>/dev/null ]; then
    echo "[*] PHP not found. Please install first"
    exit
  else
    version=$(php -v | grep ^PHP | cut -d' ' -f2)
    echo "[*] Detected php version: $version"
  fi
}

func_composer() {
  if [! command -v composer &>/dev/null ]; then
    echo "[*] Composer not found. Please install first"
    exit
  else
    version=$(composer -V | grep ^Composer | cut -d' ' -f3)
    echo "[*] Detected composer version: $version"
  fi
}

func_build_log() {
  if [ ! -f "./build.log" ]; then
    touch "./build.log"
  fi

  now="$(date +'%Y-%m-%d %H:%M')"
  count=$(awk 'END { print NR }' ./build.log)

  echo "[build] Build #$(($count+1)) at $now" >> "./build.log"
}

if [ -f "./package.json" ]; then
  echo "[*] Package.json detected"

  # Remove node_modules
  if [ -d "./node_modules" ]; then
    echo "[*] Remove node_modules"
    rm -rf "./node_modules"
  fi

  if [ -f "./package-lock.json" ]; then

    # check NPM
    func_npm

    # Remove package-lock.json
    echo "[*] Remove package-lock.json"
    rm -rf "./package-lock.json"

    # Install depedencies of package.json
    echo "[*] Install depedencies of package.json using npm"
    npm install &>/dev/null

  elif [ -f "./yarn.lock" ]; then

    # check yarn
    func_yarn

    # Remove yarn.lock
    echo "[*] Remove yarn.lock"
    rm -rf "./yarn.lock"

    # Install depedencies of package.json
    echo "[*] Install depedencies of package.json using yarn"
    yarn &>/dev/null

    # Set alias command for run yarn
    echo "[*] Set alias command for run yarn"
    prun="$(which yarn)"
  else
    echo "[*] No package-lock.json or yarn.lock found"

    # check NPM
    func_npm

    # Install depedencies of package.json
    echo "[*] Install depedencies of package.json using npm"
    npm install &>/dev/null
  fi
fi

# check if project is NextJS
if [ -f "./next.config.js" ]; then
  echo "[*] It seems nextjs framework"

  # Find dist folder and remove
  if [ -f "./dist/index.js" ]; then
    echo "[*] Remove folder './dist'"
    rm -rf "./dist"
  fi

  # Build nextjs framework
  echo "[*] Build nextjs framework"
  $prun build &>/dev/null

  # write log
  func_build_log

  # Find next-sitemap
  if [ -f "./next-sitemap.js" ]; then
    echo "[*] Build next-sitemap plugin"
    $prun sitemap &>/dev/null
  fi
fi


# check if project is using PHP Language
if [ -f "./composer.json" ]; then

  # check php
  func_php

  # check composer
  func_composer

  # Find composer.lock file and remove
  if [ -f "./composer.lock" ]; then
    echo "[*] Remove composer.lock file"
    rm -rf "./composer.lock"
  fi

  # Find vendor folder and remove
  if [ -d "./vendor" ]; then
    echo "[*] Remove vendor folder"
    rm -rf "./vendor"
  fi

  # Install depedencies of composer.json
  echo "[*] Install depedencies of composer.json using composer"
  $crun install &>/dev/null

  # check if project is Laravel
  if [ -f "./artisan" ]; then
    echo "[*] It seems laravel framework"

    artisan="$(php artisan)"

    # build javascript webpack
    echo "[*] Bundling javascript files with webpack"
    $prun prod &>/dev/null

    # remove the cached bootstrap files
    echo "[*] Remove the cached bootstrap files"
    $artisan optimize:clear &>/dev/null

    # write log
    func_build_log
  fi
fi
