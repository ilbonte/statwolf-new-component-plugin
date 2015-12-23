# statwolf-new-component-plugin
[![Build Status](https://img.shields.io/travis/Statwolf/statwolf-new-component-plugin.svg?style=flat-square)](https://travis-ci.org/Statwolf/statwolf-new-component-plugin)
[![Dependencies!](https://img.shields.io/david/Statwolf/statwolf-new-component-plugin.svg?style=flat-square)](https://david-dm.org/Statwolf/statwolf-new-component-plugin)
[![Package version!](https://img.shields.io/apm/v/statwolf-new-component-plugin.svg?style=flat-square)](https://atom.io/packages/statwolf-new-component-plugin)

This package allows to create new components based on custom `Handlebars`
templates.

## Usage
The package provides in the tree view menu a new item, which is, *Create new SW
components*. From here the default components are available:

* form
* service
* model
* view
* controller
* control template
* script (python or r)
* full form

When creating a new component, the package checks for the directory where the
action is invoked: any directory which is not empty **will not work**, since
components are supposed to be isolated and atomic entities.

### New components
A new component will be composed by several file. Files may change according to
the required component type, still some of them are pretty popular:

* `[componentName].meta.json` contains some metadata about the component
* `[componentName].deps.json` contains the component dependencies

![New Component](https://raw.githubusercontent.com/Statwolf/statwolf-new-component-plugin/type-selection/images/componentType.gif)

### Statwolf path
Another feature offered by the package is to copy the Statwolf path of any component
within the project. The Statwolf path is relative to the project and uses the dot
as separator.

### Component view
When exploding the component view, a panel will be open, containing the meta info
related to that component.

### Templates
Another feature provided by this package is the interface with the `statwolf-components`
node module. This allows to import new template to the install folder of the npm
package, so that they can be used when creating new components.

In the navigation bar, the option `Packages -> Statwolf -> Add new template` will open
the selection view for the template list. It expects the template list to be a
valid JSON file containing an array with all the new templates to add. The template
folders should exist at the same level of the template list.

A valid template list looks like this:

```
{
  "templates": [
    "template1",
    "template2",
    "template3"
  ]
}
```

After the new templates are added, they become available when creating a new component.

#### Creating a template
New templates should contain at least one file named `templateName.json.hbs`, that
is, a JSON file that can use the Handlebars syntax. This file should contain an
array of all files that the template engine should create. An example of template is
this:

```
[
  {
    "fileName": "{{name}}.js",
    "fileContent": "component.js"
  },
  {
    "fileName": "{{name}}.meta.json",
    "fileContent": {
      "ComponentType": "AwesomeComponent",
      "Name": "{{name}}"
    }
  }
]
```

In this case, when the template engine has to create a component of this type, it
will get the component name (let's say, `ComponentName`) and generate three
different files:
* a file named `ComponentName.js`, for which the content will be fetched from the
file `component.js` in the template folder (it has to be provided!)
* a file named `ComponentName.meta.json` containing the JSON included in the `fileContent`
property

In the provided example, the template engine will create a component composed by
two files. The first file content is specified in an external file, the second file
content is specified as JSON in the template file itself.
