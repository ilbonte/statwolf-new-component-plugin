_ = require 'underscore-plus'
{SelectListView, $, $$} = require 'atom-space-pen-views'
{match} = require 'fuzzaldrin'
fuzzaldrinPlus = require 'fuzzaldrin-plus'

module.exports =
class ComponentTypeView extends SelectListView

  @activate: () ->
    view = new ComponentTypeView

  @deactivate: ->
    @disposable.dispose()

  initialize: ->
    super
    @addClass('component-type')

  getFilterKey: ->
    'displayName'

  cancelled: -> @hide()

  toggle: (owner) ->
    if @panel?.isVisible()
      @cancel()
    else
      @owner = owner
      @show()

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()

    @storeFocusedElement()

    if @previouslyFocusedElement[0] and @previouslyFocusedElement[0] isnt document.body
      @eventElement = @previouslyFocusedElement[0]
    else
      @eventElement = atom.views.getView(atom.workspace)

    componentTypes = []
    componentTypes[0] =
      displayName: 'Form'
      name: 'form'
    componentTypes[1] =
      displayName: 'Full Form'
      name: 'fullForm'
    componentTypes[2] =
      displayName: 'Serevice'
      name: 'service'
    componentTypes[3] =
      displayName: 'Model'
      name: 'model'
    componentTypes[4] =
      displayName: 'View'
      name: 'view'
    componentTypes[5] =
      displayName: 'Controller'
      name: 'controller'
    componentTypes[6] =
      displayName: 'Control Template'
      name: 'controlTemplate'
    componentTypes[7] =
      displayName: 'Python Script'
      name: 'pythonScript'
    componentTypes[8] =
      displayName: 'R Script'
      name: 'rScript'

    componentTypes = _.sortBy componentTypes, 'displayName'

    @setItems componentTypes

    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  viewForItem: ({name, displayName, eventDescription}) ->
    filterQuery = @getFilterQuery()
    matches = match(displayName, filterQuery)

    $$ ->
      highlighter = (command, matches, offsetIndex) =>
        lastIndex = 0
        matchedChars = [] # Build up a set of matched chars to be more semantic

        for matchIndex in matches
          matchIndex -= offsetIndex
          continue if matchIndex < 0 # If marking up the basename, omit command matches
          unmatched = command.substring(lastIndex, matchIndex)
          if unmatched
            @span matchedChars.join(''), class: 'character-match' if matchedChars.length
            matchedChars = []
            @text unmatched
          matchedChars.push(command[matchIndex])
          lastIndex = matchIndex + 1

        @span matchedChars.join(''), class: 'character-match' if matchedChars.length

        # Remaining characters are plain text
        @text command.substring(lastIndex)

      @li class: 'event', 'data-event-name': name, =>
        @div class: 'pull-right', =>
        @span title: name, -> highlighter(displayName, matches, 0)

  confirmed: ({name}) ->
    @cancel()
    @owner.getComponentName name

  populateList: ->
    super

  # This is modified copy/paste from SelectListView#populateList, require jQuery!
  # Should be temporary
  populateAlternateList: ->

    return unless @items?

    filterQuery = @getFilterQuery()
    if filterQuery.length
      filteredItems = fuzzaldrinPlus.filter(@items, filterQuery, key: @getFilterKey())
    else
      filteredItems = @items

    @list.empty()
    if filteredItems.length
      @setError(null)

      for i in [0...Math.min(filteredItems.length, @maxItems)]
        item = filteredItems[i]
        itemView = $(@viewForItem(item))
        itemView.data('select-list-item', item)
        @list.append(itemView)

      @selectItemView(@list.find('li:first'))
    else
      @setError(@getEmptyMessage(@items.length, filteredItems.length))
