fs = require 'fs-plus'
path = require 'path'

baseFile =
  extension: null

meta =
  extension: '.meta.json'

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
        baseFile.extension = '.bindings.json'
        baseFile.content = fs.readFileSync(path.join __dirname, 'Form.json').toString()
        files.push baseFile

        resolver =
          extension: '.js'
          content: fs.readFileSync(path.join __dirname, 'FormResolver.js').toString()
        files.push resolver

        files.push meta

      when 'fullForm'
      else

    return files
