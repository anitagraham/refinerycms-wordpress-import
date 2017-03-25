require 'spec_helper'

describe Refinery::WordPress::Tag, :type => :model do

  let(:wp_tag) { Refinery::WordPress::Tag.new('ruby') }
  let(:refinery_tag) {wp_tag.to_refinery}
  let(:converting_a_tag){ ->(tag){tag.to_refinery} }

  describe "#name" do
    it "initializes a tag with the specified name" do
      expect(wp_tag.name).to eq('ruby' )
    end
  end

  describe "#==" do
    it 'is equivalent to a tag with the same name' do
      expect(wp_tag).to eq(Refinery::WordPress::Tag.new('ruby'))
    end
    it 'is not equivalent a tag with a different name' do
      expect(wp_tag).not_to eq(Refinery::WordPress::Tag.new('php'))
    end
  end

  describe "#to_refinery" do

    it "creates a Refinery::Tag with the same name as the WP tag" do
      expect(wp_tag.name).to eq(refinery_tag.name)
    end

    it "creates an ActsAsTaggableOn::Tag" do
      expect{converting_a_tag[wp_tag]}.to change(ActsAsTaggableOn::Tag, :count).by(1)
    end

  end

end

