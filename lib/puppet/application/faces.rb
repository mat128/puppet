require 'puppet/application'
require 'puppet/face'

class Puppet::Application::Faces < Puppet::Application

  should_parse_config
  run_mode :agent

  option("--debug", "-d") do |arg|
    Puppet::Util::Log.level = :debug
  end

  option("--verbose", "-v") do
    Puppet::Util::Log.level = :info
  end

  def help
    <<-HELP
puppet-faces(8) -- List available Faces and actions
========

SYNOPSIS
--------
Lists the available subcommands (with applicable terminuses and/or actions)
provided by the Puppet Faces API. This information is automatically read
from the Puppet code present on the system. By default, the output includes
all terminuses and actions.

USAGE
-----
puppet faces [-d|--debug] [-v|--verbose] [actions|terminuses]

OPTIONS
-------
Note that any configuration option valid in the configuration file is also
a valid long argument. See the configuration file documentation at
http://docs.puppetlabs.com/references/stable/configuration.html for the
full list of acceptable parameters. A commented list of all
configuration options can also be generated by running puppet agent with
'--genconfig'.

* --verbose:
  Sets the log level to "info." This option has no tangible effect at the time
  of this writing.

* --debug:
  Sets the log level to "debug." This option has no tangible effect at the time
  of this writing.

AUTHOR
------
Puppet Labs

COPYRIGHT
---------
Copyright (c) 2011 Puppet Labs, LLC Licensed under the Apache 2.0 License

    HELP
  end

  def list(*arguments)
    if arguments.empty?
      arguments = %w{terminuses actions}
    end
    faces.each do |name|
      str = "#{name}:\n"
      if arguments.include?("terminuses")
        begin
          terms = terminus_classes(name.to_sym)
          str << "\tTerminuses: #{terms.join(", ")}\n"
        rescue => detail
          puts detail.backtrace if Puppet[:trace]
          $stderr.puts "Could not load terminuses for #{name}: #{detail}"
        end
      end

      if arguments.include?("actions")
        begin
          actions = actions(name.to_sym)
          str << "\tActions: #{actions.join(", ")}\n"
        rescue => detail
          puts detail.backtrace if Puppet[:trace]
          $stderr.puts "Could not load actions for #{name}: #{detail}"
        end
      end

      print str
    end
  end

  attr_accessor :name, :arguments

  def main
    list(*arguments)
  end

  def setup
    Puppet::Util::Log.newdestination :console

    load_applications # Call this to load all of the apps

    @arguments = command_line.args
    @arguments ||= []
  end

  def faces
    Puppet::Face.faces
  end

  def terminus_classes(indirection)
    Puppet::Indirector::Terminus.terminus_classes(indirection).collect { |t| t.to_s }.sort
  end

  def actions(indirection)
    return [] unless face = Puppet::Face[indirection, '0.0.1']
    face.load_actions
    return face.actions.sort { |a, b| a.to_s <=> b.to_s }
  end

  def load_applications
    command_line.available_subcommands.each do |app|
      command_line.require_application app
    end
  end
end
