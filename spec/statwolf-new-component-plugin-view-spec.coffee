StatwolfNewComponentPluginView = require '../lib/statwolf-new-component-plugin-view'

describe "StatwolfNewComponentPluginView", ->

  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    waitsForPromise ->
     atom.packages.activatePackage('statwolf-new-component-plugin')

  describe 'when commands are triggered from the menu', ->

    it 'should attach and detach the events', ->
      expect(workspaceElement.querySelector('statwolf-new-component-plugin')).not.toExist()

      atom.commands.dispatch workspaceElement, 'statwolf-new-component-plugin:toggleFullForm'
      expect(workspaceElement.querySelector('statwolf-new-component-plugin')).toExist()
