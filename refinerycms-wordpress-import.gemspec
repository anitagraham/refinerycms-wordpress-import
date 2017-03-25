# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.name        = "refinerycms-wordpress-import"
  s.summary     = "Import WordPress XML dumps into refinerycms(-blog)."
  s.description = "This gem imports a WordPress XML dump into refinerycms (Page, User) and refinerycms-blog (BlogPost, BlogCategory, Tag, BlogComment)"
  s.version     = "3.1"
  s.date        = "2017-03-22"

  s.authors     = ['Marc Remolt', 'Marc Lee']
  s.email       = 'marc.remolt@googlemail.com'
  s.homepage    = 'https://github.com/mremolt/refinerycms-wordpress-import'

  s.add_dependency 'refinerycms-core', '~> 3.0'
  s.add_dependency 'refinerycms-blog', '~> 3.0'
  s.add_dependency 'acts-as-taggable-on'
  s.add_dependency 'nokogiri', '~> 1.6.0'
  s.add_dependency 'shortcode'

  # Development dependencies (usually used for testing)
  s.add_development_dependency 'refinerycms-testing'
  s.add_development_dependency 'database_cleaner'

  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.md"]
end

