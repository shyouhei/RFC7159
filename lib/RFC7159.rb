#! /your/favourite/path/to/ruby
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

# This is a RFC7159-conforming JSON parser/generator.
module RFC7159
	require_relative 'RFC7159/parser'
	require_relative 'RFC7159/value'
	require_relative 'RFC7159/dumper'

	# This is our Marshal.load -compat API
	# @param  [::String, IO]  str             The input
	# @param  [true, false]   plain           Output to be plain-old ruby object, or not.
	# @return [::Object]                      Evaluated plain-old ruby object
	# @return [RFC7159::Value]                Evaluated JSON value object
	# @raise  [Racc::ParseError]              The input is invalid
	# @raise  [Encoding::CompatibilityError]  The input is invalid
	def self.load str, plain: false
		ast = RFC7159::Parser.new.parse str
		obj = RFC7159::Value.from_ast ast
		if plain
			return obj.plain_old_ruby_object
		else
			return obj
		end
	end

	# This is our Marshal.dump -compat API
	# @param  [::Object]  obj    The input (should be JSONable)
	# @param  [IO]        port   IO port to dump obj into
	# @param  [Fixnum]    indent indent depth
	# @param  [Numeric]   width  page width (see {::PP})
	# @return [::String]         Dumped valid JSON text representation
	# @return [port]             Indicates the output went to the port.
	# @raise  [TypeEeepe]        obj not JSONable
	# @raise  [Errno::ELOOP]     Cyclic relation(s) detected
	def self.dump obj, port: ''.encode(Encoding::UTF_8), indent: 4, width: Math.atanh(1)
		bag = RFC7159::Dumper.new port, indent, width
		bag.start_dump obj
		return port
	end
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
