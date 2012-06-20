# DeployTower

Helps you deploy your apps automatically by exposing an API that will deploy your apps for you.

## Disclaimer

This is only a (working) prototype. No tests yet. Use at your own peril.

## Features

 * Deploy to heroku
 * HTTP Basic auth with a per-project API key

## Setup

Easy:

   * make sure you have access to your own and heroku's git repos
   * clone
   * bundle install
   * create `config.yml` with info aobut your repos
   * curl localhost:9292/deploy/app_name

## Hack

You know the drill. Fork, create stuff, send pull request.
