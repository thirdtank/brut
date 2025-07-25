import{_ as a,c as t,o as e,ag as n}from"./chunks/framework.1L-BeKqY.js";const h=JSON.parse('{"title":"Directory Structure","description":"","frontmatter":{},"headers":[],"relativePath":"dir-structure.md","filePath":"dir-structure.md"}'),d={name:"dir-structure.md"};function o(p,s,c,r,l,i){return e(),t("div",null,s[0]||(s[0]=[n(`<h1 id="directory-structure" tabindex="-1">Directory Structure <a class="header-anchor" href="#directory-structure" aria-label="Permalink to &quot;Directory Structure&quot;">​</a></h1><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>.</span></span>
<span class="line"><span>├── app</span></span>
<span class="line"><span>│   ├── config</span></span>
<span class="line"><span>│   │   └── i18n</span></span>
<span class="line"><span>│   │       └── en</span></span>
<span class="line"><span>│   ├── public</span></span>
<span class="line"><span>│   │   ├── css</span></span>
<span class="line"><span>│   │   ├── js</span></span>
<span class="line"><span>│   │   └── static</span></span>
<span class="line"><span>│   │       └── images</span></span>
<span class="line"><span>│   └── src</span></span>
<span class="line"><span>│       ├── back_end</span></span>
<span class="line"><span>│       │   ├── data_models</span></span>
<span class="line"><span>│       │       ├── db</span></span>
<span class="line"><span>│       │       ├── migrations</span></span>
<span class="line"><span>│       │       └── seed</span></span>
<span class="line"><span>│       ├── cli</span></span>
<span class="line"><span>│       └── front_end</span></span>
<span class="line"><span>│           ├── components</span></span>
<span class="line"><span>│           ├── css</span></span>
<span class="line"><span>│           ├── fonts</span></span>
<span class="line"><span>│           ├── forms</span></span>
<span class="line"><span>│           ├── handlers</span></span>
<span class="line"><span>│           ├── images</span></span>
<span class="line"><span>│           ├── js</span></span>
<span class="line"><span>│           ├── layouts</span></span>
<span class="line"><span>│           ├── pages</span></span>
<span class="line"><span>│           ├── route_hooks</span></span>
<span class="line"><span>│           ├── support</span></span>
<span class="line"><span>│           └── svgs</span></span>
<span class="line"><span>├── bin</span></span>
<span class="line"><span>├── deploy</span></span>
<span class="line"><span>├── dx</span></span>
<span class="line"><span>└── specs</span></span>
<span class="line"><span>    ├── back_end</span></span>
<span class="line"><span>    │   ├── data_models</span></span>
<span class="line"><span>    │       └── db</span></span>
<span class="line"><span>    ├── e2e</span></span>
<span class="line"><span>    ├── factories</span></span>
<span class="line"><span>    │   └── db</span></span>
<span class="line"><span>    └── front_end</span></span>
<span class="line"><span>        ├── components</span></span>
<span class="line"><span>        ├── handlers</span></span>
<span class="line"><span>        ├── js</span></span>
<span class="line"><span>        ├── pages</span></span>
<span class="line"><span>        └── support</span></span></code></pre></div><h2 id="top-level" tabindex="-1">Top Level <a class="header-anchor" href="#top-level" aria-label="Permalink to &quot;Top Level&quot;">​</a></h2><table tabindex="0"><thead><tr><th>Directory</th><th>Purpose</th></tr></thead><tbody><tr><td><code>app/</code></td><td>Contains all configuration and source code specific to your app</td></tr><tr><td><code>bin/</code></td><td>Contains tasks and other CLIs to do development of your app, such as <code>bin/test</code></td></tr><tr><td><code>dx/</code></td><td>Contains scripts to manage your development environment</td></tr><tr><td><code>specs/</code></td><td>Contains all tests</td></tr></tbody></table><h2 id="inside-app" tabindex="-1">Inside <code>app</code>/ <a class="header-anchor" href="#inside-app" aria-label="Permalink to &quot;Inside \`app\`/&quot;">​</a></h2><table tabindex="0"><thead><tr><th>Directory</th><th>Purpose</th></tr></thead><tbody><tr><td><code>bootstrap.rb</code></td><td>A ruby file that sets up your app and ensures everything is <code>require</code>d in the right way.</td></tr><tr><td><code>config/</code></td><td>Configuration for your app, such as localizations and translations. Brut tries very hard to make sure there is no YAML in here at all. YAML is not good for you.</td></tr><tr><td><code>public/</code></td><td>Root of public assets served by the app.</td></tr><tr><td><code>src/</code></td><td>All source code for your app</td></tr></tbody></table><p>Inside <code>app/src</code></p><table tabindex="0"><thead><tr><th>Directory</th><th>Purpose</th></tr></thead><tbody><tr><td><code>app.rb</code></td><td>The core of your app, mostly configuration, such as routes, hooks, middleware, etc.</td></tr><tr><td><code>back_end/</code></td><td>Back end classes for your app including database schema, DB models, seed data, and your domain logic</td></tr><tr><td><code>cli/</code></td><td>Any CLIs or tasks for your app</td></tr><tr><td><code>front_end/</code></td><td>The front-end for your app, including pages, components, forms, handlers, JavaScript, and assets</td></tr></tbody></table><p>Inside <code>app/src/back_end</code></p><table tabindex="0"><thead><tr><th>Directory</th><th>Purpose</th></tr></thead><tbody><tr><td><code>data_models/app_data_model.rb</code></td><td>Base class for all DB model classes</td></tr><tr><td><code>data_models/db</code></td><td>DB model classes</td></tr><tr><td><code>data_models/db.rb</code></td><td>Namespace module for DB model classes</td></tr><tr><td><code>data_models/migrations</code></td><td>Database schema migrations</td></tr><tr><td><code>data_models/seed</code></td><td>Seed data used for local development</td></tr></tbody></table><p>Inside <code>app/src/front_end</code></p><table tabindex="0"><thead><tr><th>Directory</th><th>Purpose</th></tr></thead><tbody><tr><td><code>components/</code></td><td>Component classes</td></tr><tr><td><code>css/</code></td><td>CSS, managed by esbuild and <code>bin/build-assets</code></td></tr><tr><td><code>fonts/</code></td><td>Custom fonts, managed by esbuild and <code>bin/build-assets</code></td></tr><tr><td><code>forms/</code></td><td>Form classes</td></tr><tr><td><code>handlers/</code></td><td>Handler classes</td></tr><tr><td><code>images/</code></td><td>Images, copied to <code>app/public</code> by <code>bin/build-assets</code></td></tr><tr><td><code>js/</code></td><td>JavaScript, managed by esbuild and <code>bin/build-assets</code></td></tr><tr><td><code>layouts/</code></td><td>Layout classes</td></tr><tr><td><code>middlewares/</code></td><td>Rack Middleware, if any</td></tr><tr><td><code>pages/</code></td><td>Page classes</td></tr><tr><td><code>route_hooks/</code></td><td>Route hooks, if any</td></tr><tr><td><code>support/</code></td><td>General support classes/junk drawer.</td></tr><tr><td><code>svgs/</code></td><td>SVGs you want to render inline</td></tr></tbody></table><h2 id="inside-specs" tabindex="-1">Inside <code>specs/</code> <a class="header-anchor" href="#inside-specs" aria-label="Permalink to &quot;Inside \`specs/\`&quot;">​</a></h2><p><code>specs/</code> is intended to mirror <code>app/src</code>, but has a few extra directories:</p><table tabindex="0"><thead><tr><th>Directory</th><th>Purpose</th></tr></thead><tbody><tr><td><code>specs/back_end</code></td><td>tests for all back-end code, organized the same as <code>app/src/back_end</code></td></tr><tr><td><code>specs/back_end/data_models/db</code></td><td>tests for all DB classes, if needed</td></tr><tr><td><code>specs/e2e</code></td><td>End-to-end tests, organized however you like</td></tr><tr><td><code>specs/factories</code></td><td>Root of all factories for FactoryBot. You can create subdirectories here for non-DB classes you may want to be able to create</td></tr><tr><td><code>specs/factories/db</code></td><td>Factories to create DB records</td></tr><tr><td><code>specs/front_end</code></td><td>tests for all front-end code, organized the same as <code>app/src/front_end</code></td></tr><tr><td><code>specs/js</code></td><td><em>JavaScript</em> code to test any autonomous custom elements you have created</td></tr></tbody></table>`,15)]))}const b=a(d,[["render",o]]);export{h as __pageData,b as default};
