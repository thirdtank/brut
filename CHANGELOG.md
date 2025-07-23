# Brut CHANGELOG

## v0.8.0 - July 23, 2025

* Moved `mkbrut` into this repo
* Unify versioning for Brut, `mkbrut`, BrutJS, and BrutCSS
* Unify all workspace workflow scripts (see README.md)
* Minor doc updates to remove references to non-existent `form_tag`

## v0.5.0 - July 21, 2025

* **New helper** `entity` for creating HTML entities without needing `raw(safe(...))`

  ```ruby
  # BEFORE
  a(href:HomePage.routing) do
    raw(safe("&larr;"))
    whitespace
    plain("Back")
  end

  # AFTER
  a(href:HomePage.routing) do
    entity("larr")  # <----
    whitespace
    plain("Back")
  end
  ```

* Insturment each component's `view_template` method to give a breakdown on 
  performance per component
* Added a few additional events for tracing
* Fix bug in `bin/scaffold db_model` where `implementation_is_trivial` was misspelled

## v0.4.0 - July 12, 2025 and July 16, 2025 (see note)

* **Breaking Change** - changed `cv.fe` and `cv.be` I18n keys to `cv.cs` and `cv.ss`
  - This is to be consistent with Brut terminology
  - To address this change:
    1. Update brut-js to 0.0.22
    2. Modify your `app/config/*/*.rb` i18n files to change `cv:` to `cs:` and `be:`
       to `ss:`
    3. Change `app/src/front_end/layouts/default_layout.rb`:

       ```diff
       -        I18nTranslations("cv.fe")
       +        I18nTranslations("cv.cs")
       ```
    4. Change anywhere in your code or tests that you refer to those keys
* Added `#valid?` to `Brut::FrontEnd::Form` to make it easier to check a lack
  of constraint violations
* Added response body to `<brut-ajax-submit>`

**NOTE:** BrutJS and BrutCSS versions were changed to 0.4.0 on July 16 to mirror the Brut RubyGem. Intention is to keep all three in sync to avoid confusion about what the versions mean.

## v0.3.1 - July 12, 2025

* **`bin/db new_migration` includes link to the migrations recipe**

## v0.3.0 - July 11, 2025

* **`bin/scaffold form` generates correct handler code**

## v0.2.3 - July 10, 2025

* **References nonexistent class**

## v0.2.2 - July 10, 2025

* **Address incorrect underscorization on classnames**

## v0.2.1 - July 10, 2025

* **Fix bug with select component where a blank value would cause an exception**

## v0.2.0 - July 10, 2025

* **Re-implement `RichString.underscorize` + add tests for `RichString`**

  `RichString` may not survive until 1.0
