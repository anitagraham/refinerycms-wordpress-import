require 'wordpress'

namespace :wordpress do

  BLOG_TABLES  = %w(ActsAsTaggableOn::Tag Refinery::Blog::Post Refinery::Blog::Category)
  CMS_TABLES   = %w(Refinery::Page)
  MEDIA_TABLES = %w(Refinery::Image Refinery::Resource)

# ------------------------------------- Begin blog processing tasks --------------------------------------------------
 desc 'Reset the blog tables for a clean import'
  task :reset_blog do
    Rake::Task['environment'].invoke
    clear_tables(BLOG_TABLES)
  end

  desc "Import categories from a Refinery::WordPress XML dump"
  task :import_categories, :file_name do |task, params|

    Rake::Task['environment'].invoke
    raise "Please specify file_name as a rake parameter (use [filename] after task_name...)" if params[:file_name].nil?

    dump = Refinery::WordPress::Dump.new(params[:file_name])
    puts "Importing #{dump.categories.count} categories ..."  unless silent
    dump.categories.each(&:to_refinery)

  end

  desc "Import tags from a Refinery::WordPress XML dump"
  task :import_tags, :file_name do |task, params|

    Rake::Task['environment'].invoke
    raise "Please specify file_name as a rake parameter (use [filename] right after task_name. No spaces)" if params[:file_name].nil?

    dump = Refinery::WordPress::Dump.new(params[:file_name])
    puts "Importing #{dump.tags.count} tags ..."  unless silent
    dump.tags.each(&:to_refinery)

  end

  desc "Import blog data from a Refinery::WordPress XML dump"
  task :import_blog, :file_name do |task, params|

    Rake::Task['environment'].invoke
    raise "Please specify file_name as a rake parameter (use [filename] after task_name...)" if params[:file_name].nil?

    dump = Refinery::WordPress::Dump.new(params[:file_name])

    puts "Importing #{dump.authors.count} authors ..."
    dump.authors.each(&:to_refinery)

    puts "Importing #{dump.posts(only_published).count} #{only_published ? 'published' : '(all)'} posts"  unless silent
    puts "Duplicate titles #{allow_duplicate_titles ? '' : 'not '}allowed."  unless silent

    dump.posts(only_published).each do |p|
      puts "Importing post #{p.title}"  unless silent
      p.to_refinery(allow_duplicate_titles)
    end
    Refinery::WordPress.create_page_if_necessary('blog')
  end

  desc 'Reset blog tables and then import blog data from a Refinery::WordPress XML dump'
  task :reset_and_import_blog, :file_name do |task, params|
    Rake::Task['wordpress:reset_blog'].invoke
    Rake::Task['wordpress:import_blog'].invoke(params[:file_name])
  end
# ------------------------------------- End blog processing tasks ----------------------------------------------------

# ------------------------------------- Begin CMS processing tasks ---------------------------------------------------

  desc 'Reset the CMS relevant tables for a clean import'
  task :reset_pages, [:id_offset] do |task, params|
    Rake::Task['environment'].invoke
    params.with_defaults :id_offset => 0
    clear_tables(CMS_TABLES, params[:id_offset].to_i)
  end

  desc 'Import CMS data from a WordPress XML dump'
  task :import_pages, [:file_name, :id_offset, :page_parent] do |task, params|

    Rake::Task['environment'].invoke
    raise "Please specify file_name as a rake parameter (use [filename] after task_name...)" if params[:file_name].nil?

    params.with_defaults :id_offset => 0
    params.with_defaults :page_parent => 'blog'
    offset = params[:id_offset].to_i

    only_published = ENV['ONLY_PUBLISHED'].present?

    puts "Importing #{dump.pages(only_published).count} #{only_published ? 'published' : '(all)'} pages"  unless silent
    dump.pages(only_published).each do |p|
      p.to_refinery(offset)
    end
#   Create the parent page for the blog pages
    Refinery::WordPress.create_page_if_necessary(params[:page_parent])

    # After all pages are persisted we can now create the parent - child
    # relationships. This is necessary, as WordPress doesn't dump the pages in
    # a correct order.
    puts 'Linking pages to their parents'  unless silent
    default_parent_page_id = Refinery::Page.where('slug = ?', "#{params[:page_parent]}").first.id
    dump.pages(only_published).each do |dump_page|
      page = Refinery::Page.find(dump_page.post_id + offset)
      page.parent_id = dump_page.parent_id ?  dump_page.parent_id + offset : default_parent_page_id
      page.save!
    end
  end

  desc 'Reset CMS tables and then import CMS data from a WordPress XML dump'
  task :reset_and_import_pages, :file_name, :id_offset do |task, params|
    Rake::Task['wordpress:reset_pages'].invoke(params[:id_offset])
    Rake::Task['wordpress:import_pages'].invoke(params[:file_name],params[:id_offset],params[:page_parent])
  end

# ------------------------------------- End page processing tasks ----------------------------------------------------

# ------------------------------------- Begin media processing tasks -------------------------------------------------

  desc 'Reset the media tables for a clean import'
  task :reset_media, [:id_offset ]do |task, params|
    Rake::Task['environment'].invoke
    params.with_defaults :id_offset => 0
    clear_tables(MEDIA_TABLES, params[:id_offset].to_i)
  end

  desc 'Import media data (images and files) from a WordPress XML dump and replace target URLs in pages and posts'
  task :import_media, :file_name do |task, params|
    Rake::Task['environment'].invoke
    raise "Please specify file_name as a rake parameter (use [filename] after task_name...)" if params[:file_name].nil?

    dump = Refinery::WordPress::Dump.new(params[:file_name])

    puts 'Importing images and resources'  unless silent
    attachments = dump.attachments.each(&:to_refinery)

    # parse all created BlogPost and Page bodys and replace the old wordpress media urls
    # with the newly created ones
    puts 'Linking images and resources to posts and pages'  unless silent
    attachments.each do |attachment|
      attachment.replace_url
    end
  end

  desc 'Reset media tables and then import media data from a WordPress XML dump'
  task :reset_and_import_media,[ :file_name, :id_offset] do |task, params|
    Rake::Task['wordpress:reset_media'].invoke(params[:id_offset])
    Rake::Task['wordpress:import_media'].invoke(params[:file_name])
  end
# ------------------------------------- End media processing tasks ---------------------------------------------------

  desc 'Reset and import all data (see the other tasks)'
  task :full_import, [:file_name, :page_id_offset, :page_parent, :media_id_offset] do |task, params|
    Rake::Task['wordpress:reset_and_import_blog'].invoke(params[:file_name])
    Rake::Task['wordpress:reset_and_import_pages'].invoke(params[:file_name],params[:page_id_offset],params[:page_parent])
    Rake::Task['wordpress:reset_and_import_media'].invoke(params[:file_name],params[:media_id_offset])
  end
# ------------------------------------- End full import task ---------------------------------------------------------

# ------------------------------------- utilities -------------------------------------------------------------
  def silent
    ENV['SILENT'].present?
  end

  def allow_duplicate_titles
    ENV['ALLOW_DUPLICATES'].present?
  end

  def only_published
    ENV['ONLY_PUBLISHED'].present?
  end

  def clear_tables(tables, offset=0)

    tables.each do |table_name|
      # deletes dependent records as well.
      puts "Deleting records with ids>#{offset} from #{table_name} ..." unless silent
      table_name.constantize.where('id>?', offset).destroy_all

    end
  end

# ------------------------------------- End utilities ----------------------------------------------------
end
