_ = require 'underscore-plus'
{SelectListView, $, $$} = require 'atom-space-pen-views'
{match} = require 'fuzzaldrin'
fuzzaldrinPlus = require 'fuzzaldrin-plus'

module.exports =
class SnippetListView extends SelectListView

  @activate: () ->
    view = new SnippetListView

  @deactivate: ->
    @disposable.dispose()

  getFilterKey: ->
    'name'

  cancelled: ->
    @hide()

  toggle: (owner, snippets) ->
    if @panel?.isVisible()
      @cancel()
    else
      @owner = owner
      @snippets = snippets
      @show()

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()

    @storeFocusedElement()

    if @previouslyFocusedElement[0] and @previouslyFocusedElement[0] isnt document.body
      @eventElement = @previouslyFocusedElement[0]
    else
      @eventElement = atom.views.getView atom.workspace

    snippetList = []
    @previews = []
    @snippets.forEach (item, index) =>
      bodyPreview = item.body
      if bodyPreview.length > 25
        bodyPreview = bodyPreview.slice(0, 22) + '...'
      snippetList.push {name: item.title, body: item.body}
      @previews.push bodyPreview
    snippetList = _.sortBy snippetList, 'name'

    @setItems snippetList

    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  viewForItem: ({name, body, eventDescription}) ->
    $$ ->
      @li class: 'event', 'data-event-name': name, =>
        @div class: 'pull-right', =>
          bodyPreview = if body.length < 25 then body else body.slice(0, 22) + '...'
          @span "#{bodyPreview}"
        @span "#{name}"

  confirmed: ({name, body}) ->
    @cancel()
    @owner.pasteSnippetIntoEditor body
