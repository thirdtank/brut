import { defineConfig } from 'vitepress'
import rdocLinker from './plugins/rdocLinker'
import jsdocLinker from './plugins/jsdocLinker'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Brut RB",
  description: "Documentation for the Brut.RB web framework.",
  head: [
    ["link", { rel: "icon", href: "/favicon.ico" }],
    [
      "meta", {
        property: "og:title",
        content: "BrutRB Documentation"
      }
    ],
    [
      "meta", {
        property: "og:type",
        content: "website"
      }
    ],
    [
      "meta", {
        property: "og:image",
        content: "https://brutrb.com/SocialImage.png"
      }
    ],
    ["script", {
      defer: "",
      "data-domain": "brutrb.com",
      src: "https://plausible.io/js/script.js"
    }
    ],
  ],
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    search: {
      provider: 'local',
    },
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Getting Started', link: '/getting-started' },
      { text: 'Overview', link: '/overview' },
      { text: 'Brut API', link: '/api/index.html', target: "_self" },
      { text: 'BrutJS', link: '/brut-js/api/index.html', target: "_self" },
      { text: 'BrutCSS', link: '/brut-css/index.html', target: "_self" },
    ],
    outline: [ 2, 3] ,
    sidebar: [
      {
        text: "Overview",
        collapsed: false,
        items: [
          { text: "Getting Started", link: "/getting-started" },
          { text: "Concepts", link: "/overview" },
          { text: "Features", link: "/features" },
          { text: "Directory Structure", link: "/dir-structure" },
          { text: "Dev Environment", link: "/dev-environment" },
          { text: "Tutorial", link: "/tutorial" },
          { text: "Documentation Conventions", link: "/doc-conventions" },
        ]
      },
      {
        text: "Front-End",
        collapsed: false,
        items: [
          { text: "Routes", link: "/routes" },
          { text: "Pages", link: "/pages" },
          { text: "Layouts", link: "/layouts" },
          { text: "Forms", link: "/forms" },
          { text: "Form Constraints", link: "/form-constraints" },
          { text: "Handlers and Actions", link: "/handlers" },
          { text: "Components", link: "/components" },
          { text: "Flash and Session", link: "/flash-and-session" },
          { text: "Space/Time Continuum", link: "/space-time-continuum" },
          { text: "JavaScript", link: "/javascript" },
          { text: "CSS", link: "/css" },
          { text: "Assets", link: "/assets" },
          { text: "BrutJS", link: "/brut-js" },
        ]
      },
      {
        text: "Back-End",
        collapsed: false,
        items: [
          { text: "Database Schema", link: "/database-schema" },
          { text: "Database Access", link: "/database-access" },
          { text: "Seed Data", link: "/seed-data" },
          { text: "Jobs", link: "/jobs" },
          { text: "Business Logic", link: "/business-logic" },
        ]
      },
      {
        text: "Framework",
        collapsed: false,
        items: [
          { text: "Configuration", link: "/configuration" },
          { text: "Keyword Injection", link: "/keyword-injection" },
          { text: "I18n", link: "/i18n" },
          { text: "CLI / Tasks", link: "/cli" },
          { text: "Deployment", link: "/deployment" },
        ]
      },
      {
        text: "Testing",
        collapsed: false,
        items: [
          { text: "Unit Tests", link: "/unit-tests" },
          { text: "End-to-End Tests", link: "/end-to-end-tests" },
          { text: "Testing Custom Elements", link: "/custom-element-tests" },
        ]
      },
      {
        text: "Advanced Topics",
        collapsed: true,
        items: [
          { text: "Route Hooks", link: "/hooks" },
          { text: "Middleware", link: "/middleware" },
          { text: "Instrumentation", link: "/instrumentation" },
          { text: "Security", link: "/security" },
          { text: "LSP Support", link: "/lsp" },
        ],
      },
      {
        text: "Recipes",
        collapsed: true,
        items: [
          { text: "Authentication", link: "/recipes/authentication" },
          { text: "Alternate Layouts", link: "/recipes/alternate-layouts" },
          { text: "Blank Layouts", link: "/recipes/blank-layouts" },
          { text: "Custom Flash Class", link: "/recipes/custom-flash" },
          { text: "Indexed Form Elements", link: "/recipes/indexed-forms" },
          { text: "Text Field Component", link: "/recipes/text-field-component" },
        ],
      },
      {
        text: "Meta",
        collapsed: false,
        items: [
          { text: "Why?!", link: "/why" },
          { text: "AI Declaration", link: "/ai" },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/thirdtank/brut' }
    ]
  },
  markdown: {
    config(md) {
      md.use(rdocLinker)
      md.use(jsdocLinker)
    }
  }
})
