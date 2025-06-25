export default function jsdocLinker(md) {

  const orig = md.renderer.rules.code_inline || function(tokens, idx, options, env, self) {
    return self.renderToken(tokens, idx, options);
  };

  function toPageName(tag) {
    if (tag == "cv") {
      return "ConstraintViolationMessage"
    }
    else if (tag == "cv-messages") {
      return "ConstraintViolationMessages"
    }
    else {
      return tag
        .split('-')
        .map(s => s.charAt(0).toUpperCase() + s.slice(1))
        .join('');
    }
  }

  md.renderer.rules.code_inline = function(tokens, idx, options, env, self) {
    const content = tokens[idx].content;
    // If it matches a custom element pattern
    const match = content.match(/^<brut-([a-z][a-z0-9\-]*)>$/);
    if (match) {
      const tag = match[1];
      const pageName = toPageName(tag);
      return `<a href="/brut-js/api/${pageName}.html" target="_self" rel="noopener" data-no-router><code style="white-space: nowrap">&lt;brut-${tag}&gt;</code></a>`;
    }
    // ...your existing Ruby class matcher, if you want both!
    return orig(tokens, idx, options, env, self);
  };
};
