# Directory Structure

```
.
├── app
│   ├── config
│   │   └── i18n
│   │       └── en
│   ├── public
│   │   ├── css
│   │   ├── js
│   │   └── static
│   │       └── images
│   └── src
│       ├── back_end
│       │   ├── data_models
│       │       ├── db
│       │       ├── migrations
│       │       └── seed
│       ├── cli
│       └── front_end
│           ├── components
│           ├── css
│           ├── fonts
│           ├── forms
│           ├── handlers
│           ├── images
│           ├── js
│           ├── layouts
│           ├── pages
│           ├── route_hooks
│           ├── support
│           └── svgs
├── bin
├── deploy
├── dx
└── specs
    ├── back_end
    │   ├── data_models
    │       └── db
    ├── e2e
    ├── factories
    │   └── db
    └── front_end
        ├── components
        ├── handlers
        ├── js
        ├── pages
        └── support
```

## Top Level

| Directory | Purpose |
|-----------|---------|
| `app/`    | Contains all configuration and source code specific to your app |
| `bin/`    | Contains tasks and other CLIs to do development of your app, such as `bin/test` |
| `dx/`     | Contains scripts to manage your development environment |
| `specs/`  | Contains all tests |

## Inside `app`/

| Directory | Purpose |
|-----------|---------|
| `bootstrap.rb` | A ruby file that sets up your app and ensures everything is `require`d in the right way. |
| `config/` | Configuration for your app, such as localizations and translations. Brut tries very hard to make sure there is no YAML in here at all. YAML is not good for you. |
| `public/` | Root of public assets served by the app. |
| `src/` | All source code for your app |

Inside `app/src`

| Directory | Purpose |
|-----------|---------|
| `app.rb` | The core of your app, mostly configuration, such as routes, hooks, middleware, etc. |
| `back_end/` | Back end classes for your app including database schema, DB models, seed data, and your domain logic |
| `cli/` | Any CLIs or tasks for your app |
| `front_end/` | The front-end for your app, including pages, components, forms, handlers, JavaScript, and assets |

Inside `app/src/back_end`

| Directory | Purpose |
|-----------|---------|
| `data_models/app_data_model.rb` | Base class for all DB model classes |
| `data_models/db` | DB model classes |
| `data_models/db.rb` | Namespace module for DB model classes |
| `data_models/migrations` | Database schema migrations |
| `data_models/seed` | Seed data used for local development |

Inside `app/src/front_end`

|Directory       | Purpose |
|----------------|---------|
| `components/`  | Component classes |
| `css/`         | CSS, managed by esbuild and `bin/build-assets` |
| `fonts/`       | Custom fonts, managed by esbuild and `bin/build-assets` |
| `forms/`       | Form classes |
| `handlers/`    | Handler classes |
| `images/`      | Images, copied to `app/public` by `bin/build-assets` |
| `js/`          | JavaScript, managed by esbuild and `bin/build-assets` |
| `layouts/`     | Layout classes |
| `middlewares/` | Rack Middleware, if any |
| `pages/`       | Page classes |
| `route_hooks/` | Route hooks, if any |
| `support/`     | General support classes/junk drawer. |
| `svgs/`        | SVGs you want to render inline |

## Inside `specs/`

`specs/` is intended to mirror `app/src`, but has a few extra directories:


|Directory       | Purpose |
|----------------|---------|
| `specs/back_end` | tests for all back-end code, organized the same as `app/src/back_end` |
| `specs/back_end/data_models/db` | tests for all DB classes, if needed |
| `specs/e2e` | End-to-end tests, organized however you like |
| `specs/factories` | Root of all factories for FactoryBot. You can create subdirectories here for non-DB classes you may want to be able to create |
| `specs/factories/db` | Factories to create DB records |
| `specs/front_end` | tests for all front-end code, organized the same as `app/src/front_end` |
| `specs/js`| *JavaScript* code to test any autonomous custom elements you have created |
