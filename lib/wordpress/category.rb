module Refinery
  module WordPress
    class Category
      attr_accessor :name

      def initialize(text)
        @name = text
      end

      def ==(other)
        name == other.name
      end

      def to_refinery
        cat = Refinery::Blog::Category.by_title(name)
        if cat.nil?
          cat = Refinery::Blog::Category.new(title: name)
          cat.save!
        end
        cat
      end
    end
  end
end

