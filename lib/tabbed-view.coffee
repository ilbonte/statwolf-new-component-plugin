{CompositeDisposable} = require 'atom'
{TextEditorView, View} = require 'atom-space-pen-views'

path = require 'path'
fs   = require 'fs-plus'

module.exports =
class TabbedView extends View

  componentPath: null
  componentName: null
  componentType: null
  extraFilePath: null
  extraFileCtnt: null

  @content: (params) ->
    @div outlet: 'main_container', class: 'component-box padded pane-item', tabindex: -1, =>
      @span click: 'toggle', class: 'icon icon-x close-icon'
      @h2 outlet: 'componentNameHeader'

      fullName = params.componentPath + path.sep + path.basename params.componentPath
      isDependency = fs.existsSync(fullName + '.deps.json')
      isResolver = fs.existsSync(fullName + '.resolver.js')

      if isDependency or isResolver
        label = if isDependency then 'Dependencies' else 'Resolver'
        @div =>
          @div =>
            @label "#{label}", class: 'text-highlight'
            @subview 'extraView', new TextEditorView(mini: true, placeholderText: '...')
            @div class: "btn-group", =>
              @button outlet: 'openButton', click: 'openExtra', class: 'btn btn-sm btn-primary', 'Open in new tab'
              @button outlet: 'saveButton', click: 'saveExtra', class: 'btn btn-sm disabled', 'Save changes'

  initialize: (serializeState) ->
    if @extraView
      atom.commands.add @extraView.element,
        'core:close': => @close()
        'core:cancel': => @close()
        'core:save': => @saveExtra()

  open: ->
    @panel = atom.workspace.addBottomPanel(item: this) unless @hasParent()
    @componentName = path.basename @componentPath
    files = fs.listSync @componentPath
    for file in files
      continue if file.indexOf('.meta.json') != -1 or
                  file.indexOf('.resolver.js') != -1 or
                  file.indexOf('.deps.json') != -1
      if path.extname(file) is '.js' or path.extname(file) is '.json'
        atom.workspace.open file
        .then (editor) =>
          editor.onDidDestroy () => @close()
    @populateInfo()
    unless @extraView
      return
    @extraView.focus()
    @extraView.model.onDidChange () =>
      @enableForSaving()

  close: ->
    @componentType = null
    @componentName = null
    @componentPath = null
    @componentNameHeader.text ''
    @detach()
    @panel.destroy()

  populateInfo: () ->
    @getComponentType()
    @componentNameHeader.append @componentName + ' - ' + @componentType
    @setExtraFilePath()
    if @hasDependencies() or @hasResolver()
      @populateExtra()

  openExtra: () ->
    if @extraFilePath
      atom.workspace.open @extraFilePath

  saveExtra: () ->
    if @extraFilePath
      toBeSaved = @extraView.getText()
      @extraFileCtnt = @extraView.getText()
      fs.writeFileSync @extraFilePath, toBeSaved
      @toggleSaveButton false

  setExtraFilePath: () ->
    if @hasDependencies()
      @extraFilePath = @componentPath + path.sep + @componentName + '.deps.json'
    else if @hasResolver()
      @extraFilePath = @componentPath + path.sep + @componentName + '.resolver.js'

  hasDependencies: () ->
    return fs.existsSync @componentPath + path.sep + @componentName + '.deps.json'

  hasResolver: () ->
    return fs.existsSync @componentPath + path.sep + @componentName + '.resolver.js'

  getComponentType: () ->
    metaFile = fs.readFileSync @componentPath + path.sep + @componentName + '.meta.json'
    unless metaFile
      return

    meta = JSON.parse metaFile
    @componentType = meta.ComponentType

  populateMeta: (type) ->
    @componentTitle.append type

  toggleSaveButton: (enable) ->
    if enable
      @saveButton.addClass 'btn-success'
      @saveButton.removeClass 'disabled'
    else
      @saveButton.removeClass 'btn-success'
      @saveButton.addClass 'disabled'

  enableForSaving: () ->
    unless @saveButton
      return
    @toggleSaveButton @extraView.getText() != @extraFileCtnt

  populateExtra: (deps) ->
    if @hasDependencies()
      extra = fs.readFileSync @componentPath + path.sep + @componentName + '.deps.json'
    else if @hasResolver()
      extra = fs.readFileSync @componentPath + path.sep + @componentName + '.resolver.js'

    @extraView.setText extra.toString()
    @extraFileCtnt = extra.toString()

  toggle: ->
    if @hasParent()
      @close()
    else
      @open()
