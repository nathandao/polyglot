require "resque/tasks"

# Load rails evironment when worker starts
task "resque:setup" => :environment