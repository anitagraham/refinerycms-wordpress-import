require 'spec_helper'

describe Refinery::WordPress::Author, :type => :model do
  let(:author) { test_dump.authors.first }

  # specify { author.login.to == 'admin' }
  # specify { author.email.to == 'admin@example.com' }

  describe "#to_refinery" do
    before do
      @user = author.to_refinery
    end

    it "creates a User object" do
      expect(Refinery::Authentication::Devise::User.count).to eq(1)
    end

    it 'returns a Refinery user' do
      expect(@user).to be_a(Refinery::Authentication::Devise::User)
    end

    it 'assigns the role "Refinery" to the user' do
      expect(@user.roles.first.title).to eq('Refinery')
    end

    it "persists the user" do
      expect(@user).to be_persisted
    end

    it "copies the attributes from Refinery::WordPress::Author" do
      expect(@user.username).to eq(author.login)
      expect(@user.email).to eq(author.email)
    end
  end
end
