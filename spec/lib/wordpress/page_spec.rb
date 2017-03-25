require 'spec_helper'

describe Refinery::WordPress::Page, :type => :model do

  let(:dump) { test_dump }
  let(:page) { dump.pages.last }

  it 'creates a page from the XML dump file' do
    expect( page.title).to eq('About me')
    expect( page.content).to    include('Lorem ipsum dolor sit')
    expect( page.creator).to    eq('admin')
    expect( page.post_date).to  eq(DateTime.new(2011, 5, 21, 12, 25, 42))
    expect( page.post_id).to    eq(10)
    expect( page.parent_id).to  eq(8)

    expect( page).to eq(dump.pages.last)
    expect( page).not_to eq(dump.pages.first)
  end

  describe "#to_refinery" do
    include ::ActionView::Helpers::TagHelper
    include ::ActionView::Helpers::TextHelper

    # "About me" has a parent page with id 8 in the XML  dump,
    # would otherwise fails creation
    before do
      Refinery::Page.create! :id => 8, :title => 'About'
      @count = Refinery::Page.count
      @ref_page = page.to_refinery
    end

    it "creates a new Refinery Page" do
      expect(Refinery::Page.count).to eq @count + 1
    end

    it "copies the attributes from Refinery::WordPress::Page" do
      expect(@ref_page.title).to            eq(page.title)
      expect(@ref_page.draft).to            eq(page.draft?)
      expect(@ref_page.created_at).to       eq(page.post_date)
      expect(@ref_page.parts.first.body).to eq(page.content_formatted)
    end
  end

  describe "#format_paragraphs" do
    let(:sample_text) do
      text = <<-EOT
        This is sample text.

        Even more text.
        But this time no paragraph.
      EOT
    end

    before do
      @result = page.send(:format_paragraphs, sample_text)
    end

    it "adds paragraphs to the sample text" do
       expect(@result).to have_tag(:p)
    end
  end

  describe '#remove_inline_styles' do
    let(:sample_text) do
      text = <<-EOT
        <p><span style="font-size: medium; color: #000000; font-family: verdana,geneva;">Sometimes less than reputable companies make special offers that they have no intent
        ion of carrying out just to win the job. </span>
        <span style="font-size: medium; color: #000000; font-family: verdana,geneva;"> The reputation of the company you are dealing with is probably more important than any
         written warranty.</span>
        </p>
      EOT
    end

    before do
      @result = page.send(:remove_inline_styles, sample_text)
    end

    it 'removes style attributes from the text' do
      expect(@result).to have_tag(:span)
      expect(@result).to_not have_tag('span[style]')
      expect(@result).to match(/<span\s*>/)
    end
  end
  describe "#format_shortcodes" do

    describe '#rewrite ruby shortcode' do
      let(:sample_text) do
        text = <<-EOT
         [ruby]p "Hello World"[/ruby]
        EOT
      end

      before do
        @result = page.send(:format_shortcodes, sample_text)
      end
      puts @result
      it 'returns <pre/> markup' do
        expect(@result).to match(/<pre class='(.+?)'>.+?<\/pre>/).with_captures("brush: ruby")
      end
    end #rewrite ruby shortcode

    describe '#rewrite caption shortcode' do
      let(:sample_text) do
        text = <<-EOT
          [caption id="attachment_304" align="alignright" width="300"]
            <img class="size-medium wp-image-304"  title="Test Image Title"
                 src="200px_Tux.svg_.png" alt="Test Image Alt text" width="300" height="198" />Test Image Caption text[/caption]
        EOT
      end

      before do
        @result = page.send(:format_shortcodes, sample_text)
      end

      it '#returns <figure/> markup' do
        expect(@result).to have_tag(:figure) do |fig|
          expect(fig).to have_tag(:img)
          expect(fig).to have_tag(:figcaption)
        end #fig
      end

      it "strips out image width and height attributes" do
        expect(@result).to have_tag(:img)
        expect(@result).to_not have_tag('img[width]')
        expect(@result).to_not have_tag('img[height]')
        expect(@result).to_not have_tag('img[style]')
      end
    end #rewrite caption shortcode

    describe '#rewrite youtube shortcode' do
      let(:sample_text) do
        text = <<-EOT
          [youtube abcde 100 200]
        EOT
      end

      before do
        @result = page.send(:format_shortcodes, sample_text)
      end

      it 'returns iframe markup' do
        expect(@result).to have_tag(:p) do |para|
          expect(para).to have_tag(:iframe, with: {
            width: '100',
            height: '200',
            src: 'http://www.youtube.com/embed/abcde?version=3&rel=1&fs=1&showsearch=0&showinfo=1&iv_load_policy=1&wmode=transparent'
          })
        end #para
      end #it returns iframe markup
    end #rewrite youtube shortcode
  end #format_shortcodes

  describe "#format_base64_images" do
    let(:sample_text) do
    # the first image is a 10x10px red square, the second a 10x10px green square
      text = <<-EOT
        <img alt=""
          src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVJREFUeNpi/M+ADzAxjEpjAQABBgBBLAETbs/ntQAAAABJRU5ErkJggg==" />
        <p>a second image here:
<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAIAAAACUFjqAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABdJREFUeNpi7Dpqz4AbMDHgBSNVGiDAAOyEAaKfkePAAAAAAElFTkSuQmCC"/>

 /></p>
      EOT
    end

    before do
      @result = page.send(:format_base64_images, sample_text, 1000)
    end

    it 'returns a reference to img src files named for the post-id and image index' do
      expect(@result).to include("src='post1000-0.png'")
      expect(@result).to include("src='post1000-1.png'")
    end

    it 'creates files containing the decoded image' do
      expect(File.exist?("#{Rails.public_path}/post1000-0.png")).to be(true)
      expect(File.exist?("#{Rails.public_path}/post1000-1.png")).to be(true)
    end

    after do
      File.delete("#{Rails.public_path}/post1000-0.png")
      File.delete("#{Rails.public_path}/post1000-1.png")
    end
  end #format_base64_images

end

