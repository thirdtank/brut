# This is a slightly modified copy if Hanamis' Filters::Block:
#
# https://github.com/hanami/view/blob/main/lib/hanami/view/erb/filters/block.rb
#
class Brut::FrontEnd::Templates::BlockFilter < Temple::Filter
  END_LINE_RE = /\bend\b/

  def on_erb_block(escape, code, content)
    tmp = unique_name

    # Remove the last `end` :code sexp, since this is technically "outside" the block
    # contents, which we want to capture separately below. This `end` is added back after
    # capturing the content below.
    case content.last
    in [:code, c] if c =~ END_LINE_RE
      content.pop
    end

    [:multi,
     # Capture the result of the code in a variable. We can't do `[:dynamic, code]` because
     # it's probably not a complete expression (which is a requirement for Temple).
     # DBC: an example is that 'code' might be "form_for do" which is not an expression.
     #      Because we later put an "end" in, the result will be
     #
     #      some_var = helper do
     #      end
     #
     #      Which IS valid Ruby.
     [:code, "#{tmp} = #{code}"],
     # Capture the content of a block in a separate buffer. This means that `yield` will
     # not output the content to the current buffer, but rather return the output.
     [:capture, unique_name, compile(content)],
     [:code, "end"],
     # Output the content, without escaping it.
     # Hanami has this ↴
     # [:escape, escape, [:dynamic, tmp]]
     [:escape, escape, [:dynamic, Brut::FrontEnd::Templates.name + "::HTMLSafeString.new(#{tmp})"]]
    ]

    # Details explaining the change:
    #
    # The sexps for template are quite convoluted and highly dynamic, so it is hard
    # to understand exactly what effect they will have.  Basically, what this [:multi thing is
    # doing is to capture the result of the block in a variable:
    #
    # some_var = form_for(args) do
    #
    # It then captures the inside of the block in a new variable:
    #
    # some_other_var = «whatever was inside that `do`»
    #
    # And follows it with an end.
    #
    # The first variable—some_var—now holds the return value of the helper, form_for in this case. To
    # output this content to the actual view, it must be dereferenced, thus [ :dynamic, "some_var" ].
    #
    # We are going to treat the return value of the block helper as HTML safe.  Thus, we'll wrap it
    # with HTMLSafeString.new(…).
  end
end
