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

require_relative 'value'
require 'prettyprint'

# Dumps ruby object into JSON string
class RFC7159::Dumper

	# @param [#<<]  port  output destination
	def initialize port
		@port = port
		@bag  = Hash.new
		@pp   = PrettyPrint.new @port
		@bag.compare_by_identity
	end

	# @param  [::Object] target  target to dump
	# @return [self]             self.
	def start_dump target
		dump target
		return self
	ensure
		@bag.clear
		@pp.flush
	end

	private

	def dump obj
		obj2 = try_convert obj
		case obj2
		when ::Array, RFC7159::Array then
			ensure_unique obj2
			@pp.group 1, '[', ']' do
				obj2.each.with_index do |i, j|
					@pp.text ',' if j > 0
					@pp.breakable ''
					dump i
				end
			end
		when ::Hash, RFC7159::Object then
			ensure_unique obj2
			@pp.group 1, '{', '}' do
				obj2.each_pair.with_index do |(i, j), k|
					@pp.text ',' if k > 0
					@pp.breakable ''
					case i
					when ::String, RFC7159::String
						dump i
					else
						dump i.to_str # should raise for non-string-ish
					end
					@pp.text ':'
					dump j
				end
			end
		when RFC7159::Value then
			obj3 = obj2.to_json
			@pp.text obj3
		when ::String then
			obj3 = try_escape_string obj2
			@pp.text '"'
			@pp.text obj3
			@pp.text '"'
		when ::Numeric then
			obj3 = try_stringize_numeric obj2
			@pp.text obj3
		when ::TrueClass then
			@pp.text 'true'
		when ::FalseClass then
			@pp.text 'false'
		when ::NilClass then
			@pp.text 'null'
		else
			begin
				# Try fallback
				@pp.text obj2.to_json
			rescue NoMethodError
				raise TypeError, "not JSONable: #{obj}"
			end
		end
	end

	# Check repetition.  JSON is a true tree -- no cyclic lists, nor even direct
	# acyclic graphs are allowed.  We check that here.
	#
	# - strings, numbers, booleans are all OK to appear multiple times.
	# - empty arrays and empty hashes are special-cased OK.
	# - other cases are subject to appear exactly once.
	def ensure_unique obj
		if @bag.include? obj and not obj2.empty?
			raise Errno::ELOOP, "target appears twice: #{target.inspect}"
		else
			@bag.store obj, obj
		end
	end

	def try_convert obj
		case obj
		when RFC7159::Value, Hash, Array, String, Integer, Float, BigDecimal, TrueClass, FalseClass, NilClass
			return obj
		else
			begin
				return obj.to_hash
			rescue NoMethodError
				begin
					return obj.to_ary
				rescue NoMethodError
					begin
						return obj.to_str
					rescue NoMethodError
						begin
							return obj.to_int
						rescue NoMethodError
							begin
								return obj.to_f
							rescue NoMethodError
								raise TypeError, "not JSONable: #{obj.class}"
							end
						end
					end
				end
			end
		end
	end

	def try_escape_string str
		buf = nil

		begin
			# fast path
			if str.valid_encoding?
				str2 = str.encode Encoding::UTF_8
				buf  = str2.unpack('U*')
			end
		rescue Encoding::UndefinedConversionError
			# str might be invalid, but that's OK as per RFC7159 section 8.2.
		end

		unless buf
			case str.encoding
			when Encoding::UTF_32BE then buf = str.unpack 'N*'
			when Encoding::UTF_32LE then buf = str.unpack 'V*'
			when Encoding::UTF_16BE then buf = str.unpack 'n*'
			when Encoding::UTF_16LE then buf = str.unpack 'v*'
			when Encoding::UTF_8,
			     Encoding::UTF8_MAC,
			     Encoding::US_ASCII then buf = str.unpack 'U*'
			else                         buf = str.unpack 'C*' # fallback
			end
		end

		# We don't escape \/, because that seems to be de facto standard.
		return buf.inject '' do |r, i|
			c = nil
			case i
			when 0x22 then c = '\\"'  # "    quotation mark  U+0022
			when 0x5C then c = '\\\\' # \    reverse solidus U+005C
		#	when 0x2F then c = '\\/'  # /    solidus         U+002F
			when 0x08 then c = '\\b'  # b    backspace       U+0008
			when 0x0C then c = '\\f'  # f    form feed       U+000C
			when 0x0A then c = '\\n'  # n    line feed       U+000A
			when 0x0D then c = '\\r'  # r    carriage return U+000D
			when 0x09 then c = '\\t'  # t    tab             U+0009
			when 0x00..0x1F, 0xD800..0xDFFF then
				c = sprintf '\\u%04X', i
			else
				c = [i].pack 'U'
			end
			r << c
		end
	end

	def try_stringize_numeric num
		case num
		when Float, BigDecimal
			if num.finite?
				# FIXME: does this lose precision?
				num.to_s
			else
				raise TypeError, "not JSONable: #{num.inspect}"
			end
		when Integer
			return num.to_s
		else
			raise TypeError, "not JSONable: #{num.inspect}"
		end
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
