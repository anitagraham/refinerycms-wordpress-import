module Refinery
  module WordPress

    def self.create_page_if_necessary(slug)
      unless Refinery::Page.where("link_url = ?", "/#{slug}").exists?
        page = Refinery::Page.create(
          :title => "Blog",
          :link_url => "/blog",
          :deletable => false,
          # :position => ((Refinery::Page.maximum(:position, :conditions => {:parent_id => nil}) || -1)+1),
          :menu_match => "^/blogs?(\/|\/.+?|)$"
        )

        Refinery::Pages.default_parts.each do |default_page_part|
          page.parts.create(:title => default_page_part, :body => nil)
        end
      end
    end

    class Page
      include ::ActionView::Helpers::TagHelper
      include ::ActionView::Helpers::TextHelper

      attr_reader :node

      def initialize(node)
        shortcode_setup
        @node = node
      end

      def inspect
        "WordPress::Page(#{post_id}): #{title}"
      end

      def title
        node.xpath("title").text.presence || 'Title'
      end

      def content
        node.xpath("content:encoded").text
      end

      def content_formatted
         formatted = remove_inline_styles(format_paragraphs(format_shortcodes(format_base64_images(content, post_id))))

        # # remove all tags inside <pre> that simple_format created
        # # TODO: replace format_paragraphs with a method, that ignores pre-tags
        # formatted.gsub!(/(<pre.*?>)(.+?)(<\/pre>)/m) do |match|
          # "#{$1}#{strip_tags($2)}#{$3}"
        # end

        formatted
      end

      def creator
        node.xpath("dc:creator").text
      end

      def post_date
        DateTime.parse node.xpath("wp:post_date").text
      end

      def post_id
        node.xpath("wp:post_id").text.to_i
      end

      def parent_id
        dump_id = node.xpath("wp:post_parent").text.to_i
        dump_id == 0 ? nil : dump_id
      end

      def status
        node.xpath("wp:status").text
      end

      def draft?
        status != 'publish'
      end

      def published?
        ! draft?
      end

      def ==(other)
        post_id == other.post_id
      end

      def to_refinery(id_offset=0)
        page = Refinery::Page.create!(
         {:id => post_id + id_offset,
          :title => title,
          :created_at => post_date,
          :draft => draft?
         })

        page.parts.create(:title => 'Body', :body => content_formatted)
        page
      end

      private

      def format_paragraphs(text, html_options={})
        # WordPress doesn't export <p>-Tags, so let's run a simple_format over
        # the content. As we trust ourselves, no sanitize. This code is heavily
        # inspired by the simple_format rails helper
        text = ''.html_safe if text.nil?
        start_tag = tag('p', html_options, true)

        text.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
        text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}")  # 2+ newline  -> paragraph
        text.insert 0, start_tag

        text.html_safe.safe_concat("</p>")
      end

      def remove_inline_styles(text)
#         so many inline styles
        text = ''.html_safe if text.nil?
        return text.gsub(/style\s*=\s*"[^"]*"[^>]*/,' ')
      end

      # def format_syntax_highlighter(text)
        # # Support for SyntaxHighlighter (http://alexgorbatchev.com/SyntaxHighlighter/):
        # # In WordPress you can (via a plugin) enclose code in [lang][/lang]
        # # blocks, which are converted to a <pre>-tag with a class corresponding
        # # to the language.
        # #
        # # Example:
        # # [ruby]p "Hello World"[/ruby]
        # # -> <pre class="brush: ruby">p "Hello world"</pre>
        # text.gsub(/\[(\w+)\](.+?)\[\/\1\]/m, '<pre class="brush: \1">\2</pre>')
      # end


      # Replace Wordpress shortcodes with formatted HTML (see shortcode gem and support/templates folder)
      def format_shortcodes(text)
        # preprocess to replace badly formatted shortcodes with syntactically correct shortcodes
        # [youtube id width height] -> [youtube id="id" width="width" height="height"]
        Shortcode.process(text.gsub(/\[youtube\s+?(\w*?)\s+?(\d+)\s+?(\d+)\s*\]/, '[youtube id="\1" width="\2" height="\3"]'))
      end

#       Replace bas64 encoded images with a file reference. Write the file out
      def format_base64_images(text, id)

        matchString = /src="data:image\/(\w+?);base64,(.*?)"/
        matches = text.scan(matchString)
        matches.each_with_index do |(mimetype, b64), ix|

          unless b64.nil?
            filename = 'post' + id.to_s + '-' + ix.to_s + '.' + mimetype
            fullfilespec = "#{Rails.public_path}/#{filename}"
            File.open(fullfilespec, 'wb') do |f|
              f.write(Base64.decode64(b64))
            end
            text.sub!(matchString, "src='#{filename}'")
          end

        end
        text
      end

      def shortcode_setup
        Shortcode.setup do |config|
          # the template parser to use
          config.template_parser = :haml # :erb or :haml supported, :haml is default

           # location of the template files
          config.template_path = ::File.join(::File.dirname(__FILE__), "..", "..","support/templates/haml")

          # a list of block tags to support e.g. [quote]Hello World[/quote]
          config.block_tags = [:caption, :column, :quote, :ruby]

          # a list of self closing tags to support e.g. [youtube id="12345"]
          config.self_closing_tags = [:end_columns,  :youtube]
        end
      end
    end
  end
end
