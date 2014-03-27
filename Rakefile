#! /your/favourite/path/to/rake
# -*- coding: utf-8 -*-

# Copyright (c) 2014 Urabe, Shyouhei.  All rights reserved.
#
# Redistribution  and  use  in  source   and  binary  forms,  with  or  without
# modification, are  permitted provided that the following  conditions are met:
#
#     - Redistributions  of source  code must  retain the  above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     - Redistributions in binary form  must reproduce the above copyright
#       notice, this  list of conditions  and the following  disclaimer in
#       the  documentation  and/or   other  materials  provided  with  the
#       distribution.
#
#     - Neither the name of Internet  Society, IETF or IETF Trust, nor the
#       names of specific contributors, may  be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
# AND ANY  EXPRESS OR  IMPLIED WARRANTIES, INCLUDING,  BUT NOT LIMITED  TO, THE
# IMPLIED WARRANTIES  OF MERCHANTABILITY AND  FITNESS FOR A  PARTICULAR PURPOSE
# ARE  DISCLAIMED. IN NO  EVENT SHALL  THE COPYRIGHT  OWNER OR  CONTRIBUTORS BE
# LIABLE  FOR   ANY  DIRECT,  INDIRECT,  INCIDENTAL,   SPECIAL,  EXEMPLARY,  OR
# CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT   NOT  LIMITED  TO,  PROCUREMENT  OF
# SUBSTITUTE  GOODS OR SERVICES;  LOSS OF  USE, DATA,  OR PROFITS;  OR BUSINESS
# INTERRUPTION)  HOWEVER CAUSED  AND ON  ANY  THEORY OF  LIABILITY, WHETHER  IN
# CONTRACT,  STRICT  LIABILITY, OR  TORT  (INCLUDING  NEGLIGENCE OR  OTHERWISE)
# ARISING IN ANY  WAY OUT OF THE USE  OF THIS SOFTWARE, EVEN IF  ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'rubygems'
require 'bundler'
require 'rake'
require "bundler/gem_tasks"
begin
	Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
	$stderr.puts e.message
	$stderr.puts "Run `bundle install` to install missing gems"
	exit e.status_code
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
	spec.pattern = FileList['spec/**/*_spec.rb']
end

require 'yard'
YARD::Rake::YardocTask.new

task yard:  'lib/RFC7159/parser.rb'
task rdoc:  'lib/RFC7159/parser.rb'
task build: 'lib/RFC7159/parser.rb'
file 'lib/RFC7159/parser.rb' => %w'lib/RFC7159/parser.ry' do |t|
	sh "bundle exec racc --debug --output-file=#{t.name} #{t.prerequisites.first}"
end

desc "a la rails console"
task :console do
	require_relative 'lib/RFC7159'
	require 'json'
	require 'yajl'
	require 'oj'
	require 'irb'
	require 'irb/completion'
	ARGV.clear
	IRB.start
end

task default: :spec

# 
# Local Variables:
# mode: ruby
# coding: utf-8-unix
# indent-tabs-mode: t
# tab-width: 3
# ruby-indent-level: 3
# fill-column: 79
# default-justification: full
# End:
