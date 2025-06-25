import ejs        from "ejs"
import fs         from "node:fs"
import path       from "node:path"
import markdownit from "markdown-it"
import Prism      from "prismjs"
import beautify   from "js-beautify"
import Logger     from "./Logger.js"

import loadLanguages from "prismjs/components/index.js"
loadLanguages(["html"])

/** A title has a string usable as a human-readable title, plus a sort key used
 * to sort pages by their title
 */
class Title {
  /** Create a title based on a directory name that may have a prefix used for sorring */
  static fromDirName(dirName) {
    const nameWithoutPrefix = dirName.replace(/^\d+_/, '').replace(/\..*$/,'')
    const title = nameWithoutPrefix.
      split('-').
      map(word => word.charAt(0).toUpperCase() + word.slice(1)).
      join(' ')
    return new this(title, dirName)
  }
  constructor(title, sortKey) {
    this.title = title
    this.sortKey = sortKey
  }
  toString() { return this.title }
  static compare(a,b) {
    if (!a.title) { throw `${a.constructor.name} has no title` }
    if (!b.title) { throw `${b.constructor.name} has no title` }
    if (!a.title.sortKey) { throw `${a.constructor.name} has a title, but it's not a Title` }
    if (!b.title.sortKey) { throw `${b.constructor.name} has a title, but it's not a Title` }
    return a.title.sortKey.localeCompare(b.title.sortKey)
  }
}

/* A page to generate based on a template */
class Page {
  constructor(pathToPageTemplate, pathToPageOutput) {
    this.pathToPageTemplate = pathToPageTemplate
    this.uri = pathToPageOutput
  }

  static compare(a,b) {
    Title.compare(a.page, b.page)
  }
}

/* A static file that isn't being run through EJS */
class StaticFile extends Page {
  get title() {
    return Title.fromDirName(path.basename(this.pathToPageTemplate))
  }
  generate(outputDirName) {
    Logger.info("Copying %s from %s", this.uri, this.pathToPageTemplate)
    fs.copyFileSync(this.pathToPageTemplate, path.join(outputDirName, this.uri))
  }
}

/* A templated page that will be run through EJS */
class TemplatePage extends Page {
  constructor(pathToPageTemplate, pathToPageOutput, pathToPageContent) {
    super(pathToPageTemplate, pathToPageOutput)
    this.pathToPageContent = pathToPageContent
  }
  get title() {
    return Title.fromDirName(path.basename(this.pathToPageContent))
  }
  generate(outputDirName, pathToBrutCSSRoot, nav) {
    Logger.info("Generating %s from %s using %s", this.uri, this.pathToPageTemplate, this.pathToPageContent || "no additional content")
    let htmlContent = null
    if (this.pathToPageContent) {
      const contents = fs.readFileSync(this.pathToPageContent, "utf8")
      if (path.extname(this.pathToPageContent) === ".md") {
        const markdown = new markdownit({
          html: true,
          linkify: true,
          typographer: true,
        })
        htmlContent = markdown.render(contents)
      }
      else if (path.extname(this.pathToPageContent) === ".html") {
        htmlContent = contents
      }
      else {
        throw `Unsupported file type for ${this.pathToPageContent}. Only .md and .html are supported.`
      }
    }
    const html = ejs.render(fs.readFileSync(this.pathToPageTemplate, "utf8"), {
      nav:nav,
      pathToBrutCSSRoot: pathToBrutCSSRoot,
      content: htmlContent || ""
    }, {
      filename: this.pathToPageTemplate
    })
    const destinationFile = path.join(outputDirName, this.uri)
    fs.mkdirSync(path.dirname(destinationFile), { recursive: true })
    fs.writeFileSync(destinationFile, html, "utf8")
    Logger.info("Wrote %s", destinationFile)
  }
}

