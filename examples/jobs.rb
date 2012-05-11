$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'
require 'stalker'

Stalker.job 'send.email' do |args|
  Stalker.log "Sending email to #{args['email']}"
end

Stalker.job 'transform.image' do |args|
  Stalker.log "Image transform"
end

Stalker.job 'cleanup.strays' do |args|
  Stalker.log "Cleaning up"
end
