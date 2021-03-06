{$, $$, View, TextEditorView, ScrollView} = require 'atom-space-pen-views'
{allowUnsafeEval, allowUnsafeNewFunction} = require 'loophole'

fs         = require 'fs-plus'
path       = require 'path'
components = require 'statwolf-components'
Handlebars = require 'handlebars'

DirectoryListView = require './directory-list-view'
ComponentTypeView = require './component-type-view'
SnippetListView   = require './snippet-list-view'
StatwolfNavigator = require './navigator'

module.exports =
class StatwolfNewComponentPluginView extends View

  statwolfNewComponentPluginView: null
  componentType: null
  componentView: null

  @detaching: false
  @creatingTemplate: false

  @config:
    caseSensitiveAutoCompletion:
      title: 'Case-sensitive auto-completion'
      type: 'boolean'
      default: false
    createFileInstantly:
      title: 'Create files instantly'
      description: "When opening files that don't exist, create them
                    immediately instead of on save."
      type: 'boolean'
      default: true
    openExtraPanel:
      title: 'Open extra panel'
      description: 'Automatically open extra panel when a new component has been created'
      type: 'boolean'
      default: false
    doubleClickNavigation:
      title: 'Double click to navigate'
      description: 'When double clicking to a component string, automatically open that component main file'
      type: 'boolean'
      default: true

  @content: (params) ->
    @div class: 'statwolf-new-component-plugin', =>
      @p
        outlet: 'message',
        class: 'icon icon-file-add',
        "Enter the path for the file/directory. Directories end with a "#{path.sep}"."
      @label outlet: 'overwriteLabel', =>
        @input outlet: 'overwriteCheckbox', type: 'checkbox'
        @text ' Overwrite existing templates'
      @subview 'miniEditor', new TextEditorView({mini:true})
      @subview 'directoryListView', new DirectoryListView()

  @activate: (state) ->
    @statwolfNewComponentPluginView = new StatwolfNewComponentPluginView state.statwolfNewComponentPluginViewState

    atom.workspace.observeTextEditors (editor) =>
      view = atom.views.getView editor
      view.ondblclick = =>
        if atom.config.get 'statwolf-new-component-plugin.doubleClickNavigation'
          StatwolfNavigator.navigate()

  @deactivate: ->
    @componentType = null
    @statwolfNewComponentPluginView?.detach()

  initialize: (serializeState) ->
    atom.commands.add('atom-workspace', {
      'statwolf-new-component-plugin:toggle': (event) => @toggle event
      'statwolf-new-component-plugin:expandComponent': (event) => @expandComponent event
      'statwolf-new-component-plugin:showComponentExtra': (event) => @showComponentExtra event
      'statwolf-new-component-plugin:copyStatwolfPath': (event) => @copyStatwolfPath event
      'statwolf-new-component-plugin:addNewTemplate': (event) => @addNewTemplate event
      'statwolf-new-component-plugin:pasteComponentSnippet': (event) => @getSnippetsForCurrentComponent event
      'statwolf-new-component-plugin:getComponentSnippets': (event) => @getSnippetsForSelectedComponent event
      'statwolf-new-component-plugin:navigate': (event) => StatwolfNavigator.navigate()
    })

    atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @detach()
      'statwolf-new-component-plugin:autocomplete': => @autocomplete()
      'statwolf-new-component-plugin:undo': => @undo()
      'statwolf-new-component-plugin:move-cursor-down': => @moveCursorDown()
      'statwolf-new-component-plugin:move-cursor-up': => @moveCursorUp()

    @directoryListView.on 'click', ".list-item", (ev) => @clickItem item

    editor = @miniEditor.getModel()
    editor.setPlaceholderText './'
    editor.setSoftWrapped false

  clickItem: (item) ->
    listItem = $(item.currentTarget)
    @selectItem listItem
    @miniEditor.focus()

  selectItem: (listItem) ->
    if listItem.hasClass 'parent-directory'
      newPath = path.dirname(@inputPath()) + path.sep
      @updatePath newPath
    else
      newPath = path.join @inputPath(), listItem.text()
      if not listItem.hasClass 'directory'
        if @creatingTemplate
          @addTemplate newPath
        else
          @openOrCreate newPath
      else
        @updatePath newPath + path.sep

  getSnippetsForCurrentComponent: (event) ->
    editor = null
    unless editor = atom.workspace.getActiveTextEditor()
      return

    currentPath = editor.getPath()
    unless currentPath
      return

    filePath = path.parse currentPath
    @snippetFilePath = filePath
    metaPath = filePath.dir + path.sep + filePath.name + '.meta.json'
    @getSnippetsAndOpenListView metaPath

  getSnippetsForSelectedComponent: (event) ->
    filePath = path.parse @getSelectedComponentFromEvent event
    @snippetFilePath = filePath
    metaPath = path.join(filePath.dir, filePath.base, filePath.name) + '.meta.json'
    @getSnippetsAndOpenListView metaPath

  getSnippetsAndOpenListView: (metaPath) ->
    unless fs.existsSync metaPath
      return

    snippets = JSON.parse(fs.readFileSync metaPath).Snippets

    unless snippets
      return

    snippetList = []

    snippets.forEach (snippet) ->
      snippetList.push snippet.body

    snippetListView = new SnippetListView
    snippetListView.toggle @, snippets

  pasteSnippetIntoEditor: (snippet) ->
    unless editor = atom.workspace.getActiveTextEditor()
      return

    env = localStorage.getItem 'activeEnvironment'
    env += 'EnvConfig'
    filePath = @snippetFilePath.dir
    swPath = filePath.split((localStorage.getItem 'rootPath') + path.sep)[1]

    context =
      hostname: localStorage.getItem 'host'
      port: localStorage.getItem 'port'
      user: localStorage.getItem 'userId'
      componentName: @snippetFilePath.name
      internalPath: swPath.split(path.sep).join('.')

    template = Handlebars.compile snippet
    outcome  = allowUnsafeEval => allowUnsafeNewFunction =>
      template context

    editor.insertText outcome

  inputPath: () ->
    input = @miniEditor.getText()
    if input.endsWith path.sep
      return input
    else
      return path.dirname input

  getFileList: (callback) ->
    input = @miniEditor.getText()
    inputPath = @absolutify @inputPath()

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
            filePath = path.join inputPath, filename
            isDir = fs.statSync(filePath).isDirectory()

            (if isDir then dirList else fileList).push({
              name: filename,
              isDir: isDir,
              isProjectDir: isDir and filePath in atom.project.getPaths(),
            })

        callback.apply @, [dirList.concat fileList]

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

    if newPath == ".#{path.sep}"
      newPath = ''

    @miniEditor.setText newPath

  update: ->
    if @detaching
      return

    @getFileList (files) ->
      @renderAutocompleteList files

    if @miniEditor.getText().endsWith path.sep
      @setMessage 'file-directory-create'
    else
      @setMessage 'file-add'

  setMessage: (icon, str) ->
    @message.removeClass "icon"\
      + " icon-file-add"\
      + " icon-file-directory-create"\
      + " icon-alert"
    if icon? then @message.addClass "icon icon-" + icon
    @message.text str or "Enter the path for the file/directory. Separator is '#{path.sep}'."

  renderAutocompleteList: (files) ->
    inputPath = @absolutify @inputPath()
    showParent = inputPath and inputPath.endsWith(path.sep) and not @isRoot(inputPath)
    @directoryListView.renderFiles files, showParent

  confirm: ->
    selected = @find '.list-item.selected'
    if selected.length > 0
      @selectItem selected
    else
      if @creatingTemplate
        @addTemplate @miniEditor.getText()
      else
        @openOrCreate @miniEditor.getText()

  addTemplate: (inputPath) ->
    inputPath = @absolutify inputPath
    unless fs.existsSync inputPath
      @detach()
      return

    try
      overwrite = @overwriteLabel[0].childNodes[0].checked
      tptDir = localStorage.getItem 'externalTemplateDir'
      addedTemplates = components.templateHelper.addTemplateFromList inputPath, overwrite, tptDir
      atom.notifications.addSuccess "#{addedTemplates.length} new templates added."
    catch error
      atom.notifications.addError error.message
    finally
      @detach()

  openOrCreate: (inputPath) ->
    inputPath = @absolutify inputPath

    if fs.existsSync inputPath
      if fs.statSync(inputPath).isFile()
        atom.workspace.open inputPath
        @detach()
      else
        atom.beep()
      return

    createWithin = path.dirname inputPath
    containsFiles = false

    try
      items = fs.listSync createWithin

      for item in items
        containsFiles = fs.isFileSync item

      [..., last] = inputPath.split path.sep

      if containsFiles
        throw new Error 'Invalid path specified.'

      componentFullName = inputPath + path.sep + last
      rPath = localStorage.getItem 'rootPath'
      basePath = componentFullName.split(rPath)[1].slice 1

      context =
        name: last
        path: path.dirname path.dirname componentFullName
        basePath: path.dirname basePath

      filesToCreate = allowUnsafeEval => allowUnsafeNewFunction =>
        tptDir = localStorage.getItem 'externalTemplateDir'
        components.templateHelper.getFileListForType @componentType, context, tptDir

      for file in filesToCreate
        fs.writeFileSync file.path, file.content

      if atom.config.get 'statwolf-new-component-plugin.openExtraPanel'
        @showComponentPanel path.dirname(componentFullName)

      @detach()

    catch error
      @setMessage 'alert', error.message
      return error.message

  addNewTemplate: ->
    @creatingTemplate = true
    @suggestedPathFromSelection = process.env.HOME
    @getComponentName()

  expandComponent: (event) ->
    selectedItem = @getSelectedComponentFromEvent event
    if fs.isFileSync selectedItem
      selectedItem = path.dirname selectedItem
    @showComponentPanel selectedItem

  showComponentExtra: (event) ->
    if @componentView and @componentView.hasParent()
      @componentView.close()
    else
      @showComponentPanel path.dirname atom.workspace.getActiveTextEditor().getPath()

  showComponentPanel: (fullPath) ->
    fullName = fullPath + path.sep + path.basename fullPath
    isDependency = fs.existsSync(fullName + '.deps.json')
    isResolver = fs.existsSync(fullName + '.resolver.js')

    unless isDependency or isResolver
      return

    TabbedView = require './tabbed-view'
    if @componentView
      @componentView.close()

    @componentView = new TabbedView(
      componentPath: fullPath,
      fullName: fullName,
      isDependency: isDependency,
      isResolver: isResolver)

    @componentView.componentPath = fullPath
    @componentView.toggle()

  undo: ->
    if @pathHistory.length > 0
      @miniEditor.setText @pathHistory.pop()
    else
      atom.beep()

  moveCursorDown: ->
    selected = @find(".list-item.selected").next()
    if selected.length < 1
      selected = @find(".list-item:first")
    @moveCursorTo selected

  moveCursorUp: ->
    selected = @find(".list-item.selected").prev()
    if selected.length < 1
      selected = @find(".list-item:last")
    @moveCursorTo selected

  moveCursorTo: (selectedElement) ->
    @find(".list-item").removeClass 'selected'
    selectedElement.addClass 'selected'

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
    @creatingTemplate = false
    @overwriteLabel[0].childNodes[0].checked = false
    @overwriteLabel.removeClass 'hidden'
    $("html").off("click", @outsideClickHandler) unless not @outsideClickHandler
    @outsideClickHandler = null
    return unless @hasParent()

    @detaching = true
    @miniEditor.setText ''
    @setMessage()
    @directoryListView.empty()
    miniEditorFocused = @miniEditor.hasFocus()
    super
    @panel?.destroy()
    @restoreFocus() if miniEditorFocused
    @detaching = false

  attach: (suggested) ->
    @suggestedPathFromSelection = suggested
    componentTypeView = new ComponentTypeView

    tptDir = localStorage.getItem 'externalTemplateDir'
    typeList = components.templateHelper.getTemplateList tptDir
    componentTypeView.toggle @, typeList

  getComponentName: (compType) ->
    @componentType = compType
    @suggestPath @suggestedPathFromSelection
    @previouslyFocusedElement = $(":focus")
    @pathHistory = []
    @panel = atom.workspace.addModalPanel item: this

    if not @creatingTemplate
      @overwriteLabel.addClass 'hidden'

    @parent(".modal").css({
      "max-height": "100%",
      display: "flex",
      "flex-direction": "column",
    })

    @outsideClickHandler = (event) =>
      if not $(event.target).closest('.statwolf-new-component-plugin').length
        @detach()
    $('html').on 'click', @outsideClickHandler

    @miniEditor.focus()
    @miniEditor.getModel().setCursorScreenPosition [0, 10000], autoscroll: true

    @miniEditor.getModel().onDidChange => @update()

    @miniEditor.focus()
    @getFileList (files) -> @renderAutocompleteList files

  suggestPath: (suggested) ->
    suggestedPath = suggested
    if fs.isFileSync suggestedPath
      suggestedPath = path.dirname suggestedPath
    suggestedPath += path.sep

    @miniEditor.setText suggestedPath

  copyStatwolfPath: (event) ->
    launchPath = @getSelectedComponentFromEvent event
    projectName = 'Statwolf'
    projectPath = localStorage.getItem 'rootPath'

    unless launchPath.split(projectPath)[1]
      atom.notifications.addWarning 'Component path not copied', {detail: 'You selected an invalid Statwolf component.'}

    relativePath = path.sep + projectName + launchPath.split(projectPath)[1]

    if fs.isFileSync launchPath
      relativePath = path.dirname relativePath

    relativePath = relativePath.replace(new RegExp('\\' + path.sep, 'g'), '.').slice 1
    atom.clipboard.write relativePath.split('.').slice(1).join('.')

  getRoot: (inputPath) ->
    lastPath = null
    while inputPath is not lastPath
      lastPath = inputPath
      inputPath = path.dirname inputPath
    return inputPath

  isRoot: (inputPath) ->
    return path.dirname(inputPath) is inputPath

  absolutify: (inputPath) ->
    if @getRoot(inputPath) == '.'
      projectPaths = atom.project.getPaths()
      if projectPaths.length > 0
        return path.join projectPaths[0], inputPath

    absolutePath = path.resolve inputPath
    if inputPath.endsWith path.sep
      return absolutePath + path.sep

    return absolutePath

  toggle: (event) =>
    launchPath = @getSelectedComponentFromEvent event
    if @hasParent()
      @detach()
    else
      @attach launchPath

  getSelectedComponentFromEvent: (event) ->
    target = $(event.target)
    launchPath = target.data('path') or
                 target.find('span').data('path') or
                 target.find('div').data('path')
    return launchPath

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.views.getView(atom.workspace).focus()

  longestCommonPrefix: (fileNames) ->
    if (fileNames?.length == 0)
      return ''

    longestCommonPrefix = ''
    for prefixIndex in [0..fileNames[0].length - 1]
      nextCharacter = fileNames[0][prefixIndex]
      for fileIndex in [0..fileNames.length - 1]
        fileName = fileNames[fileIndex]
        if (fileName.length < prefixIndex || fileName[prefixIndex] != nextCharacter)
          return longestCommonPrefix
      longestCommonPrefix += nextCharacter

    return longestCommonPrefix
