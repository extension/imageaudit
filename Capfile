load 'deploy'
Dir['vendor/gems/*/recipes/*.rb','vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'
load 'deploy/assets'

require 'capistrano/honeybadger'