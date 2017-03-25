module Refinery
  module WordPress
    class Post < Page
      def tags
        # xml dump has "post_tag" for wordpress 3.1 and "tag" for 3.0
        path = if node.xpath("category[@domain='post_tag']").count > 0
          "category[@domain='post_tag']"
        else
          "category[@domain='tag']"
        end

        node.xpath(path).collect do |tag_node|
          Tag.new(tag_node.text.strip)
        end
      end

      def tag_list
        tags.collect(&:name).join(',')
      end

      def categories
        node.xpath("category[@domain='category']").collect do |cat|
          Category.new(cat.text.strip)
        end
      end

      def cat_list
        categories.collect(&:name).to_sentence
      end

      def meta_keywords
        if node.xpath('//wp:postmeta[wp:meta_key="_msp_keywords"]/wp:meta_value').count > 0
          node.xpath('//wp:postmeta[wp:meta_key="_msp_keywords"]/wp:meta_value').first.content.strip!
        end
      end

      def meta_description
        if node.xpath('//wp:postmeta[wp:meta_key="_msp_description"]/wp:meta_value').count > 0
          node.xpath('//wp:postmeta[wp:meta_key="_msp_description"]/wp:meta_value').first.content.strip!
        end
      end

      def comments
        node.xpath("wp:comment").collect do |comment_node|
          Comment.new(comment_node)
        end
      end

      def to_refinery(allow_duplicates=false, verbose=false)
        user = ::Refinery::Authentication::Devise::User.find_by_email(creator) || ::Refinery::Authentication::Devise::User.first
        raise "Referenced User doesn't exist! Make sure the authors are imported first."  unless user

        # if the title has already been taken (WP allows duplicates here, refinery doesn't) append a counter to the title

        safe_title = title
        if allow_duplicates
          counter = 0
          while Refinery::Blog::Post.exists?(title: safe_title) do
            safe_title = "#{title}-#{counter+=1}"
          end
        end

        begin
          post = ::Refinery::Blog::Post.new title:  safe_title, body:  content_formatted,
            draft:  draft?, published_at:  post_date,
            user_id:  user.id, tag_list:  tag_list, meta_description:  meta_description
          post.created_at = post_date
          post.save!

          ::Refinery::Blog::Post.transaction do
            categories.each do |category|
              post.categories << category.to_refinery
            end

            comments.each do |comment|
              comment = comment.to_refinery
              comment.post = post
              comment.save
            end
          end
        rescue Exception => e
          if e.message=="Validation failed: Title has already been taken"
            raise "Duplicate title #{safe_title}. Post not imported." unless !verbose
          else
            raise
          end
       end
       post
      end


    end
  end
end
