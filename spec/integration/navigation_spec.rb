require 'spec_helper'

describe "Rails project" do
  it "is a valid app" do
    expect(::Rails.application).to be_a(Dummy::Application)
  end
end
