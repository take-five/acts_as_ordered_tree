appraise "rails3.0" do
  gem "activerecord", "~> 3.0.0"
  gem "activerecord-jdbcpostgresql-adapter", "~> 1.1.3", :platforms => :jruby if ENV['DB'] == 'pg'
  gem "activerecord-jdbcsqlite3-adapter", "~> 1.2.0", :platforms => :jruby if ENV['DB'] == 'sqlite3'
  gem "activerecord-jdbcmysql-adapter", "~> 1.1.3", :platforms => :jruby if ENV['DB'] == 'mysql'
end

appraise "rails3.1" do
  gem "activerecord", "~> 3.1.0"
end

appraise "rails3.2" do
  gem "activerecord", "~> 3.2.0"
end

appraise "rails4.0" do
  gem "activerecord", "~> 4.0.0"

  gem "activerecord-jdbcpostgresql-adapter", "~> 1.3.0", :platform => :jruby
  gem "activerecord-jdbcsqlite3-adapter", "~> 1.3.0", :platform => :jruby
  gem "activerecord-jdbcmysql-adapter", "~> 1.3.0", :platform => :jruby
end