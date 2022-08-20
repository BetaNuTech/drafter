if ENV.fetch('NO_TEST_COVERAGE','') == 'true'
  # See Guardfile cmd: to toggle this option when running with Guard
  # Coverage is disabled because Guard will run partial tests
  puts "*** Skipping Test Coverage Report"
else
  # SimpleCov for coverage reports at coverage/index.html
  # If using dev container, viewable at http://localhost:3000/coverage/
  #
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_group 'Channels', 'app/channels'
    add_group 'Controllers', 'app/controllers'
    add_group 'Helpers', 'app/helpers'
    add_group 'Jobs', 'app/jobs'
    add_group 'Mailers', 'app/mailers'
    add_group 'Models', 'app/models'
    add_group 'Policies', 'app/policies'
    add_group 'Services', 'app/services'
  end
end
