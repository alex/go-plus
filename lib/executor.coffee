{exec} = require 'child_process'
{BufferedProcess} = require 'atom'
fs = require 'fs-plus'

module.exports =
class Executor
  constructor: (@environment) ->

  exec: (command, cwd, env, callback, args) =>
    output = ''
    error = ''
    code = 0
    messages = []
    options =
      cwd: null
      env: null
    options.cwd = fs.realpathSync(cwd) if cwd? and cwd isnt '' and cwd isnt false and fs.existsSync(cwd)
    options.env = if env? then env else @environment
    stdout = (data) -> output += data
    stderr = (data) -> error += data
    exit = (data) ->
      if error? and error isnt '' and error.replace(/\r?\n|\r/g, '') is "\'" + command + "\' is not recognized as an internal or external command,operable program or batch file."
        message =
            line: false
            column: false
            msg: 'No file or directory: [' + command + ']'
            type: 'error'
            source: 'executor'
        messages.push message
        callback(127, output, error, messages)
        return
      code = data
      callback(code, output, error, messages)
    args = [] unless args?
    bufferedprocess = new BufferedProcess({command, args, options, stdout, stderr, exit})
    bufferedprocess.process.once 'error', (err) =>
      if err.code is 'ENOENT'
        message =
            line: false
            column: false
            msg: 'No file or directory: [' + command + ']'
            type: 'error'
            source: 'executor'
        messages.push message
      else
        console.log err

      callback(127, output, error, messages)
