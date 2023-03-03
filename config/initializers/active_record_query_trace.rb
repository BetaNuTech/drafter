# For documentation and configuration options, see:
#   https://github.com/brunofacca/active-record-query-trace

if Rails.env.development?
  ActiveRecordQueryTrace.enabled = ['1', 't', 'true'].include?(ENV.fetch('DEBUG', 'false'))
  # Optional: other gem config options go here:
  ActiveRecordQueryTrace.colorize = :light_purple
  #ActiveRecordQueryTrace.ignore_cached_queries = true
end
