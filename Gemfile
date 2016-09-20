source 'https://rubygems.org'

gem 'rails', '3.2.22.2'

# data
gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
# speed up sppppppprooooockets
gem 'turbo-sprockets-rails3'
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
  # files for bootstrap-in-asset-pipeline integration
  gem 'bootstrap-sass', '~> 3.1.1.1'
  # replaces glyphicons
  gem 'font-awesome-rails'
  # wysihtml5 + bootstrap + asset pipeline
  gem 'bootstrap-wysihtml5-rails'
end

# server settings
gem "config"

# authentication
gem 'omniauth', "~> 1.0"
gem 'omniauth-openid'

# jquery magick
gem 'jquery-rails'

# pagination
gem 'kaminari'

# background jobs
gem 'sidekiq'

# command line tools
gem 'thor'

# legacy data support
gem 'safe_attributes'

# jqplot
gem 'outfielding-jqplot-rails'

# exception handling
gem 'honeybadger'

# caching
gem 'redis-rails'

# cleaner log output
gem 'lograge'

# slack integration
gem "slack-notifier"

# exif data
gem 'mini_exiftool'

# mime type determination
gem 'mimemagic'

# breadcrumbs
gem "breadcrumbs_on_rails"

# html scrubbing
gem "loofah"

# Ruby 2.2 wtf
gem 'test-unit'

group :development do
  # require the powder gem
  gem 'powder'
  gem 'pry'
  gem 'httplog'
  gem 'capistrano', '~> 2.15.5'
  gem 'capatross', source: 'https://engineering.extension.org/rubygems'
  gem 'exdata', source: 'https://engineering.extension.org/rubygems'

  # moar advanced stats in dev only
  #gem 'gsl', :git => 'git://github.com/30robots/rb-gsl.git'
  #gem 'statsample-optimization', :require => 'statsample'

  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

end
