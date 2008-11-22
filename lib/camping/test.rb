$:.unshift(File.dirname(__FILE__) + '/../')
require 'test/unit'
require 'camping/server'
require 'camping/test/utils'
require 'camping/test/assertions'
require 'camping/test/base'

SOURCE = "\n\n"+File.read(File.dirname(__FILE__) + '/test/base.rb')
Camping::S << SOURCE
Camping::Apps.each do |app|
  eval(SOURCE.gsub("Camping", app.to_s))
end

Test::Unit::TestCase.fixture_path = "test/fixtures/" if Test::Unit::TestCase.respond_to?(:fixture_path)