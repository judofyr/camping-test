module Camping
  TestUtils = Object.const_get("Cam\ping").const_get(:TestUtils) unless defined?(TestUtils)
  include TestUtils

  module Tests
    # Checks if models have been loaded
    if Models.autoload?(:Base).nil? && Object.const_defined?(:ActiveRecord) && Models::Base == ActiveRecord::Base
      require 'active_record/fixtures'
      require 'active_record/test_case'
      
      # Our TestCase-class with fixtures
      parent = Class.new(ActiveRecord::TestCase) do
        include ActiveRecord::TestFixtures
        self.fixture_path = "test/fixtures/"
        self.use_instantiated_fixtures  = false
        self.use_transactional_fixtures = true
        def self.name; inspect; end
        self
      end
      
      # connect!
      Models::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
      # dummy so AR thinks we've connected
      Models::Base.configurations['test'] = true
      
      # register all models to fixture_class_names, so AR can load fixtures properly
      Models.constants.each do |const|
        klass = Models.const_get(const)
        if klass.is_a?(Class) && klass < Models::Base
          parent.fixture_class_names[klass.table_name.to_sym] = klass
        end
      end
    else
      # Old, boring Test::Unit
      parent = ::Test::Unit::TestCase
    end
    
    class Test < parent
      include TestUtils
      undef default_test if defined? default_test
      
      def self.test(name, &blk)
        meth = "test: #{name}"
        raise "Test already defined: #{meth}" if instance_methods.include?(meth)
        define_method(meth, &blk)
      end
    end
    
    class Model < Test
      include Camping::Models
    end
    
    class Web < Test
      attr_reader :state, :cookies
      include Assertions
      
      def setup
        super
        @state = Camping::H.new
        @cookies = Camping::H.new
        @app = C
        @app = Server::XSendfile.new(@app)
        @request = Rack::MockRequest.new(@app)
      end
      
      def send_request(method, path, input = nil)
        method = method.to_s.upcase
        opts = FormBuilder.new(method, input).build
        path << "?#{opts[:query]}" if opts[:query]
        opts[STATE] = @state
        opts[COOKIES] = @cookies
        @response = @request.request(method, path, opts)
        
        @assigns = @response.original_headers.delete(ASSIGNS)
        @response.headers.delete(ASSIGNS)
        @cookies = @assigns[:cookies]
        @state = @assigns[:state]
      end
      
      [:get, :post, :put, :delete, :head].each do |meth|
        class_eval("def #{meth}(path = '/', opts = {})
          send_request(#{meth.to_s.inspect}, path, opts)
        end")
      end
      
      def extract_redirect
        URI.parse(@response.location).request_uri
      end
      
      def upload(name, opts = {})
        MockUpload.new(name, opts)
      end
      
      def follow_redirect
        if @response && @response.redirect?
          get extract_redirect
        end
      end
    end
  end
  
  Base.class_eval do
    service = Base.instance_method(:service)
    define_method(:service) do |*a|
      @cookies.update(@env[COOKIES])
      @state.update(@env[STATE]) if @state
      begin
        service.bind(self).call(*a)
      ensure
        @headers[ASSIGNS] = instance_variables.inject({}) do |assigns, ivar|
          assigns[ivar[1..-1].to_sym] = instance_variable_get(ivar)
          assigns
        end
      end
    end
  end
  
  create if respond_to?(:create)
end
