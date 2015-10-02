# TODO change templateHelper behaviour
# TODO change default miniEditor path suggestion

{$, $$, View, TextEditorView, ScrollView} = require "atom-space-pen-views"

fs         = require 'fs-plus'
os         = require 'os'
osenv      = require 'osenv'
path       = require 'path'
touch      = require 'touch'
components = require 'statwolf-components'

DEFAULT_SELECTED_DIR = 'Selected file\'s directory'
DEFAULT_PROJECT_ROOT    = 'Project root'
DEFAULT_EMPTY           = 'Empty'

getRoot = (inputPath) ->
  lastPath = null
  while inputPath != lastPath
    lastPath = inputPath
    inputPath = path.dirname(inputPath)
  return inputPath

isRoot = (inputPath) ->
  return path.dirname(inputPath) is inputPath

absolutify = (inputPath) ->
  if getRoot(inputPath) == '.'
    projectPaths = atom.project.getPaths()
    if projectPaths.length > 0
      return path.join projectPaths[0], inputPath

  absolutePath = path.resolve inputPath
  if inputPath.endsWith path.sep
    return absolutePath + path.sep
  else
    return absolutePath

class DirectoryListView extends ScrollView
  @content: ->
    @ul class: 'list-group', outlet: 'directoryList'

  renderFiles: (files, showParent) ->
    @empty()

    # Parent directory
    if showParent
      @append $$ ->
        @li class: 'list-item parent-directory', =>
          @span class: 'icon icon-file-directory', '..'

    files?.forEach (file) =>
      icon = if file.isDir then 'icon-file-directory' else 'icon-file-text'
      @append $$ ->
        @li class: "list-item #{'directory' if file.isDir}", =>
          @span class: "filename icon #{icon}", "data-name": path.basename(file.name), file.name
          if file.isDir and not file.isProjectDir then @span
            class: "add-project-folder icon icon-plus",
            title: "Open as project folder"

