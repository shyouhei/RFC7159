#! /your/favourite/path/to/gem
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

# coding: utf-8

# hack avoid namespace pollution
path      = File.expand_path 'lib/RFC7159/version.rb', __dir__
content   = File.read path
version   = Module.new.module_eval <<-'end'
  RFC7159 = Module.new
  eval content, binding, path
end

Gem::Specification.new do |spec|
	spec.name          = 'RFC7159'
	spec.version       = version
	spec.authors       = %w'Urabe, Shyouhei'
	spec.email         = %w'shyouhei@ruby-lang.org'
	spec.summary       = 'RFC7159 parser / generator'
	spec.description   = <<-'end'.gsub(/[\n\s]+/, ' ').strip
		A  JSON  parser/generator  that  conforms  (I believe)  to  RFC7159  "The
		JavaScript Object Notation (JSON)  Data Interchange Format".  That RFC is
		very  different to  its predecessor  RFC4627, when  it comes  to parsing.
		This gem honors the updated syntax as possible.  The generator guarantees
		that  a  parsed  valid  properly  rounds-trip  to  identical  valid  JSON
		representation.
	end
	spec.homepage      = 'http://github.com/shyouhei/RFC7159'
	spec.license       = "Simplified BSD License" # consult LICENSE.txt

	spec.files         = `git ls-files -z`.split("\x0") + %w'lib/RFC7159/parser.rb'
	spec.executables   = %w''
	spec.test_files    = spec.files.grep(%r{^spec/})
	spec.require_paths = %w'lib'

	spec.required_ruby_version = '~> 2.0'
	spec.add_development_dependency 'bundler'
	spec.add_development_dependency 'rake'
	spec.add_development_dependency 'rdoc'
	spec.add_development_dependency 'yard'
	spec.add_development_dependency 'rspec'
	spec.add_development_dependency 'simplecov'
	spec.add_development_dependency 'racc'
	# racc runtime is inside ruby's stdlib so no runtime dependency.

	# below are only for comparisons
	spec.add_development_dependency 'json'      # 1.8.1 tested
	spec.add_development_dependency 'yajl-ruby' # 1.2.0 tested
	spec.add_development_dependency 'oj'        # 2.6.1 tested
end

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
