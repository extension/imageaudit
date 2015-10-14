set :deploy_to, "/services/imageaudit/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :vhost, 'dev-imageaudit.extension.org'
server vhost, :app, :web, :db, :primary => true
