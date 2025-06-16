exports.defineTags = function(dictionary) {
  dictionary.defineTag('customelement', {
    mustHaveValue: true,
    onTagged: function(doclet, tag) {
      doclet.customElement = tag.value;
    }
  });
};
