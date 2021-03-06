components = require 'statwolf-components'
path       = require 'path'
fs         = require 'fs'

module.exports = Navigator =

  getText: (editor) ->
    cursor = editor.getCursors()[0]
    range = editor.displayBuffer.bufferRangeForScopeAtPosition '.string.quoted', cursor.getBufferPosition()
    text = if range then editor.getTextInBufferRange(range)[1..-2] else
      editor.getWordUnderCursor wordRegex: /[\/A-Z\.\-\d\\-_:]+(:\d+)?/i
    text.trim()

  isValidSWPath: (text) ->
    return text.match(/^Statwolf(\.[\w\d\-\_]+)+$/g) isnt null

  openRequiredPath: (swPath) ->
    swPath = swPath.replace /\./g, path.sep
    componentPath = path.join localStorage.getItem('rootPath'), swPath
    componentName = path.basename componentPath

    metaPath = componentPath + path.sep + componentName + '.meta.json'

    unless fs.existsSync metaPath
      atom.notifications.addWarning componentName + ' not found.',
        detail: 'The main file might be missing, please check it.'
        icon: 'alert'
      return

    componentType = JSON.parse(fs.readFileSync metaPath).ComponentType
    mainExtension = components.config[componentType].extension
    mainFilePath  = componentPath + path.sep + componentName + mainExtension

    atom.workspace.open mainFilePath

  navigate: ->
    editor = atom.workspace.getActiveTextEditor()

    unless editor
      return

    quotedText = @getText editor

    if @isValidSWPath quotedText
      @openRequiredPath quotedText
