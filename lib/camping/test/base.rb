module Camping
  TestUtils = Object.const_get("Cam\ping").const_get(:TestUtils) unless defined?(TestUtils)
  module Tests
    class Test < ::Test::Unit::TestCase
      include TestUtils
      undef default_test
      
      def self.test(name, &blk)
        meth = "test: #{name}"
        raise "Test already defined: #{meth}" if instance_methods.include?(meth)
        define_method(meth, &blk)
      end
    end
    
    class Model < Test
    end
    
    class Web < Test
      include Assertions
      def setup
        super
        @app = C
        @app = Server::XSendfile.new(@app)
        @request = Rack::MockRequest.new(@app)
      end
      
      def send_request(method, path, input = nil)
        method = method.to_s.upcase
        opts = FormBuilder.new(method, input).build
        path << "?#{opts[:query]}" if opts[:query]
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
  
  include TestUtils::AssignStealer
  
  if Models.autoload?(:Base).nil? && Object.const_defined?(:ActiveRecord) && Models::Base == ActiveRecord::Base
    require 'active_record/fixtures'
    require 'sqlite3_api'
    Models::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
    Tests::Model.send(:include, Models)
  end
  
  create if respond_to?(:create)
end