set :deploy_to, "/services/imageaudit/"
set :branch, 'master'
set :vhost, 'imageaudit.extension.org'
server vhost, :app, :web, :db, :primary => true