/* The page used for a category of custom properties */
class PropertiesPage extends TemplatePage {
  constructor(pathToPageContent, pathToPageOutput, category, parsedDocumentation) {
    super(pathToPageContent, pathToPageOutput)
    Logger.debug("Creating PropertiesPage %s for %s", pathToPageContent, category.name)
    this.category = category
    this.colorsCategory  = parsedDocumentation.classCategories.find( (category) => category.ref == "class-category:foreground-colors" )
  }
  get documentationRef() { return this.category.ref }
  get title() { return Title.fromDirName(this.category.name) }
  generate(outputDirName, pathToBrutCSSRoot, nav) {
    const locals = {
      nav:nav,
      pathToBrutCSSRoot: pathToBrutCSSRoot,
      category: this.category,
    }
    if ( (this.category.ref == "class-category:foreground-colors") ||
         (this.category.ref == "class-category:background-colors") ||
         (this.category.ref == "class-category:border-colors") ) {
      locals.colorsCategory = this.colorsCategory
    }

    const html = ejs.render(fs.readFileSync(this.pathToPageTemplate, "utf8"),
      locals,
      {
        filename: this.pathToPageTemplate
      })
    const destinationFile = path.join(outputDirName, this.uri)
    fs.mkdirSync(path.dirname(destinationFile), { recursive: true })
    fs.writeFileSync(destinationFile, html, "utf8")
    Logger.debug("Wrote %s", destinationFile)
  }
}

/* The page used for a category of CSS classe */
class ClassesPage extends PropertiesPage {
}

/* A section of the nav, which is a title and a bunch of pages it links to */
class NavSection {
  static fromPath(sourcePath, parsedDocumentation) {
    const basename = path.basename(sourcePath)
    if (basename.match(/^\d+_properties$/)) {
      return new PropertiesSection(sourcePath, parsedDocumentation)
    }
    if (basename.match(/^\d+_classes/)) {
      return new ClassesSection(sourcePath, parsedDocumentation)
    }
    return new StaticPagesSection(sourcePath)
  }
}

/* The section of the nav for custom properties */
class PropertiesSection extends NavSection {
  constructor(sourcePath, parsedDocumentation) {
    super()
    this.categoryTemplate = path.join(sourcePath, "page.html.ejs")
    if (!fs.existsSync(this.categoryTemplate)) {
      throw `No category template found at ${this.categoryTemplate}`
    }
    this.parsedDocumentation = parsedDocumentation
    const basename = path.basename(sourcePath)
    this.uriBase = basename.replace(/^\d+_/,"")
    this.title = Title.fromDirName(basename)
  }
  get items() {
    return this.parsedDocumentation.propertyCategories.map( (category) => {
      return {
        page: new PropertiesPage(
          this.categoryTemplate,
          path.join(this.uriBase, category.name) + ".html",
          category,
          this.parsedDocumentation,
        )
      }
    })
  }
}

/* The section of the nav for CSS classes */
class ClassesSection extends PropertiesSection {

  get items() {
    return this.parsedDocumentation.classCategories.map( (category) => {
      return {
        page: new ClassesPage(
          this.categoryTemplate,
          path.join(this.uriBase, category.name) + ".html",
          category,
          this.parsedDocumentation)
      }
    })
  }
}

/* A section of static pages not based on API docs, but that will be run through EJS */
class StaticPagesSection extends NavSection {
  constructor(sourcePath) {
    super()
    this.sourcePath = sourcePath
    this.pageTemplate = path.join(sourcePath, "page.html.ejs")
    if (!fs.existsSync(this.pageTemplate)) {
      throw `No category template found at ${this.pageTemplate}`
    }

    const basename = path.basename(sourcePath)
    this.title = Title.fromDirName(basename)

    this.items = []

    fs.readdirSync(sourcePath).forEach((file) => {
      const fullPath = path.join(sourcePath, file)
      const stat = fs.statSync(fullPath)
      if (stat.isDirectory()) {
        throw `${fullPath} is a directroy. ${sourcePath} may only includes files`
      }
      if (file != "page.html.ejs") {
        const pathToPageOutput = path.join(
          ...path.join(basename, file).split(path.sep).map( (part) => {
            return part.replace(/^\d+_/,"").replace(/\..*$/,".html")
          })
        )
        this.items.push({
          page: new TemplatePage(this.pageTemplate, pathToPageOutput, fullPath)
        })
      }
    })
    this.items.sort(Page.compare)
  }
}

/* Given the description parsed from the source, this expands it to HTML and also
 * locates all cross-references.
 */
