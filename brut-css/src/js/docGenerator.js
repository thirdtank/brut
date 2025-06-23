import ejs from "ejs"
import fs from "node:fs"
import path from "node:path"

class Title {
  static fromId(id) {
    const nameWithoutPrefix = id.replace(/^\d+_/, '').replace(/\..*$/,'')
    return new this(nameWithoutPrefix.
      split('-').
      map(word => word.charAt(0).toUpperCase() + word.slice(1)).
      join(' '))
  }
  constructor(title) {
    this.title = title
  }
  toString() { return this.title }
}
class Page {
  constructor(pagePath, uri) {
    this.pagePath = pagePath
    this.id = path.basename(pagePath)
    this.uri = uri
    this.title = Title.fromId(this.id).toString()
  }
  static compare(a,b) { return a.id.localeCompare(b.id) }
}
class NavSection {
  static fromPath(sourcePath, parsedDocumentation) {
    const id = path.basename(sourcePath)
    if (id.match(/^\d+_properties$/)) {
      return new PropertiesSection(sourcePath,id, parsedDocumentation)
    }
    if (id.match(/^\d+_classes/)) {
      return new ClassesSection(sourcePath,id, parsedDocumentation)
    }
    return new StaticPagesSection(sourcePath,id)
  }
}

class PropertiesSection extends NavSection {
  constructor(sourcePath, id, parsedDocumentation) {
    super()
    this.categoryTemplate = path.join(sourcePath, "category.html.ejs")
    this.id = id
    this.parsedDocumentation = parsedDocumentation
  }
  get title() { return "Properties" }
  get items() {
    return this.parsedDocumentation.propertyCategories.map( (category) => {
      return {
        title: Title.fromId(category.name).toString(),
        uri: path.join(this.id, category.name),
      }
    })
  }
}

class ClassesSection extends PropertiesSection {

  get title() { return "Classes" }
  get items() {
    return this.parsedDocumentation.classCategories.map( (category) => {
      return {
        title: Title.fromId(category.name).toString(),
        uri: path.join(this.id, category.name),
      }
    })
  }
}

class StaticPagesSection extends NavSection {
  constructor(sourcePath, id) {
    super()
    this.sourcePath = sourcePath
    this.id = id

    this.title = Title.fromId(this.id).toString()

    this.items = []

    fs.readdirSync(sourcePath).forEach((file) => {
      const fullPath = path.join(sourcePath, file)
      const stat = fs.statSync(fullPath)
      if (stat.isDirectory()) {
        throw `${fullPath} is a directroy. ${sourcePath} may only includes files`
      }
      this.items.push(new Page(fullPath, path.join(this.id,file)))
    })
    this.items.sort(Page.compare)
  }

  static compare(a,b) { return a.id.localeCompare(b.id) }
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
  return
  const x = ejs.render(`
  <% parsedDocumentation.propertyCategories.forEach( (category) => { %>
    <h2><%= category.name %></h2>
    <p><%= category.description %></p>
    <ul>
      <% category.scales.forEach( (scale) => { %>
        <li><%= scale.name %>: <%= scale.description %></li>
      <% }) %>
    </ul>
  <% }) %>`, { parsedDocumentation: parsedDocumentation })
  console.log(x)
}

export default docGenerator
