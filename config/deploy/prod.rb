set :deploy_to, "/services/imageaudit/"
set :branch, 'master'
set :vhost, 'imageaudit.extension.org'
set :deploy_server, 'imageaudit.awsi.extension.org'
server deploy_server, :app, :web, :db, :primary => true
