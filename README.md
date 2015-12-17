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
