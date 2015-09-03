class MakeMoreSensitive < ActiveRecord::Migration
  def up
    execute "ALTER TABLE `prod_imageaudit`.`hosted_images` CHANGE COLUMN `path` `path` TEXT CHARACTER SET utf8 COLLATE utf8_bin NULL  COMMENT '' AFTER `filename`;"
    HostedImageLink.rebuild
    Rebuild.do_it('all')
  end
end
