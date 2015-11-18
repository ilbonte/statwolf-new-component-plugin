{$, $$, View, TextEditorView, ScrollView} = require "atom-space-pen-views"

path = require 'path'

module.exports =
class DirectoryListView extends ScrollView

  @content: ->
    @ul class: 'list-group', outlet: 'directoryList'

  renderFiles: (files, showParent) ->
    @empty()

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
