'use strict'

program = require 'commander'
commands = require './'

program
  .version(require('../package.json').version)
  .usage('[command] [options]')

program
  .command('build')
  .description('Build server & client')
  .action -> commands.build()

program
  .command('build:server')
  .action -> commands.buildServer()

program
  .command('build:client')
  .action -> commands.buildClient()

program
  .command('test')
  .action -> commands.test()

program
  .command('bundle')
  .action -> commands.b2b()

program
  .command('dev')
  .action -> console.log "DEV not implemented"

program
  .command('dev:client')
  .action -> console.log "DEV-CLIENT not implemented"

program
  .command('dev:server')
  .action -> console.log "DEV-SERVER not implemented"

program
  .command('prepublish')
  .action -> console.log "DEV-PREPUBLISH not implemented"

program
  .command('postinstall')
  .action -> console.log "DEV-POSTINSTALL not implemented"

exports.run = ->

  if process.argv.length > 2
    args = process.argv.slice()
  else
    try
      args = JSON.parse(process.env.npm_config_argv).original
      switch args[0]
        when 'run'
          args.unshift 'npm'
        when 'install'
          args = ['npm', 'run', 'postinstall']
        when 'publish'
          args = ['npm', 'run', 'prepublish']
        else
          throw new Error 'unsupported npm hook'

    catch err
      throw new Error 'cant use cozybuild with no arguments'

  console.log args

  if args.length > 1
    program.parse args
  else
    program.help()
