# encoding: utf-8

# Copyright (c) 2014, HipByte SPRL and contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

begin
  require 'bundler'
rescue LoadError
  abort "Please make sure you have 'bundler' gem installed and try again."
end

require 'erb'
require 'fileutils'

module Motion; class Command
  class Gem < Command
    DefaultOS = 'ios'
    self.summary = 'Create a RubyMotion gem.'

    self.description = %q(Create a RubyMotion specific gem.
You can choose what operating system you wish to targed by
using the '--os' switch, with the values of either:

  - 'ios' for iOS
or
  - 'osx' for OS X

Omitting the value, defaults to iOS.)

    def initialize(argv)
      @name = argv.shift_argument
      @os = argv.option('os') || DefaultOS
      super
    end

    self.arguments = 'GEM-NAME'

    def validate!
      super
      help! "Specify a vaild OS: ios or osx." unless valid_os?
      help! "Specify a gem name." unless @name
    end

    def self.options
      [
        ['--os=[ios|osx]', "Operating system for the gem, defaults to iOS"],
      ].concat(super)
    end

    def run
      bundle_gem_create
      add_rubymotion_specifics
    end

    def bundle_gem_create
      system "bundle gem #{@name}"
    end

    def add_rubymotion_specifics
      modify_rakefile
      copy_rubymotion_gitignore
      copy_app_files
      copy_lib_files
      copy_spec_files
      git_add_all
    end

    private

    def valid_os?
      @os =~ /\A(ios|osx)\Z/
    end

    def modify_rakefile
      render_and_write "#{$motion_libdir}motion/gem/templates/Rakefile.erb", "#{@name}/Rakefile"
    end

    def render_and_write template, destination
      rendered = ERB.new File.read(template)
      File.open(destination, 'w') { |file| file.write(rendered.result(binding)) }
    end

    def copy_rubymotion_gitignore
      motion_gitignore = "#{$motion_libdir}motion/gem/templates/.gitignore"
      FileUtils.cp(motion_gitignore, "#{@name}/.gitignore")
    end

    def copy_app_files
      app_dir = "#{@name}/app"
      FileUtils.mkdir_p app_dir
      templates_dir = "#{$motion_libdir}motion/gem/templates"
      source_files = Dir.glob "#{templates_dir}/#{os_files}"

      source_files.each do |file|
        FileUtils.cp file, app_dir
        file_name = file.gsub("#{templates_dir}/#{@os}/", '')
        log "#{@name}/#{file_name}"
      end
    end

    def copy_lib_files
      lib_file_dir = "#{@name}/lib/#{@name}"
      lib_file_name = "#{lib_file_dir}.rb"
      templates_dir = "#{$motion_libdir}motion/gem/templates/#{@os}/"
      lib_file_template = "#{templates_dir}lib/gem_name.rb.erb"

      render_and_write lib_file_template, lib_file_name
      log lib_file_name
    end

    def copy_spec_files
      spec_dir = "#{@name}/spec"
      FileUtils.mkdir_p spec_dir

      template = "#{$motion_libdir}motion/gem/templates/#{@os}/spec/main_spec.rb.erb"
      spec_file_path = "#{spec_dir}/main_spec.rb"
      render_and_write template, spec_file_path
      log spec_file_path
    end

    def os_files
      path = "#{@os}/app"
      @os == "ios" ? "#{path}/app_delegate.rb" : "#{path}/*.rb"
    end

    def log file
      what = "\e[1m\e[32m" + "create".rjust(12) + "\e[0m" # Bold Green
      $stderr.puts "#{what}  #{file}"
    end

    def git_add_all
      system "cd #{@name}; git add ."
    end
  end
end; end