module.exports =
class StatwolfNewComponentPluginView extends View

  statwolfNewComponentPluginView: null
  componentType: null

  @config:
    caseSensitiveAutoCompletion:
      title: "Case-sensitive auto-completion"
      type: "boolean"
      default: false
    createFileInstantly:
      title: "Create files instantly"
      description: "When opening files that don't exist, create them
                    immediately instead of on save."
      type: "boolean"
      default: true
    helmDirSwitch:
      title: "Shortcuts for fast directory switching"
      description: "See README for details."
      type: "boolean"
      default: false
    defaultInputValue:
      title: "Default input value"
      description: "What should the path input default to when the dialog
                    is opened?"
      type: "string"
      enum: [DEFAULT_SELECTED_DIR, DEFAULT_PROJECT_ROOT, DEFAULT_EMPTY]
      default: DEFAULT_SELECTED_DIR

  @activate: (state) ->
    @statwolfNewComponentPluginView = new StatwolfNewComponentPluginView(state.statwolfNewComponentPluginViewState)

  @deactivate: ->
    @componentType = null
    @disposables.dispose()
    @statwolfNewComponentPluginView?.detach()

  @content: (params) ->
    @div class: "statwolf-new-component-plugin", =>
      @p
        outlet: "message",
        class: "icon icon-file-add",
        "Enter the path for the file/directory. Directories end with a "#{path.sep}"."
      @subview "miniEditor", new TextEditorView({mini:true})
      @subview "directoryListView", new DirectoryListView()

  @detaching: false,

  initialize: (serializeState) ->
    atom.commands.add('atom-workspace', {
      'statwolf-new-component-plugin:toggleFullForm': (event) => @toggle 'fullForm', event
      'statwolf-new-component-plugin:toggleForm': (event) => @toggle 'form', event
      'statwolf-new-component-plugin:toggleService': (event) => @toggle 'service', event
      'statwolf-new-component-plugin:toggleModel': (event) => @toggle 'model', event
      'statwolf-new-component-plugin:toggleControlTemplate': (event) => @toggle 'controlTemplate', event
      'statwolf-new-component-plugin:toggleView': (event) => @toggle 'view', event
      'statwolf-new-component-plugin:toggleController': (event) => @toggle 'controller', event
      'statwolf-new-component-plugin:togglePythonScript': (event) => @toggle 'pythonScript', event
      'statwolf-new-component-plugin:toggleRScript': (event) => @toggle 'rScript', event
    })

    atom.commands.add @element,
      "core:confirm": => @confirm()
      "core:cancel": => @detach()
      "statwolf-new-component-plugin:autocomplete": => @autocomplete()
      "statwolf-new-component-plugin:undo": => @undo()
      "statwolf-new-component-plugin:move-cursor-down": => @moveCursorDown()
      "statwolf-new-component-plugin:move-cursor-up": => @moveCursorUp()
    @directoryListView.on "click", ".list-item", (ev) => @clickItem(ev)
    @directoryListView.on "click", ".add-project-folder", (ev) => @addProjectFolder(ev)

    editor = @miniEditor.getModel()
    editor.setPlaceholderText './'
    editor.setSoftWrapped false

  clickItem: (ev) ->
    listItem = $(ev.currentTarget)
    @selectItem listItem
    @miniEditor.focus()

  selectItem: (listItem) ->
    if listItem.hasClass "parent-directory"
      newPath = path.dirname(@inputPath()) + path.sep
      @updatePath newPath
    else
      newPath = path.join @inputPath(), listItem.text()
      if not listItem.hasClass "directory"
        @openOrCreate(newPath)
      else
        @updatePath newPath + path.sep

  addProjectFolder: (ev) ->
    listItem = $(ev.currentTarget).parent(".list-item")
    folderPath = path.join @inputPath(), listItem.text()
    atom.project.addPath(folderPath)
    @detach()

  inputPath: () ->
    input = @miniEditor.getText()
    if input.endsWith path.sep
      return input
    else
      return path.dirname input

  # Returns the list of directories matching the current input (path and autocomplete fragment)
  getFileList: (callback) ->
    input = @miniEditor.getText()
    inputPath = absolutify(@inputPath())

    fs.stat inputPath, (err, stat) =>
      if err?.code is "ENOENT"
        return []

      fs.readdir inputPath, (err, files) =>
        fileList = []
        dirList = []

        files.forEach (filename) =>
          fragment = input.substr(input.lastIndexOf(path.sep) + 1, input.length)
          caseSensitive = atom.config.get "statwolf-new-component-plugin.caseSensitiveAutoCompletion"

          if not caseSensitive
            fragment = fragment.toLowerCase()

          matches =
            caseSensitive and filename.indexOf(fragment) is 0 or
            not caseSensitive and filename.toLowerCase().indexOf(fragment) is 0

          if matches
            filePath = path.join(inputPath, filename)

            try
              isDir = fs.statSync(filePath).isDirectory()
            catch
              ## TODO fix error which is thrown when you hold backspace

            (if isDir then dirList else fileList).push({
              name: filename,
              isDir: isDir,
              isProjectDir: isDir and filePath in atom.project.getPaths(),
            })

        callback.apply @, [dirList.concat fileList]

  # Called only when pressing Tab to trigger auto-completion
  autocomplete: ->
    pathToComplete = @inputPath()
    @getFileList (files) ->
      newString = pathToComplete
      oldInputText = @miniEditor.getText()
      indexOfString = oldInputText.lastIndexOf(pathToComplete)
      textWithoutSuggestion = oldInputText.substring(0, indexOfString)
      if files?.length is 1
        newPath = path.join(@inputPath(), files[0].name)

        suffix = if files[0].isDir then path.sep else ""
        @updatePath(newPath + suffix)

      else if files?.length > 1
        longestPrefix = @longestCommonPrefix((file.name for file in files))
        newPath = path.join(@inputPath(), longestPrefix)

        if (newPath.length > @inputPath().length)
          @updatePath(newPath)
        else
          atom.beep()
      else
        atom.beep()

  updatePath: (newPath, oldPath=null) ->
    @pathHistory.push oldPath or @miniEditor.getText()
    newPath = path.normalize(newPath)

    # If the new path is ./, just leave it blank.
    if newPath == ".#{path.sep}"
      newPath = ''

    @miniEditor.setText(newPath)

  update: ->
    if @detaching
      return

    if atom.config.get "statwolf-new-component-plugin.helmDirSwitch"
      text = @miniEditor.getText()
      if text.endsWith path.sep + path.sep
        @updatePath getRoot(text), text[...-1]
      else if text.endsWith("#{path.sep}~#{path.sep}") or text == "~#{path.sep}"
        try # Make sure ~ doesn't exist in the current directory.
          fs.statSync @inputPath()
        catch # It doesn't, do the shortcut!
          @updatePath osenv.home() + path.sep, text[...-2]
      else if text.endsWith("#{path.sep}:#{path.sep}") or text == ":#{path.sep}"
        projectPaths = atom.project.getPaths()
        if projectPaths.length > 0
          @updatePath projectPaths[0] + path.sep, text[...-2]

    @getFileList (files) ->
      @renderAutocompleteList files

    if @miniEditor.getText().endsWith(path.sep)
      @setMessage "file-directory-create"
    else
      @setMessage "file-add"

  setMessage: (icon, str) ->
    @message.removeClass "icon"\
      + " icon-file-add"\
      + " icon-file-directory-create"\
      + " icon-alert"
    if icon? then @message.addClass "icon icon-" + icon
    @message.text str or "
      Enter the path for the file/directory. Separator is '#{path.sep}'.
    "

  # Renders the list of directories
  renderAutocompleteList: (files) ->
    inputPath = absolutify(@inputPath())
    showParent = inputPath and inputPath.endsWith(path.sep) and not isRoot(inputPath)
    @directoryListView.renderFiles files, showParent

  confirm: ->
    selected = @find(".list-item.selected")
    if selected.length > 0
      @selectItem(selected)
    else
      @openOrCreate(@miniEditor.getText())

  openOrCreate: (inputPath) ->
    inputPath = absolutify(inputPath)

    if fs.existsSync(inputPath)
      if fs.statSync(inputPath).isFile()
        atom.workspace.open inputPath
        @detach()
      else
        atom.beep()
    else
      createWithin = path.dirname inputPath
      containsFiles = false
      try
        items = fs.listSync createWithin

        for item in items
          containsFiles = fs.isFileSync item

        [..., last ] = inputPath.split path.sep

        if containsFiles
          throw new Error 'Invalid path specified.'

        filesToCreate = components.templateHelper.getTemplates @componentType, last
        componentFullName = inputPath + path.sep + last

        for file in filesToCreate
          fs.writeFileSync componentFullName + file.extension, file.content

        @detach()
      catch error
        @setMessage 'alert', error.message

  undo: ->
    if @pathHistory.length > 0
      @miniEditor.setText @pathHistory.pop()
    else
      atom.beep()

  moveCursorDown: ->
    selected = @find(".list-item.selected").next()
    if selected.length < 1
      selected = @find(".list-item:first")
    @moveCursorTo(selected)

  moveCursorUp: ->
    selected = @find(".list-item.selected").prev()
    if selected.length < 1
      selected = @find(".list-item:last")
    @moveCursorTo(selected)

  moveCursorTo: (selectedElement) ->
    @find(".list-item").removeClass("selected")
    selectedElement.addClass("selected")

    parent = selectedElement.parent()
    parentHeight = parent.height()
    selectedPos = selectedElement.position()
    selectedHeight = selectedElement.height()
    if selectedPos.top < 0
      parent.scrollTop(selectedPos.top + parent.scrollTop())
    else if selectedPos.top + selectedHeight > parentHeight
      distanceBelow = selectedPos.top - parentHeight
      parent.scrollTop(distanceBelow + selectedHeight + parent.scrollTop())

  detach: ->
    $("html").off("click", @outsideClickHandler) unless not @outsideClickHandler
    @outsideClickHandler = null
    return unless @hasParent()
    @detaching = true
    @miniEditor.setText ""
    @setMessage()
    @directoryListView.empty()
    miniEditorFocused = @miniEditor.hasFocus()
    super
    @panel?.destroy()
    @restoreFocus() if miniEditorFocused
    @detaching = false

  attach: (suggested) ->
    @suggestPath suggested
    @previouslyFocusedElement = $(":focus")
    @pathHistory = []
    @panel = atom.workspace.addModalPanel(item: this)

    @parent(".modal").css({
      "max-height": "100%",
      display: "flex",
      "flex-direction": "column",
    })

    # Detach when clicked outside.
    @outsideClickHandler = (ev) =>
      if not $(ev.target).closest(".statwolf-new-component-plugin").length
        @detach()
    $("html").on "click", @outsideClickHandler

    @miniEditor.focus()
    @miniEditor.getModel().setCursorScreenPosition [0, 10000], autoscroll: true

    # Populate the directory listing live
    @miniEditor.getModel().onDidChange => @update()

    @miniEditor.focus()
    @getFileList (files) -> @renderAutocompleteList files

  suggestPath: (suggested) ->
    suggestedPath = ''
    switch atom.config.get("statwolf-new-component-plugin.defaultInputValue")
      when DEFAULT_SELECTED_DIR
        suggestedPath = suggested
        if fs.isFileSync suggestedPath
          suggestedPath = path.dirname suggestedPath
        suggestedPath += path.sep
      when DEFAULT_PROJECT_ROOT
        projectPaths = atom.project.getPaths()
        if projectPaths.length > 0
          suggestedPath = projectPaths[0] + path.sep

    @miniEditor.setText suggestedPath

  toggle: (type, event) =>
    launchPath = event.target.attributes[2].textContent
    @componentType = type
    if @hasParent()
      @detach()
    else
      @attach launchPath

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.views.getView(atom.workspace).focus()

  longestCommonPrefix: (fileNames) ->
    if (fileNames?.length == 0)
      return ""

    longestCommonPrefix = ""
    for prefixIndex in [0..fileNames[0].length - 1]
      nextCharacter = fileNames[0][prefixIndex]
      for fileIndex in [0..fileNames.length - 1]
        fileName = fileNames[fileIndex]
        if (fileName.length < prefixIndex || fileName[prefixIndex] != nextCharacter)
          # The first thing that doesn't share the common prefix!
          return longestCommonPrefix
      longestCommonPrefix += nextCharacter

    return longestCommonPrefix
