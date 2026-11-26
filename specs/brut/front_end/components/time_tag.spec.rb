require "spec_helper"
require "nokogiri"
require "rack-protection"

RSpec.describe Brut::FrontEnd::Components::TimeTag do
  let(:translations) do
    {
      time: {
        formats: {
          full:                 "TIME_FULL(%Y-%m-%d)",
          full_no_year:         "TIME_NO_YEAR(%m-%d)",
          full_no_dow:          "TIME_NO_DOW(%Y-%m-%d)",
          full_no_year_no_dow:  "TIME_NO_YEAR_NO_DOW(%m-%d)",
          iso_8601:             "%Y-%m-%dT%H:%M:%S",
        },
      },
      date: {
        formats: {
          date:                 "DATE_DATE(%Y-%m-%d)",
          date_no_year:         "DATE_NO_YEAR(%m-%d)",
          date_no_dow:          "DATE_NO_DOW(%Y-%m-%d)",
          date_no_year_no_dow:  "DATE_NO_YEAR_NO_DOW(%m-%d)",
          iso_8601:             "%Y-%m-%d",
        },
      },
    }
  end

  let(:timezone) { TZInfo::Timezone.get("UTC") }
  let(:now)      { Time.utc(2030, 6, 15, 12, 0, 0) }
  let(:clock)    { Clock.new(timezone, now: now) }

  let(:request_context) do
    rack_session = {}
    context = Brut::FrontEnd::RequestContext.new(
      env: { "rack.session" => rack_session },
      session: Brut::FrontEnd::Session.new(rack_session: rack_session),
      flash: Brut::FrontEnd::Flash.new,
      xhr: false,
      body: "",
      host: URI("https://example.com")
    )
    context[:clock] = clock
    context
  end

  around do |example|
    @original_i18n_backend    = I18n.backend
    @original_i18n_load_path  = I18n.load_path
    @original_available       = I18n.available_locales_initialized? ? I18n.available_locales : nil

    # A fresh `I18n::Backend::Simple` lazily loads every file in `I18n.load_path`
    # the first time a lookup (or `available_locales`) happens, because `lookup`
    # calls `init_translations unless initialized?`. That is the entire
    # faker/activesupport locale set, ~0.3s *per example* here. Our translations
    # are stored explicitly below, so blanking the load path (note: assigning
    # it calls `backend.reload!`, so it must happen before we store anything)
    # and caching `[:en]` skips that load entirely. Both are restored below.
    I18n.load_path          = []
    I18n.backend            = I18n::Backend::Simple.new
    I18n.backend.store_translations(:en, translations)
    I18n.available_locales  = [:en]
    I18n.locale             = :en

    example.run
  ensure
    I18n.available_locales  = @original_available
    I18n.load_path          = @original_i18n_load_path
    I18n.backend            = @original_i18n_backend
  end

  before do
    span = double(add_prefixed_attributes: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }

    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    allow(Brut).to receive(:container).and_return(container)

    Thread.current.thread_variable_set(:request_context, request_context)
  end

  after do
    Thread.current.thread_variable_set(:request_context, nil)
  end

  def time_from(html) = Nokogiri::HTML5(html).at_css("time")

  describe "generating HTML" do
    it "renders a time element with the formatted timestamp and an ISO-8601 datetime attribute" do
      timestamp = Time.utc(2030, 6, 10, 15, 30, 0)

      time = time_from(
        described_class.new(
          timestamp:,
          format: :full,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: false
        ).call
      )

      expect(time.text).to        eq("TIME_FULL(2030-06-10)")
      expect(time["datetime"]).to eq("2030-06-10T15:30:00")
    end

    it "uses date formats and renders date-only values when given a date" do
      date = Date.new(2029, 7, 4)

      time = time_from(
        described_class.new(
          date:,
          format: :date,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: false
        ).call
      )

      expect(time.text).to        eq("DATE_DATE(2029-07-04)")
      expect(time["datetime"]).to eq("2029-07-04")
    end

    it "renders the timestamp in the request clock's time zone" do
      time = time_from(
        described_class.new(
          timestamp: Time.utc(2030, 6, 10, 15, 30, 0),
          format: :full,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: false
        ).call
      )

      expect(time["datetime"]).to eq("2030-06-10T15:30:00")
    end

    it "renders the given block's content instead of the formatted value, but still sets datetime" do
      date = Date.new(2029, 7, 4)

      time = time_from(
        described_class.new(
          date:,
          format: :date,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: false
        ) { "custom contents" }.call
      )

      expect(time.text).to        eq("custom contents")
      expect(time["datetime"]).to eq("2029-07-04")
    end
  end

  context "when the request clock is in another time zone" do
    let(:timezone) { TZInfo::Timezone.get("America/New_York") }

    it "formats the timestamp in that time zone" do
      time = time_from(
        described_class.new(
          timestamp: Time.utc(2030, 6, 10, 15, 30, 0),
          format: :full,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: false
        ).call
      )

      expect(time.text).to        eq("TIME_FULL(2030-06-10)")
      expect(time["datetime"]).to eq("2030-06-10T11:30:00")
    end
  end

  context "when skip_year_if_same is applied at a year boundary in another time zone" do
    # UTC-2029-12-31 is 2030-01-01 in Kiritimati (UTC+14), so the year being
    # *displayed* (2030) matches the request clock's year even though the
    # timestamp's own `year` is 2029.
    let(:timezone) { TZInfo::Timezone.get("Pacific/Kiritimati") }

    it "compares the year as displayed in the request clock's time zone" do
      time = time_from(
        described_class.new(
          timestamp: Time.utc(2029, 12, 31, 20, 0, 0),
          format: :full,
          skip_year_if_same: true,
          skip_dow_if_not_this_week: false
        ).call
      )

      expect(time.text).to eq("TIME_NO_YEAR(01-01)")
    end
  end

  describe "skip_year_if_same" do
    it "omits the year when the timestamp is in the same year as the request clock's now" do
      timestamp = Time.utc(2030, 3, 1, 12, 0, 0)

      time = time_from(
        described_class.new(
          timestamp:,
          format: :full,
          skip_year_if_same: true,
          skip_dow_if_not_this_week: false
        ).call
      )

      expect(time.text).to eq("TIME_NO_YEAR(03-01)")
    end

    it "keeps the year when the timestamp is in a different year from the request clock's now" do
      timestamp = Time.utc(2029, 3, 1, 12, 0, 0)

      time = time_from(
        described_class.new(
          timestamp:,
          format: :full,
          skip_year_if_same: true,
          skip_dow_if_not_this_week: false
        ).call
      )

      expect(time.text).to eq("TIME_FULL(2029-03-01)")
    end

    it "keeps the year when skip_year_if_same is false" do
      timestamp = Time.utc(2030, 3, 1, 12, 0, 0)

      time = time_from(
        described_class.new(
          timestamp:,
          format: :full,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: false
        ).call
      )

      expect(time.text).to eq("TIME_FULL(2030-03-01)")
    end
  end

  describe "skip_dow_if_not_this_week" do
    it "omits the day of week when the timestamp is more than 7 days before the request clock's now" do
      timestamp = Time.utc(2030, 6, 1, 12, 0, 0) # 14 days before the clock's now

      time = time_from(
        described_class.new(
          timestamp:,
          format: :full,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: true
        ).call
      )

      expect(time.text).to eq("TIME_NO_DOW(2030-06-01)")
    end

    it "keeps the day of week when the timestamp is within 7 days of the request clock's now" do
      timestamp = Time.utc(2030, 6, 12, 12, 0, 0) # 3 days before the clock's now

      time = time_from(
        described_class.new(
          timestamp:,
          format: :full,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: true
        ).call
      )

      expect(time.text).to eq("TIME_FULL(2030-06-12)")
    end

    it "keeps the day of week when skip_dow_if_not_this_week is false" do
      timestamp = Time.utc(2030, 6, 1, 12, 0, 0)

      time = time_from(
        described_class.new(
          timestamp:,
          format: :full,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: false
        ).call
      )

      expect(time.text).to eq("TIME_FULL(2030-06-01)")
    end

    it "applies both suffixes when the year matches and the timestamp is more than 7 days old" do
      timestamp = Time.utc(2030, 6, 1, 12, 0, 0)

      time = time_from(
        described_class.new(
          timestamp:,
          format: :full,
          skip_year_if_same: true,
          skip_dow_if_not_this_week: true
        ).call
      )

      expect(time.text).to eq("TIME_NO_YEAR_NO_DOW(06-01)")
    end
  end

  describe "invalid usage" do
    it "raises when neither date nor timestamp is given" do
      expect {
        described_class.new
      }.to raise_error(ArgumentError, /one of timestamp: or date:/)
    end

    it "raises when both date and timestamp are given" do
      expect {
        described_class.new(timestamp: Time.utc(2030, 6, 10, 12, 0, 0), date: Date.new(2030, 6, 10))
      }.to raise_error(ArgumentError, /only one of timestamp: or date:/)
    end

    it "raises when no matching format can be found" do
      expect {
        described_class.new(
          timestamp: Time.utc(2030, 6, 10, 12, 0, 0),
          format: :nonsense,
          skip_year_if_same: false,
          skip_dow_if_not_this_week: false
        )
      }.to raise_error(ArgumentError, /nonsense is not a known time format/)
    end
  end
end
