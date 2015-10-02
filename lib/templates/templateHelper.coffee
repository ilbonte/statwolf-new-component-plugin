fs = require 'fs-plus'
path = require 'path'

baseFile =
  extension: null

meta =
  extension: '.meta.json'

dependencies =
  extension: '.deps.js'
  content: '{}'

types =
  'form': 'DashboardForm'
  'fullForm': 'DashboardForm'
  'service': 'DashboardService'
  'model': 'DashboardModel'
  'controlTemplate': 'DashboardTemplate'
  'view': 'DashboardView'
  'controller': 'DashboardController'
  'pythonScript': 'DashboardScript'
  'rScript': 'DashboardScript'

module.exports =

  getTemplates: (componentType, componentName) ->
    files = []
    meta.content = '{ "ComponentType": "' + types[componentType] + '", "Name": "' + componentName + '" }'

    switch componentType
      when 'form'
        # baseFile.extension = '.bindings.json'
        # baseFile.content = fs.readFileSync(path.join __dirname, 'Form.json').toString()

        resolver =
          extension: '.js'
          content: fs.readFileSync(path.join __dirname, 'FormResolver.js').toString()
        files.push resolver

      when 'fullForm'
        console.log 'full form requested'

      when 'service'
        # baseFile.extension = '.js'
        # baseFile.content = fs.readFileSync(path.join __dirname, 'Service.js').toString()

        # files.push dependencies

      when 'model'
        # baseFile.extension = '.js'
        # baseFile.content = fs.readFileSync(path.join __dirname, 'Model.json').toString()
        # files.push baseFile

      when 'view'
        # baseFile.extension = '.js'
        # baseFile.content = fs.readFileSync(path.join __dirname, 'View.json').toString()

        # files.push dependencies

      when 'controller'
        # baseFile.extension = '.js'
        # baseFile.content = fs.readFileSync(path.join __dirname, 'Controller.json').toString()

        # files.push dependencies

      when 'controlTemplate'
        # baseFile.extension = '.js'
        # baseFile.content = fs.readFileSync(path.join __dirname, 'ControlTemplateDirective.js').toString()

        # files.push dependencies

        # template =
          # extension: '.template.html'
          # content: fs.readFileSync(path.join __dirname, 'ControlTemplateTemplate.html').toString()
        # files.push template

      when 'pythonScript'
        baseFile.extension = '.py'
        baseFile.content = ''

        files.push dependencies

      when 'rScript'
        baseFile.extension = '.r'
        baseFile.content = ''

        files.push dependencies

      else

    files.push baseFile
    files.push meta
    return files
