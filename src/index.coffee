fs = require 'fs'
path = require 'path'
stream = require 'stream'
Readable = stream.Readable
browserify = require 'browserify'

CLIENT_PATH = path.join process.cwd(), 'client'

run = (command, args, options = {}, cb) ->
	[options, cb] = [{}, options] unless cb
	console.log "RUN", command, args.join ' '
	child = require('child_process').spawn command, args, options
	child.stdout.pipe process.stdout
	child.stderr.pipe process.stderr
	child.on 'error', cb
	child.on 'close', (code) ->
		cb if code is 0 then null else new Error "exit code #{code}"

coffee = (compile, output, cb) ->
	run 'coffee', ['--bare', '--output', output, '--compile', compile], cb

mocha = (files, cb) ->
	run 'mocha', [
		'--reporter', 'spec',
		'--compilers', 'coffee:coffee-script/register',
		'--colors',
		files], cb

stringToStream = (string) ->
	s = new Readable()
	s._read = ->
	s.push string
	s.push null
	return s

exports.buildServer = (callback = ->) ->
	console.log "START build:server"
	coffee 'server', 'build/server'
	, -> coffee 'server.coffee', 'build/'
	, (err) ->
		if err then console.log "FAIL build:server", err
		else console.log "DONE build:server"
		callback null

exports.buildClient = (callback = ->) ->
	console.log "START build:client"
	run 'brunch', ['build'], cwd: CLIENT_PATH
	, (err) ->
		if err then console.log "FAIL build:client", err
		else console.log "DONE build:client"
		callback null

# @TODO : this would be cleaner, but brunch is complicated
# exports.buildClient = (callback = ->) ->
# 	require('brunch').build
# 		config: path.join __dirname, 'brunch-config'
# 	, (err) ->
# 		if err then console.log "FAIL build:client", err
# 		else console.log "DONE build:client"
# 		callback null

exports.build = (callback = ->) ->
	console.log "START build"
	exports.buildClient ->
		exports.buildServer ->
			console.log "DONE build"
			callback null

exports.b2b = (callback = ->) ->
	console.log "START npm-vendor"
	packageFile = path.join CLIENT_PATH, 'package.json'
	dependencies = Object.keys require(packageFile).dependencies
	out = path.join CLIENT_PATH, 'test-br.js'

	pipeline = browserify
		insertGlobals: false
		detectGlobals: false

	for dependency in dependencies
		console.log "DEP", dep = path.join CLIENT_PATH, 'node_modules', dependency
		pipeline.require dep, expose: dependency

	out = fs.createWriteStream out, 'utf8'
	out.write """
		var brunchRequire = require;
	"""
	pipeline.bundle().pipe out, end: false
	pipeline.on 'end', ->
		out.write """
			var npmRequire = require;
			window.require = brunchRequire;
		"""
		for dependency in dependencies
			out.write """
				require.register('#{dependency}', function(exports, require, module) {
					module.exports = npmRequire('#{dependency}'):
				}
			"""
		out.end()


exports.test = (callback = ->) ->
	console.log "START test"
	mocha 'tests', (err) ->
		if err then console.log "FAIL test", err
		else console.log "DONE test"

exports.lint = (callback = ->) ->
	console.log 'lint'