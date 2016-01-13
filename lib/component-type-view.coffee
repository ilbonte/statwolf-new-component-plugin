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
    @addClass 'component-type'

  getFilterKey: ->
    'displayName'

  cancelled: ->
    @hide()

  toggle: (owner, componentList) ->
    if @panel?.isVisible()
      @cancel()
    else
      @owner = owner
      @componentList = componentList
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
    @componentList.forEach (item, index) ->
      displayName = item.replace(/([A-Z])/g, ' $1')
                        .replace /^./, (str) -> return str.toUpperCase()
      componentTypes.push {name: item, displayName: displayName}
    @componentTypes = _.sortBy @componentTypes, 'name'

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
