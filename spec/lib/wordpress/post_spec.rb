require 'spec_helper'

describe Refinery::WordPress::Post, type:  :model do

  let(:dump) { test_dump }
  let(:wp_post) { dump.posts.last }
  let(:convert_post) {
    ->(post, allow_duplicates=false, verbose=true) { post.to_refinery(allow_duplicates, verbose)}
  }

  it 'imports a post from the XML dump file' do
    expect( wp_post.title).to eq('Third blog post')
    expect( wp_post.content).to include('Lorem ipsum dolor sit')
    expect( wp_post.content_formatted).to start_with('<p>').and end_with('</p>')
    expect( wp_post.content_formatted).to include('Lorem ipsum dolor sit')
    expect( wp_post.creator).to eq('admin')
    expect( wp_post.post_date).to eq(DateTime.new(2011, 5, 21, 12, 24, 45))
    expect( wp_post.post_id).to eq(6)
    expect( wp_post.parent_id).to eq(nil)
    expect( wp_post.status).to eq('publish')
#     Refinery doesn't use meta_keywords
    # expect( wp_post.meta_keywords).to eq('key1, key2, key3')
    expect( wp_post.meta_description).to eq('meta description')

    expect(wp_post).to eq(test_dump.posts.last)
    expect(wp_post).not_to eq(test_dump.posts.first)

    expect(wp_post.categories.count).to eq(1)
    expect(wp_post.categories.first).to eq(Refinery::WordPress::Category.new('Rant'))

    expect(wp_post.tags.count).to eq(3)
    expect(wp_post.tags).to include(Refinery::WordPress::Tag.new('css'),
                                 Refinery::WordPress::Tag.new('html'),
                                 Refinery::WordPress::Tag.new('php'))
    expect(wp_post.tag_list).to eq('css,html,php')
  end

  describe "#comments" do
    it "returns all attached comments" do
      expect(wp_post.comments.count).to eq(2)
    end

    context "the last comment" do
      let(:wp_comment) { wp_post.comments.last }

      it "returns the comment's attributes" do
        expect( wp_post.comments.last.author).to eq('admin')
        expect( wp_comment.email).to             eq('admin@example.com')
        expect( wp_comment.url).to               eq('http://www.example.com/')
        expect( wp_comment.date).to              eq(DateTime.new(2011, 5, 21, 12, 26, 30))
        expect( wp_comment.content).to           include('Another one!')
        expect( wp_comment).to                   be_approved()
      end

      describe "#to_refinery" do
        let(:refinery_comment) {wp_comment.to_refinery}

        it "initializes a Refinery::Blog::Comment (not save it)" do
          expect(Refinery::Blog::Comment.count).to eq(0)
          expect(refinery_comment).to be_new_record
        end

        it "copies the attributes from Refinery::WordPress::Comment" do
          expect(refinery_comment.name).to eq(wp_comment.author)
          expect(refinery_comment.email).to eq(wp_comment.email)
          expect(refinery_comment.body).to eq(wp_comment.content)
          expect(refinery_comment.state).to eq('approved')
          expect(refinery_comment.created_at).to eq(wp_comment.date)
          expect(refinery_comment.created_at).to eq(wp_comment.date)
        end
      end
    end
  end

  describe "#to_refinery" do
    before do
      @user = Refinery::Authentication::Devise::User.create! username:  'admin', email:  'admin@example.com',
        password:  'password', password_confirmation:  'password'
    end


    describe "with new title" do
      let(:refinery_post){convert_post[wp_post] }

      it 'adds a Refinery::Blog post' do
        expect{convert_post[wp_post]}.to change(Refinery::Blog::Post, :count).by(1)
      end

      it 'saves a refinery post with all attributes' do

        expect(refinery_post).to have_attributes(
           title: wp_post.title,
          body: wp_post.content_formatted,
          draft: wp_post.draft?,
          published_at: wp_post.post_date,
          meta_description: wp_post.meta_description)
      end

      it "assigns a category for each Refinery::WordPress::Category assigned to this post" do
        expect(refinery_post.categories.count).to eq(wp_post.categories.count)
      end

      it "creates a comment for each Refinery::WordPress::Comment attached to this post" do
        expect(refinery_post.comments.count).to eq(wp_post.comments.count)
      end
    end

    describe "with a duplicate title" do
      before do
        # create a post with the same title as ours
        Refinery::Blog::Post.create! title: wp_post.title, body: 'Lorem', author:  @user, published_at:  Time.now
      end

      context 'when duplicate titles are not allowed' do

        it 'raises an error' do
          expect{convert_post[wp_post, false]}.to raise_error("Duplicate title #{wp_post.title}. Post not imported.")
        end
      end

      context 'when duplicate titles are allowed' do
        let(:refinery_post){convert_post[wp_post,  true] }

        it 'saves a post' do
          expect{convert_post[wp_post, true]}.to change(Refinery::Blog::Post, :count).by(1)
        end

        it "appends a counter to the original title" do
          expect(refinery_post.title).to match(/#{Regexp.quote(wp_post.title)}-\d/)
        end

        describe 'saves the post with all attributes and associations' do
          it "the Refinery::Post has the same number of categories as the WP post" do
            expect(refinery_post.categories.count).to eq(wp_post.categories.count)
          end

          it "the Refinery::Post has the same number of comments as the WP post" do
            expect(refinery_post.comments.count).to eq(wp_post.comments.count)
          end
        end
      end

    end
  end
end
