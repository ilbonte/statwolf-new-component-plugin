StatwolfNewComponentPluginView = require '../lib/statwolf-new-component-plugin-view'
{$} = require 'atom-space-pen-views'
fs = require 'fs-plus'
path = require 'path'

describe "StatwolfNewComponentPluginView", ->

  workspaceElement  = null
  swComponentPlugin = null
  testPath = null

  beforeEach ->
    workspaceElement = atom.views.getView atom.workspace
    swComponentPlugin = new StatwolfNewComponentPluginView()

    waitsForPromise ->
     atom.packages.activatePackage 'statwolf-new-component-plugin'

    runs ->
      atom.packages.emitter.emit 'did-activate-all'
      jasmine.attachToDOM workspaceElement
      testPath = atom.packages.getActivePackage('statwolf-new-component-plugin').path + path.sep + 'spec' + path.sep + 'Test' + path.sep + 'TestComponent'
      fs.removeSync path.dirname testPath

  afterEach ->
    fs.removeSync path.dirname testPath
    swComponentPlugin = null


  describe 'when commands are triggered from the menu', ->
    it 'should attach and detach the events', ->
      expect($('statwolf-new-component-plugin')).not.toExist()

      atom.commands.dispatch workspaceElement, 'statwolf-new-component-plugin:toggleFullForm'
      expect($('.statwolf-new-component-plugin')).toExist()


  describe 'when a new component is required to be created', ->
    it 'should properly create a form', ->
      swComponentPlugin.componentType = 'form'
      swComponentPlugin.openOrCreate testPath

      expect(fs.existsSync testPath + path.sep + 'TestComponent.js').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.bindings.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.meta.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.deps.json').toBe false
      expect(fs.existsSync testPath + path.sep + 'TestComponent.test.js').toBe true

    it 'should properly create a service', ->
      swComponentPlugin.componentType = 'service'
      swComponentPlugin.openOrCreate testPath

      expect(fs.existsSync testPath + path.sep + 'TestComponent.js').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.meta.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.deps.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.test.js').toBe true

    it 'should properly create a model', ->
      swComponentPlugin.componentType = 'model'
      swComponentPlugin.openOrCreate testPath

      expect(fs.existsSync testPath + path.sep + 'TestComponent.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.meta.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.deps.json').toBe false
      expect(fs.existsSync testPath + path.sep + 'TestComponent.test.js').toBe true

    it 'should properly create a control template', ->
      swComponentPlugin.componentType = 'controlTemplate'
      swComponentPlugin.openOrCreate testPath

      expect(fs.existsSync testPath + path.sep + 'TestComponent.js').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.meta.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.deps.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.template.html').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.test.js').toBe true

    it 'should properly create a view', ->
      swComponentPlugin.componentType = 'view'
      swComponentPlugin.openOrCreate testPath

      expect(fs.existsSync testPath + path.sep + 'TestComponent.js').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.meta.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.deps.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.test.js').toBe true

    it 'should properly create a controller', ->
      swComponentPlugin.componentType = 'controller'
      swComponentPlugin.openOrCreate testPath

      expect(fs.existsSync testPath + path.sep + 'TestComponent.js').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.meta.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.deps.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.test.js').toBe true

    it 'should properly create a python script', ->
      swComponentPlugin.componentType = 'pythonScript'
      swComponentPlugin.openOrCreate testPath

      expect(fs.existsSync testPath + path.sep + 'TestComponent.py').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.meta.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.deps.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.test.js').toBe true

    it 'should properly create an R script', ->
      swComponentPlugin.componentType = 'rScript'
      swComponentPlugin.openOrCreate testPath

      expect(fs.existsSync testPath + path.sep + 'TestComponent.r').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.meta.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.deps.json').toBe true
      expect(fs.existsSync testPath + path.sep + 'TestComponent.test.js').toBe true

    it 'should throw an error if the path is not specified', ->
      expect(swComponentPlugin.openOrCreate).toThrow(new Error 'this.absolutify is not a function')

    it 'should return an error message if an invalid path is specified', ->
      swComponentPlugin.componentType = 'form'
      fs.writeFileSync path.dirname(testPath) + path.sep + 'someFile', 'some stuff'
      outcome = swComponentPlugin.openOrCreate testPath

      expect(outcome).toEqual 'Invalid path specified.'
      expect(fs.existsSync testPath + path.sep + 'TestComponent.js').toBe false

    it 'should do something if the type is not specified', ->
      outcome = swComponentPlugin.openOrCreate testPath
      expect(outcome).toEqual 'Component type not provided.'
      expect(fs.existsSync testPath + path.sep + 'TestComponent.js').toBe false
