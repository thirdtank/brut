# Brut CHANGELOG

## v0.4.0 - July 12, 2025

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
