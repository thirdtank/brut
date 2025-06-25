export default function rdocLinker(md) {

  const orig = md.renderer.rules.code_inline || function(tokens, idx, options, env, self) {
    return self.renderToken(tokens, idx, options);
  };

  md.renderer.rules.code_inline = function(tokens, idx, options, env, self) {
    const content = tokens[idx].content;
    // Only match Ruby class-like tokens
    if (/^Brut::[A-Z][A-Za-z0-9_:]+$/.test(content)) {
      const path = content.replace(/::/g, '/')
      return `<a href="/api/${path}.html" target="_self" rel="noopener" data-no-router><code>${md.utils.escapeHtml(content)}</code></a>`;
    }
    // Fallback to regular rendering
    return orig(tokens, idx, options, env, self);
  };

};
