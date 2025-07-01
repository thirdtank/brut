import { defineConfig } from 'vitepress'
import rdocLinker from './plugins/rdocLinker'
import jsdocLinker from './plugins/jsdocLinker'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Brut RB",
  description: "Documentation for the Brut.RB web framework.",
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
          { text: "Documentation Conventions", link: "/doc-conventions" },
          { text: "Tutorial", link: "/tutorial" },
          { text: "Dev Environment", link: "/dev-environment" },
          { text: "AI Declaration", link: "/ai" },
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
          { text: "Form Validations", link: "/recipes/form-validations" },
          { text: "Database Migrations", link: "/recipes/database-migrations" },
          { text: "Ajax Form Submission", link: "/recipes/ajax-form" },
          { text: "Custom Telemetry", link: "/recipes/telemetry" },
          { text: "CLI App/Task", link: "/recipes/cli-app" },
        ],
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
