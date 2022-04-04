require 'rspec/expectations'

RSpec::Matchers.define :be_critically_equivalent_to do |expected|
  match do |actual|
    actual.map(&:critical_attributes) == expected.map(&:critical_attributes)
  end

  failure_message do |actual|
    "expected (#{expected.map(&:critical_attributes)}) but got: #{actual.map(&:critical_attributes)}"
  end  
end