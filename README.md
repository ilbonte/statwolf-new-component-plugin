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
Another feature offered by the package is to copy the Statwolf path of any
component within the project. The Statwolf path is relative to the project and
uses the dot as separator.

### Component view
When exploding the component view, a panel will be open, containing the meta
info related to that component.

### Templates
Another feature provided by this package is the interface with the
`statwolf-components` node module. This allows to import new template to the
install folder of the npm package, so that they can be used when creating new
components.

In the navigation bar, the option `Packages -> Statwolf -> Add new template`
will open the selection view for the template list. It expects the template list
to be a valid JSON file containing an array with all the new templates to add.
The template folders should exist at the same level of the template list.

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

After the new templates are added, they become available when creating a new
component.

When selecting the template list location in Atom, it is possible to specify
whether to overwrite the existing templates, in case some freshly imported
template already exists in the destination folder.

Another way to sync templates with the package is simply copy the template
folders in the configured template directory (see atom configurations for
editing this location).

#### Creating a template
New templates can be composed by as many files as needed. When creating a new
template, each file name can be a string that will be parsed by Handlebars.

As an example, let's consider the Full Form template. It is composed by this
file structure:

```
model
└───{{name}}
    ├───{{name}}
    │   │   {{name}}.json
    │   │   {{name}}.meta.json
    │   │   {{name}}.bindings.json
    │   │   {{name}}.test.js
    │
    ├───{{name}}Controller
    │   │   {{name}}Controller.js
    │   │   {{name}}Controller.deps.json
    │   │   {{name}}Controller.meta.json
    │   │   {{name}}Controller.test.js
    │
    ├───{{name}}Model
    │   │   {{name}}Model.json
    │   │   {{name}}Model.meta.json
    │   │   {{name}}Model.test.js
    │
    ├───{{name}}Service
    │   │   {{name}}Service.js
    │   │   {{name}}Service.deps.json
    │   │   {{name}}Service.meta.json
    │   │   {{name}}Service.test.js
    │
    ├───{{name}}View
    │   │   {{name}}View.js
    │   │   {{name}}View.deps.json
    │   │   {{name}}View.meta.json
    │   │   {{name}}View.test.js
```

Each file can contain some template content that will be parsed by Handlebars,
or just static content. In the Full Form example, Atom will invoke the template
engine with a `name` variable, along with many others provided in the context
object: those variables will be used when parsing the template.

The template engine also provides some helpers that can perform basic operations.
In the example, `pathSep` is an helper that just returns the path separator in
the current environment (either `/` or `\`). Other helpers are:

- `json` returns the stringified version of an object
- `swPath` returns the Statwolf representation of a path (using the dot as separator)
- `joinPath` returns the concatenation of the arguments with the system path separator
 (it should be invoked like this: `{{joinPath 'first second third'}}` and will
 produce `first/second/third`)

### Snippets
New components may carry with them some snippet templates in their meta files.
If this is the case, the package can fetch those snippets, compile them with
Handlebars and paste them where required.

When working with a component, `ctrl-alt-v` will show a list view where the user
can pick the snippet that will be pasted in the buffer. Alternatively, the user can
right click on any component folder or component file in the tree view and select
**Get component snippets** and the list view will be shown.

When parsing a snippet, some information is passed to it. That is:

- `hostname`: the hostname currently active
- `port`: the port currently active
- `userId`: the user currently active
- `componentName`: the name of the component that triggered the snippet
- `internalPath`: the Statwolf representation of the component path

### Navigation
When working with code, it is possible to automatically open a component if its
Statwolf path is written in a quoted text, both with:

- the default keybinding `ctrl-alt-n`
- double clicking on the quoted text itself

A string that can trigger the navigation can be in the forms:

```
'Statwolf.Component.Internal.Path'
"Statwolf.Another.Great.Path"
```

Please consider that the navigation feature **requires the cursor to be placed
in the string to jump into**.

If the component does not exist, Atom will notify the user with a warning popup.

![Warning](https://raw.githubusercontent.com/Statwolf/statwolf-new-component-plugin/master/images/navigateWarning.png)
