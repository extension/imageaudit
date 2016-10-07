set :deploy_to, "/services/imageaudit/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :vhost, 'dev-imageaudit.extension.org'
set :deploy_server, 'dev-imageaudit.aws.extension.org'
server deploy_server, :app, :web, :db, :primary => true
