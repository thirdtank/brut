# Almost verbatim copy of Hanami's parser:
#
# https://github.com/hanami/view/blob/main/lib/hanami/view/erb/parser.rb
#
# That is licensed MIT and thus so is this.
#
# Avoid changes to this file so it can be kept updated with Hanami.
class Brut::FrontEnd::Templates::ERBParser < Temple::Parser
  ERB_PATTERN = /(\n|<%%|%%>)|<%(==?|\#)?(.*?)?-?%>/m

  IF_UNLESS_CASE_LINE_RE = /\A\s*(if|unless|case)\b/
  BLOCK_LINE_RE = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/
  END_LINE_RE = /\bend\b/

  def call(input)
    results = [[:multi]]
    pos = 0

    input.scan(ERB_PATTERN) do |token, indicator, code|
      # Capture any text between the last ERB tag and the current one, and update the position
      # to match the end of the current tag for the next iteration of text collection.
      text = input[pos...$~.begin(0)]
      pos  = $~.end(0)

      if token
        # First, handle certain static tokens picked up by our ERB_PATTERN regexp. These are
        # newlines as well as the special codes for literal `<%` and `%>` values.
        case token
        when "\n"
          results.last << [:static, "#{text}\n"] << [:newline]
        when "<%%", "%%>"
          results.last << [:static, text] unless text.empty?
          token.slice!(1)
          results.last << [:static, token]
        end
      else
        # Next, handle actual ERB tags. Start by adding any static text between this match and
        # the last.
        results.last << [:static, text] unless text.empty?

        case indicator
        when "#"
          # Comment tags: <%# this is a comment %>
          results.last << [:code, "\n" * code.count("\n")]
        when %r{=}
          # Expression tags: <%= "hello (auto-escaped)" %> or <%== "hello (not escaped)" %>
          if code =~ BLOCK_LINE_RE
            # See Hanami::View::Erb::Filters::Block for the processing of `:erb, :block` sexps
            block_node = [:erb, :block, indicator.size == 1, code, (block_content = [:multi])]
            results.last << block_node

            # For blocks opened in ERB expression tags, push this `[:multi]` sexp
            # (representing the content of the block) onto the stack of resuts. This allows
            # subsequent results to be appropriately added inside the block, until its closing
            # tag is encountered, and this `block_content` multi is subsequently popped off
            # the results stack.
            results << block_content
          else
            results.last << [:escape, indicator.size == 1, [:dynamic, code]]
          end
        else
          # Code tags: <% if some_cond %>
          if code =~ BLOCK_LINE_RE || code =~ IF_UNLESS_CASE_LINE_RE
            results.last << [:code, code]

            # For ERB code tags that will result in a matching `end`, push the last result
            # back onto the stack of results. This might seem redundant, but it allows
            # subsequent sexps to continue to be pushed onto the same result while also
            # allowing it to be safely popped again when the matching `end` is encountered.
            results << results.last
          elsif code =~ END_LINE_RE
            results.last << [:code, code]
            results.pop
          else
            results.last << [:code, code]
          end
        end
      end
    end

    # Add any text after the final ERB tag
    results.last << [:static, input[pos..-1]]
  end
end
