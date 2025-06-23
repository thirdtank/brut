import ejs from "ejs"
import fs from "node:fs"
import path from "node:path"
import markdownit from "markdown-it"

class Title {
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
}

class Page {
  constructor(pathToPageTemplate, pathToPageContent, pathToPageOutput) {
    this.pathToPageTemplate = pathToPageTemplate
    this.pathToPageContent = pathToPageContent
    this.uri = pathToPageOutput
  }
  get title() {
    return Title.fromDirName(path.basename(this.pathToPageContent))
  }
  static compare(a,b) { return a.title.sortKey.localeCompare(b.title.sortKey) }

  generate(outputDirName, nav) {
    console.log("Generating %s from %s using %s", this.uri, this.pathToPageTemplate, this.pathToPageContent)
    const contents = fs.readFileSync(this.pathToPageContent, "utf8")
    let htmlContent = null
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
    const html = ejs.render(fs.readFileSync(this.pathToPageTemplate, "utf8"), {
      nav:nav,
      content: htmlContent
    }, {
      filename: this.pathToPageTemplate
    })
    const destinationFile = path.join(outputDirName, this.uri)
    fs.mkdirSync(path.dirname(destinationFile), { recursive: true })
    fs.writeFileSync(destinationFile, html, "utf8")
    console.log("Wrote %s", destinationFile)
  }
}

class PropertiesPage extends Page {
  constructor(pathToPageContent, pathToPageOutput, category) {
    super(pathToPageContent, null, pathToPageOutput)
    this.category = category
  }
  get title() { return Title.fromDirName(this.category.name) }
  generate(outputDirName, nav) {
    const html = ejs.render(fs.readFileSync(this.pathToPageTemplate, "utf8"), {
      nav:nav,
      category: this.category,
    }, {
      filename: this.pathToPageTemplate
    })
    const destinationFile = path.join(outputDirName, this.uri)
    fs.mkdirSync(path.dirname(destinationFile), { recursive: true })
    fs.writeFileSync(destinationFile, html, "utf8")
    console.log("Wrote %s", destinationFile)
  }
}

class ClassesPage extends PropertiesPage {
}

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

class PropertiesSection extends NavSection {
  constructor(sourcePath, parsedDocumentation) {
    super()
    this.categoryTemplate = path.join(sourcePath, "page.html.ejs")
    if (!fs.existsSync(this.categoryTemplate)) {
      throw `No category template found at ${this.categoryTemplate}`
    }
    this.parsedDocumentation = parsedDocumentation
    this.uriBase = path.basename(sourcePath).replace(/^\d+_/,"")
  }
  get title() { return new Title("Properties",this.sortKey) }
  get items() {
    return this.parsedDocumentation.propertyCategories.map( (category) => {
      return new PropertiesPage(this.categoryTemplate, path.join(this.uriBase, category.name) + ".html", category)
    })
  }
}

class ClassesSection extends PropertiesSection {

  get title() { return new Title("Classes",this.sortKey) }
  get items() {
    return this.parsedDocumentation.classCategories.map( (category) => {
      return new ClassesPage(this.categoryTemplate, path.join(this.uriBase, category.name) + ".html", category)
    })
  }
}

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
        this.items.push(new Page(this.pageTemplate, fullPath, pathToPageOutput))
      }
    })
    this.items.sort(Page.compare)
  }

  static compare(a,b) { return a.title.sortKey.localeCompare(b.title.sortKey) }
}

const docGenerator = (outputDirName, templateDirName, parsedDocumentation) => {
  const nav = []
  const pages = []
  fs.readdirSync(templateDirName).forEach((file) => {
    const fullPath = path.join(templateDirName, file)
    const stat = fs.statSync(fullPath)
    if (stat.isDirectory()) {
      if (file != "includes") {
        nav.push(NavSection.fromPath(fullPath, parsedDocumentation))
      }
    }
    else {
      pages.push({ file: fullPath, basename: file })
    }
  })
  nav.sort(NavSection.compare)
  pages.forEach( ({file,basename}) => {
    const ext = path.extname(basename)
    if (ext == ".ejs") {
      const destinationFile = path.join(outputDirName, basename.slice(0,-ext.length, file))
      const html = ejs.render(fs.readFileSync(file, "utf8"), {
        nav:nav,
      }, {
        filename: file
      })
      fs.writeFileSync(destinationFile, html, "utf8")
      console.log("EJS'ed %s to %s", file, destinationFile)
    }
    else {
      const destinationFile = path.join(outputDirName, basename)
      fs.cpSync(file, destinationFile, { recursive: false })
      console.log("Copied non-EJS file %s to %s", file, destinationFile)
    }
  })
  nav.forEach( (navSection) => {
    navSection.items.forEach( (page) => {
      page.generate(outputDirName, nav)
    })
  })
  return
}

export default docGenerator
