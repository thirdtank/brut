import fs        from "node:fs"
import postcss   from "postcss"
import { parse } from "comment-parser"

class NormalizedCommentText {
  constructor(text) {
    const trimmed = (text || "").trim()
    const delimitersRemoved = trimmed.replace(/\/\*+/,"").replace(/\*+\//,"")
    this.normalizedComment = `/**\n ${delimitersRemoved}\n*/`
  }
}
class MediaQuery {
  constructor(rawQuery, documentation, suffix) {
    this.rawQuery      = rawQuery
    this.documentation = documentation
    this.suffix        = suffix
    this.error         = null
  }

  isError() { return false }
}

class ParseError {
  constructor(rawQuery, error) {
    this.rawQuery = rawQuery
    this.error    = error
  }
  isError() { return true }
}

class CommentParsingError {
  constructor(commentText, error) {
    this.commentText = commentText
    this.error       = error
  }
  isError() { return true }
}
class ParsedComment {
  static fromNormalizedCommentText(normalizedCommentText) {
    const commentParserResult = parse(normalizedCommentText.normalizedComment)
    if (commentParserResult.length == 0) {
      return new CommentParsingError(commentText, "Did not contain a preceding comment (which should contain a @suffix tag)")
    }
    if (commentParserResult.length > 1) {
      throw `Something is wrong: Got more than one comment from ${normalizedCommentText.normalizedComment}`
    }
    const parsedComment = commentParserResult[0]
    const suffixTags = parsedComment.tags.filter((tag) => tag.tag === "suffix")
    if (suffixTags.length == 0) {
      return new CommentParsingError(normalizedCommentText.normalizedComment, "Did not contain a @suffix tag")
    }
    if (suffixTags.length > 1) {
      return new CommentParsingError(normalizedCommentText.normalizedComment, "Contained more than one @suffix tag")
    }
    return new ParsedComment(parsedComment.description, suffixTags[0].name)
  }

  constructor(documentation, suffix) {
    this.documentation = documentation
    this.suffix        = suffix
    this.error         = null
  }

  isError() { return false }
}

const mediaQueryConfigParser = (mediaQueryConfigFile) => {
  const mediaQueries = [
    new MediaQuery(null, "The default media query", null)
  ]
  if (!mediaQueryConfigFile) {
    return mediaQueries
  }
  const css = fs.readFileSync(mediaQueryConfigFile, 'utf8')
  const parsedCSS = postcss.parse(css, { from: mediaQueryConfigFile })


  parsedCSS.walkAtRules('media', (rule) => {
    const mediaQuery = rule.params.trim()
    const comment = rule.prev()

    if (!comment || comment.type !== "comment") {
      mediaQueries.push(new ParseError(mediaQuery, "Must be preceded by a comment"))
    }
    else {
      const parsedComment = ParsedComment.fromNormalizedCommentText(new NormalizedCommentText(comment.text))
      if (parsedComment.isError()) {
        mediaQueries.push(new ParseError(mediaQuery, parsedComment.error))
      }
      else {
        mediaQueries.push(new MediaQuery(mediaQuery, parsedComment.documentation, parsedComment.suffix))
      }
    }
  })
  return mediaQueries
}

export default mediaQueryConfigParser