class ExpandedDescription {
  constructor(documentedEntry, documentationRefs, pathToBrutCSSRoot) {
    const unexpandedDescription = documentedEntry.description || ""

    this.doc = unexpandedDescription.replace(/\{([^}]+)\}/g, (_, key) => {
      const reference = key.trim()
      let referenced = documentationRefs.refs[reference]
      if (!referenced) {
        throw new Error(`Could not find reference to ${reference} in documentation`)
      }
      return `[${referenced.title}](${pathToBrutCSSRoot}/${referenced.uri})`
    })
  }
  toHTML() {
    const markdown = new markdownit({
      html: true,
      linkify: true,
      typographer: true,
    })
    return markdown.render(this.doc)
  }
}
class ExpandedSee {
  constructor(see, documentationRefs, pathToBrutCSSRoot) {
    if (see.ref) {
      let referenced = documentationRefs.refs[see.ref]
      if (!referenced) {
        const [part,rest] = see.ref.split(":",2)
        const candidates = Object.keys(documentationRefs).filter( (key) => key.startsWith(part) )
        throw new Error(`Could not find reference to ${see.ref} in documentation ${ candidates }`)
      }
      this.doc = `[${referenced.title}](${pathToBrutCSSRoot}/${referenced.uri})`
    }
    else {
      this.doc = `[${see.linkText}](${see.url}) (external)`
    }
  }
  toHTML() {
    const markdown = new markdownit({
      html: true,
      linkify: true,
      typographer: true,
    })
    return markdown.render(this.doc)
  }
}

class Documentation {
  constructor(templateRootDirName, parsedDocumentation, pathToBrutCSSRoot) {
    const nav = []
    const pages = []
    fs.readdirSync(templateRootDirName).forEach((file) => {
      const fullPath = path.join(templateRootDirName, file)
      const stat = fs.statSync(fullPath)
      if (stat.isDirectory()) {
        if (file != "includes") {
          nav.push(NavSection.fromPath(fullPath, parsedDocumentation))
        }
      }
      else {
        if (this.#isEJS(file)) {
          pages.push(new TemplatePage(
            fullPath,
            file.replace(/^\d+_/,"").replace(/\..*$/,".html")
          ))
        }
        else {
          pages.push(new StaticFile(
            fullPath,
            file
          ))
        }
      }
    })
    nav.sort(Title.compare)
    this.nav = nav
    this.pages = pages
    this.#decorate(parsedDocumentation, pathToBrutCSSRoot)
  }

