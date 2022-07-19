# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# == Standard Procedure ====
# - Include the Seeds:Seedable concern in the model.
# - Create Rake task in lib/tasks/seeds.rb
# - Create Seed data YML in db/seeds/
# - Add entry below to invoke the seed rake task

puts "*** Seeding Roles"
Rake::Task["db:seed:roles"].invoke

puts "*** Seeding Project Roles"
Rake::Task["db:seed:project_roles"].invoke

puts "*** Seeding Users"
Rake::Task["db:seed:users"].invoke

