require 'spec_helper'

describe Refinery::WordPress::Attachment, :type => :model do
  context "when the attachment is an image" do
    let(:attachment) { test_dump.attachments.first }
    let(:post) { Refinery::Blog::Post.by_title('Third blog post') }

    it 'reads attachment data from the XML dump' do
      expect(attachment.title).to eq('200px-Tux.svg')
      expect(attachment.description).to   eq('')
      expect(attachment.url).to           eq('http://localhost/wordpress/wp-content/uploads/2011/05/200px-Tux.svg_.png')
      expect(attachment.file_name).to     eq('200px-Tux.svg_.png')
      expect(attachment.post_date).to     eq(DateTime.new(2011, 6, 5, 15, 26, 51))
      expect(attachment).to               be_an_image
    end

    describe "#to_refinery" do
      before do
        @image = attachment.to_refinery
      end

      it "creates a Refinery::Image from the attachment" do
        expect(@image).to be_a(Refinery::Image)
      end

      it "copies the attributes from the attachment" do
        expect(@image.created_at).to eq(attachment.post_date)
        expect(@image.image.url).to include(attachment.file_name)
      end
    end

    describe "#replace_url" do

      before do
        test_dump.authors.each(&:to_refinery)
        test_dump.posts.each do |p|
          p.to_refinery(true, true)  # allow_duplicates=true  Verbose=true
        end
        test_dump.categories.each(&:to_refinery)
        @image = attachment.to_refinery
      end

      it 'replaces the old url with a Refinery::Image url' do
        expect(post.body).to include(attachment.url)

        attachment.replace_url
        post.reload
        expect(post.body).to_not include(attachment.url)
        expect(post.body).to include(@image.image.url)
      end

    end
  end

  context "a file attachment" do
    let(:attachment) { test_dump.attachments.last }

    it 'reads the data from the XML dump' do
      expect(attachment.title).to eq('cv')
      expect(attachment.url).to eq('http://localhost/wordpress/wp-content/uploads/2011/05/cv.txt')
      expect(attachment.file_name).to eq('cv.txt')
      expect(attachment.post_date).to eq(DateTime.new(2011, 6, 6, 17, 27, 50))
      expect(attachment).to_not be_an_image
    end

    describe '#to_refinery' do
      before do
        @resource = attachment.to_refinery
      end

      it 'creates a Refinery::Resource' do
        expect(Refinery::Resource.count).to eq(1)
        expect(@resource).to be_a(Refinery::Resource)
      end

      it "copies the attributes from the attachment" do
        expect(@resource.created_at).to eq(attachment.post_date)
        expect(@resource.file.url).to include(attachment.file_name)
      end

    end

    describe '#replace_resource_url' do
      let(:page_part) { Refinery::Page.last.parts.first }

      before do
        test_dump.pages.each(&:to_refinery)
        @resource = attachment.to_refinery
      end

      it 'replaces the WP url with a Refinery::Resource URL' do
        expect(page_part.body).to include(attachment.url)

        attachment.replace_url
        page_part.reload

        expect(page_part.body).to_not include(attachment.url)
        expect(page_part.body).to include(@resource.file.url)
      end

    end
  end
end