  #isEJS(file) {
    return path.extname(file) === ".ejs"
  }

  #decorate(parsedDocumentation, pathToBrutCSSRoot) {
    this.#addTitles(parsedDocumentation)
    this.#expandReferences(parsedDocumentation, pathToBrutCSSRoot)
    this.#highlightCode(parsedDocumentation)
  }

  #highlightCode(parsedDocumentation) {
    parsedDocumentation.classCategories.forEach( (category) => {
      category.scales.forEach( (scale) => {
        scale.rules.forEach( (rule) => {
          rule.highlightedCode = Prism.highlight(
            rule.code,
            Prism.languages.css,
            "css"
          )
          rule.examples.forEach( (example) => {
            const prettyHTML = beautify.html(example.code.join("\n"), {
              wrap_line_length: 60,
              indent_size: 2,
            })
            example.highlightedCode = Prism.highlight(
              prettyHTML,
              Prism.languages.html,
              "html"
            )
          })
        })
      })
    })
  }

  #expandReferences(parsedDocumentation, pathToBrutCSSRoot) {
    const referencedDocumentation = new ReferencedDocumentation(this)
    parsedDocumentation.propertyCategories.forEach( (category) => {
      category.descriptionHTML = (new ExpandedDescription(category, referencedDocumentation, pathToBrutCSSRoot)).toHTML()
      category.seeLinks = category.sees.map( (see) => (new ExpandedSee(see, referencedDocumentation, pathToBrutCSSRoot)).toHTML() )
      category.scales.forEach( (scale) => {
        scale.descriptionHTML = (new ExpandedDescription(scale, referencedDocumentation, pathToBrutCSSRoot)).toHTML()
        scale.seeLinks = scale.sees.map( (see) => (new ExpandedSee(see, referencedDocumentation, pathToBrutCSSRoot)).toHTML() )
        if (!scale.name) {
          throw new Error(`Scale ${scale.ref}.${scale.constructor.name} has no name`)
        }
        scale.properties.forEach( (property) => {
          property.descriptionHTML = (new ExpandedDescription(property, referencedDocumentation, pathToBrutCSSRoot)).toHTML()
          property.seeLinks = property.sees.map( (see) => (new ExpandedSee(see, referencedDocumentation, pathToBrutCSSRoot)).toHTML() )
        })
      })
    })
    parsedDocumentation.classCategories.forEach( (category) => {
      category.descriptionHTML = (new ExpandedDescription(category, referencedDocumentation, pathToBrutCSSRoot)).toHTML()
      category.seeLinks = category.sees.map( (see) => (new ExpandedSee(see, referencedDocumentation, pathToBrutCSSRoot)).toHTML() )
      category.scales.forEach( (scale) => {
        scale.descriptionHTML = (new ExpandedDescription(scale, referencedDocumentation, pathToBrutCSSRoot)).toHTML()
        scale.seeLinks = scale.sees.map( (see) => (new ExpandedSee(see, referencedDocumentation, pathToBrutCSSRoot)).toHTML() )
        scale.rules.forEach( (rule) => {
          rule.descriptionHTML = (new ExpandedDescription(rule, referencedDocumentation, pathToBrutCSSRoot)).toHTML()
          rule.seeLinks = rule.sees.map( (see) => (new ExpandedSee(see, referencedDocumentation, pathToBrutCSSRoot)).toHTML() )
        })
      })
    })
  }

  #addTitles(parsedDocumentation) {
    parsedDocumentation.propertyCategories.forEach( (category) => {
      category.title = category.explicitTitle || category.name.split(/-/).map( (part) => {
        return part.charAt(0).toUpperCase() + part.slice(1)
      }).join(" ")
      category.scales.forEach( (scale) => {
        if (!scale.name) {
          throw `Scale ${scale.ref}.${JSON.stringify(scale)} has no name`
        }
        scale.title = scale.explicitTitle || scale.name.split(/-/).map( (part) => {
          return part.charAt(0).toUpperCase() + part.slice(1)
        }).join(" ")
      })
    })
    parsedDocumentation.classCategories.forEach( (category) => {
      category.title = category.explicitTitle || category.name.split(/-/).map( (part) => {
        return part.charAt(0).toUpperCase() + part.slice(1)
      }).join(" ")
      category.scales.forEach( (scale) => {
        scale.title = scale.explicitTitle || scale.name.split(/-/).map( (part) => {
          return part.charAt(0).toUpperCase() + part.slice(1)
        }).join(" ")
      })
    })
  }
}

class ReferencedDocumentation {
  constructor(documentation) {
    this.refs = {}
    documentation.nav.forEach( (navSection) => {
      navSection.items.forEach( ({page}) => {
        if (page.documentationRef) {
          this.refs[page.documentationRef] = page
          if (page.category) {
            page.category.scales.forEach( (scale) => {
              this.refs[scale.ref] = {
                title: new Title(scale.title, scale.name),
                uri: page.uri + `#${scale.ref}`
              }
              if (scale.properties) {
                scale.properties.forEach( (property) => {
                  this.refs[property.ref] = {
                    title: new Title("`" + property.name + "`", property.name),
                    uri: page.uri + `#${property.ref}`
                  }
                })
              }
              else if (scale.rules) {
                scale.rules.forEach( (rule) => {
                  this.refs[rule.ref] = {
                    title: new Title("`" + rule.selector + "`", rule.selector),
                    uri: page.uri + `#${rule.ref}`
                  }
                })
              }
            })
          }
          else {
            throw `No category for ${page.documentationRef} / ${page.constructor.name}`
          }
        }
        else {
          Logger.info("Skipping %s because it has no documentation reference", page.uri)
        }
      })
    })
  }
}

const docGenerator = (outputDirName, templateDirName, parsedDocumentation, pathToBrutCSSRoot) => {
  const documentation = new Documentation(templateDirName, parsedDocumentation, pathToBrutCSSRoot)

  documentation.pages.forEach( page => page.generate(outputDirName, pathToBrutCSSRoot, documentation.nav) )

  documentation.nav.forEach( (navSection) => {
    navSection.items.forEach( ({page}) => {
      page.generate(outputDirName, pathToBrutCSSRoot, documentation.nav)
    })
  })
}

export default docGenerator
