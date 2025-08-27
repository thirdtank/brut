require "spec_helper"

RSpec.describe Brut::Instrumentation::Methods do
  describe "#instrument" do
    it "instruments only those methods specified" do
      mock_container = double("Brut::Framework::Container")
      instrumentation = instance_double(Brut::Instrumentation::OpenTelemetry)
      allow(Brut).to receive(:container).and_return(mock_container)
      allow(mock_container).to receive(:instrumentation).and_return(instrumentation)
      allow(instrumentation).to receive(:span).and_yield(double("span that should not be used"))

      class_to_instrument = Class.new do
        include Brut::Instrumentation::Methods

        def save
          @save_called = true
        end

        def search
          @search_called = true
        end

        def self.name # since this is an anonymous class, need some name to show up
          "TestClass"
        end

        private

        def delete
          @delete_called = true
        end

        instrument :save, :delete
      end
      object = class_to_instrument.new

      object.save
      object.search
      object.send(:delete)

      expect(object.instance_variable_get(:@save_called)).to   eq(true)
      expect(object.instance_variable_get(:@search_called)).to eq(true)
      expect(object.instance_variable_get(:@delete_called)).to eq(true)
      expect(instrumentation).to have_received(:span).with(
        "TestClass#save",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "save",
        }
      )
      expect(instrumentation).to have_received(:span).with(
        "TestClass#delete",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "delete",
        }
      )
      expect(instrumentation).not_to have_received(:span).with(
        /\#search/,
        attributes: kind_of(Hash)
      )
    end
    it "works when called on a method definition" do
      mock_container = double("Brut::Framework::Container")
      instrumentation = instance_double(Brut::Instrumentation::OpenTelemetry)
      allow(Brut).to receive(:container).and_return(mock_container)
      allow(mock_container).to receive(:instrumentation).and_return(instrumentation)
      allow(instrumentation).to receive(:span).and_yield(double("span that should not be used"))

      class_to_instrument = Class.new do
        include Brut::Instrumentation::Methods

        instrument def save
          @save_called = true
        end

        def search
          @search_called = true
        end

        def self.name # since this is an anonymous class, need some name to show up
          "TestClass"
        end

        private

        instrument def delete
          @delete_called = true
        end
      end
      object = class_to_instrument.new

      object.save
      object.search
      object.send(:delete)

      expect(object.instance_variable_get(:@save_called)).to   eq(true)
      expect(object.instance_variable_get(:@search_called)).to eq(true)
      expect(object.instance_variable_get(:@delete_called)).to eq(true)
      expect(instrumentation).to have_received(:span).with(
        "TestClass#save",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "save",
        }
      )
      expect(instrumentation).to have_received(:span).with(
        "TestClass#delete",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "delete",
        }
      )
      expect(instrumentation).not_to have_received(:span).with(
        /\#search/,
        attributes: kind_of(Hash)
      )
    end

    it "calling it twice raises an error" do
      expect {
        Class.new do
          include Brut::Instrumentation::Methods

          def save
            @save_called = true
          end

          def self.name # since this is an anonymous class, need some name to show up
            "TestClass"
          end

          instrument :save
          instrument :save
        end
      }.to raise_error(ArgumentError, /already instrumented/)
    end

    it "instrumenting a nonexistent method raises an error" do
      expect {
        Class.new do
          include Brut::Instrumentation::Methods

          def save
            @save_called = true
          end

          def self.name # since this is an anonymous class, need some name to show up
            "TestClass"
          end

          instrument :foo
        end
      }.to raise_error(ArgumentError)
    end
  end
  describe "#instrument_all" do
    it "instruments all methods" do
      mock_container = double("Brut::Framework::Container")
      instrumentation = instance_double(Brut::Instrumentation::OpenTelemetry)
      allow(Brut).to receive(:container).and_return(mock_container)
      allow(mock_container).to receive(:instrumentation).and_return(instrumentation)
      allow(instrumentation).to receive(:span).and_yield(double("span that should not be used"))

      class_to_instrument = Class.new do
        include Brut::Instrumentation::Methods

        def save
          @save_called = true
        end

        def search
          @search_called = true
        end

        def self.name # since this is an anonymous class, need some name to show up
          "TestClass"
        end

        private

        def delete
          @delete_called = true
        end

        instrument_all
      end
      object = class_to_instrument.new

      object.save
      object.search
      object.send(:delete)

      expect(object.instance_variable_get(:@save_called)).to   eq(true)
      expect(object.instance_variable_get(:@search_called)).to eq(true)
      expect(object.instance_variable_get(:@delete_called)).to eq(true)
      expect(instrumentation).to have_received(:span).with(
        "TestClass#save",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "save",
        }
      )
      expect(instrumentation).to have_received(:span).with(
        "TestClass#delete",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "delete",
        }
      )
      expect(instrumentation).to have_received(:span).with(
        "TestClass#search",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "search",
        }
      )
    end
    it "instruments all methods defined after it is called" do
      mock_container = double("Brut::Framework::Container")
      instrumentation = instance_double(Brut::Instrumentation::OpenTelemetry)
      allow(Brut).to receive(:container).and_return(mock_container)
      allow(mock_container).to receive(:instrumentation).and_return(instrumentation)
      allow(instrumentation).to receive(:span).and_yield(double("span that should not be used"))

      class_to_instrument = Class.new do
        include Brut::Instrumentation::Methods
        instrument_all

        def save
          @save_called = true
        end

        def search
          @search_called = true
        end

        def self.name # since this is an anonymous class, need some name to show up
          "TestClass"
        end

        private

        def delete
          @delete_called = true
        end
      end
      object = class_to_instrument.new

      object.save
      object.search
      object.send(:delete)

      expect(object.instance_variable_get(:@save_called)).to   eq(true)
      expect(object.instance_variable_get(:@search_called)).to eq(true)
      expect(object.instance_variable_get(:@delete_called)).to eq(true)
      expect(instrumentation).to have_received(:span).with(
        "TestClass#save",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "save",
        }
      )
      expect(instrumentation).to have_received(:span).with(
        "TestClass#delete",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "delete",
        }
      )
      expect(instrumentation).to have_received(:span).with(
        "TestClass#search",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "search",
        }
      )
    end
  end
  describe "#instrument_public" do
    it "instruments only public methods" do
      mock_container = double("Brut::Framework::Container")
      instrumentation = instance_double(Brut::Instrumentation::OpenTelemetry)
      allow(Brut).to receive(:container).and_return(mock_container)
      allow(mock_container).to receive(:instrumentation).and_return(instrumentation)
      allow(instrumentation).to receive(:span).and_yield(double("span that should not be used"))

      class_to_instrument = Class.new do
        include Brut::Instrumentation::Methods

        def save
          @save_called = true
        end

        def search
          @search_called = true
        end

        def self.name # since this is an anonymous class, need some name to show up
          "TestClass"
        end

        private

        def delete
          @delete_called = true
        end

        instrument_public

      end
      object = class_to_instrument.new

      object.save
      object.search
      object.send(:delete)

      expect(object.instance_variable_get(:@save_called)).to   eq(true)
      expect(object.instance_variable_get(:@search_called)).to eq(true)
      expect(object.instance_variable_get(:@delete_called)).to eq(true)
      expect(instrumentation).to have_received(:span).with(
        "TestClass#save",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "save",
        }
      )
      expect(instrumentation).to have_received(:span).with(
        "TestClass#search",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "search",
        }
      )
      expect(instrumentation).not_to have_received(:span).with(
        "TestClass#delete",
        attributes: kind_of(Hash)
      )
    end
    it "instruments only public methods defined after it is called" do
      mock_container = double("Brut::Framework::Container")
      instrumentation = instance_double(Brut::Instrumentation::OpenTelemetry)
      allow(Brut).to receive(:container).and_return(mock_container)
      allow(mock_container).to receive(:instrumentation).and_return(instrumentation)
      allow(instrumentation).to receive(:span).and_yield(double("span that should not be used"))

      class_to_instrument = Class.new do
        include Brut::Instrumentation::Methods
        instrument_public

        def save
          @save_called = true
        end

        def search
          @search_called = true
        end

        def self.name # since this is an anonymous class, need some name to show up
          "TestClass"
        end

        private

        def delete
          @delete_called = true
        end

      end
      object = class_to_instrument.new

      object.save
      object.search
      object.send(:delete)

      expect(object.instance_variable_get(:@save_called)).to   eq(true)
      expect(object.instance_variable_get(:@search_called)).to eq(true)
      expect(object.instance_variable_get(:@delete_called)).to eq(true)
      expect(instrumentation).to have_received(:span).with(
        "TestClass#save",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "save",
        }
      )
      expect(instrumentation).to have_received(:span).with(
        "TestClass#search",
        attributes: {
          "brut.class" => "TestClass",
          "brut.method" => "search",
        }
      )
      expect(instrumentation).not_to have_received(:span).with(
        "TestClass#delete",
        attributes: kind_of(Hash)
      )
    end
  end
end
