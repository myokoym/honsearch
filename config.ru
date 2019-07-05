base_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(base_dir, "lib")
$LOAD_PATH.unshift(lib_dir)
require "honsearch/web/app"

ENV["HONSEARCH_HOME"] ||= File.join(base_dir, ".honsearch")
ENV["HONSEARCH_SUB_URL"] = ""

if ENV["HONSEARCH_ENABLE_CACHE"]
  require "racknga"
  require "racknga/middleware/cache"

  cache_database_path = File.join(base_dir, "var", "cache", "db")
  use Racknga::Middleware::Cache, :database_path => cache_database_path
end

run Honsearch::Web::App
