# a = ["id", "sponsor_id", "ip_address", "created_at", "updated_at"]

# a.each do |col|
# 	puts col
# end

# @n = 0
# 3.times do
#   Thread.start { 100.times { @n += 1 } }
# end
# puts @n

# require 'rake'
system("rake sunspot:solr:start")
# Rake::Task['sunspot:solr:start'].invoke
# Rake.application["sunspot:solr:start"].invoke