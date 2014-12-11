tv4 = require 'tv4'
gaze = require 'gaze'
fs = require 'fs'
path = require 'path'

colors = require('colors');

colors.setTheme
  silly: 'rainbow',
  input: 'grey',
  verbose: 'cyan',
  prompt: 'grey',
  info: 'green',
  data: 'grey',
  help: 'cyan',
  warn: 'yellow',
  debug: 'blue',
  error: 'red'

# https://github.com/Automattic/cli-table
schema2file = {}

findMissing = (missings, data, schema)->
  if missings.length
    for missing in missings
      console.log "getting #{missing}".warn
      tv4.addSchema missing, JSON.parse fs.readFileSync "schemas/#{missing}"
    result = tv4.validateResult data, schema, true, true
    #TODO change to deep search of schema
    if result.missing.length
      result = findMissing result.missing, data, schema
    result

revalidateMapedFiles = (key)->
  if schema2file[key]?.length
    for file in schema2file[key]
      tv4.dropSchemas()
      validateFile file
  else
    console.log "NO mapping for #{key}".error
validateFile = (url)->
  console.log '============================================================'.info
  console.log "Validation for #{url}"
  console.log '------------------------------------------------------------'.info
  data = JSON.parse fs.readFileSync url
  schemaFileName = "schemas/#{data.package.replace '.', '/'}.schema.json"
  schema = JSON.parse fs.readFileSync schemaFileName
  if not schema2file[schemaFileName]? then schema2file[schemaFileName] = []
  if url not in schema2file[schemaFileName] then schema2file[schemaFileName].push url
  result = tv4.validateResult data, schema, true, true
  if result.missing.length
    result = findMissing result.missing, data, schema
  # delete result.error?.stack
  console.log result
  console.log '============================================================\n'.info
  return

gaze ['test/**/*.json', 'schemas/**/*.schema.json'], (err, watcher)->

  watcher.relative (err, files)->
    process.stdout.write '\u001B[2J\u001B[0;0f' #Clean Screen
    for own folder of files
      for file in files[folder] when file.slice(-1) isnt "/" and file.slice(-12) isnt ".schema.json"
        tv4.dropSchemas()
        validateFile "#{folder}#{file}"


  watcher.on 'changed', (filepath)->
    return if not filepath
    process.stdout.write '\u001B[2J\u001B[0;0f' #Clean Screen
    filepath = path.relative(__dirname , filepath)
    console.log(filepath + ' was changed');
    if filepath.slice(-12) is ".schema.json"
      tv4.dropSchemas()
      revalidateMapedFiles filepath
    else if /^.*test\/(?:(?!\.schema).)*\.json$/.test filepath
      tv4.dropSchemas()
      validateFile filepath


