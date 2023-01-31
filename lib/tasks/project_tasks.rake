namespace :project_tasks do

  desc 'Sync Project Task state from remote'
  task :sync_from_remote => :environment do
    print "*** Syncing Project Task states from remote..."
    ProjectTaskServices::Sync.new.pull_project_task_states
    puts "OK"
  end

end
