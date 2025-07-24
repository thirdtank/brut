# Brut's defaults for various strings required by Brut's internals.
#
# You are discouraged from changing this file.
{
  # en: must be the first entry, thus indicating this is the EN translations
  en: {
    time:{
      formats: { # strftime formats
        iso_8601: "%Y-%m-%d %H:%M:%S.%6N %Z",
        full_with_tz: "%Y-%m-%d %H:%M:%S %Z",
        full: "%Y-%m-%d %H:%M:%S",
        default: "%Y-%m-%d %H:%M:%S",
        date: "%a, %b %e, %Y",
        date_no_dow: "%b %e, %Y",
        date_no_year: "%a, %b %e",
        date_no_year_no_dow: "%b %e",
        month_day_year: "%b %e, %Y",
        month_day_year_no_year: "%b %e",
        day_of_week: "%A",
        time_only: "%l:%M %p",
      },
      am: "AM",
      pm: "PM",
    },
    date: {
      formats: {
        iso_8601: "%Y-%m-%d",
        full: "%Y-%m-%d",
        default: "%a, %b %e, %Y",
        date: "%a, %b %e, %Y",
        date_no_dow: "%b %e, %Y",
        date_no_year: "%a, %b %e",
        date_no_year_no_dow: "%b %e",
        month_day_year: "%b %e, %Y",
        month_day_year_no_year: "%b %e",
        day_of_week: "%A",
        day_of_week_short: "%a",
        time_only: "%l:%M %p",
      },
      abbr_day_names: [
        "Sun",
        "Mon",
        "Tue",
        "Wed",
        "Thu",
        "Fri",
        "Sat",
      ],
      day_names: [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
      ],
      abbr_month_names: [
        "",
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ],
      month_names: [
        "",
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      ],
    },
    cv: { # short for "constraint violations" to avoid having to type that out
      this_field: "This field",
      cs: { # short for "client-side", again to not have to type it out
            # These keys use camel-case because that is how the browser defines
            # these values, based on ValidityState
        badInput: "%{field} is the wrong type of data",
        patternMismatch: "%{field} isn't in the right format",
        rangeOverflow: "%{field} is too big",
        rangeUnderflow: "%{field} is too small",
        stepMismatch: "%{field} is not a valid value in the range",
        tooLong: "%{field} is too long",
        tooShort: "%{field} is too short",
        typeMismatch: "%{field} is the wrong type",
        valueMissing: "%{field} is required",
        general: "Form is invalid",
      },
      ss: { # short for "server-side", again not to have to type it out
            # These are snake case, which is idiomatic for Ruby.  The values
            # here are all based on DataObjectValidator's behavior
        required: "%{field} is required",
        too_short: "%{field} is too short; must be at least %{minlength} characters",
      },
    },
    diagnostics: { # This is to help diagnose issues with the translation system and is not
                   # intended to store real strings to be used by your app
      has_interpolations: "Test %{interp} Test",
      has_pluralizations: {
        one: "Once!",
        other: "More than once!",
      },
      has_pluralizations_and_zero: {
        zero: "ZERO",
        one: "ONE",
        other: "MORE",
      },
      simple1: "SIMPLE1",
      simple2: "SIMPLE2",
    },
  },
}
