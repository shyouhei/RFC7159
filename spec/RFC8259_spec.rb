#! /your/favourite/path/to/rspec
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

require_relative 'spec_helper'
require 'pathname'

describe RFC8259 do
	this_dir = Pathname.new __dir__

	describe '.load' do
		[
		 Encoding::UTF_8,
		 Encoding::UTF_16BE,
		 Encoding::UTF_16LE,
		 Encoding::UTF_32BE,
		 Encoding::UTF_32LE,
		].each do |enc|
			the_dir = this_dir + 'acceptance/valid'
			the_dir.find do |f|
				case f.extname when '.json'
					it "should accept: #{enc}-encoded #{f.basename}" do
						expect do
							f.open "rb", external_encoding: Encoding::UTF_8, internal_encoding: enc do |fp|
								RFC8259.load fp
							end
						end.to_not raise_exception
					end
				end
			end

			the_dir = this_dir + 'acceptance/invalid'
			the_dir.find do |f|
				case f.extname when '.txt'
					it "should reject: #{enc}-encoded #{f.basename}" do
						expect do
							f.open "rb", external_encoding: Encoding::UTF_8, internal_encoding: enc do |fp|
								RFC8259.load fp
							end
						end.to raise_exception
					end
				end
			end
		end
	end

	describe '.dump' do
		[
		 Encoding::UTF_8,
		 Encoding::UTF_16BE,
		 Encoding::UTF_16LE,
		 Encoding::UTF_32BE,
		 Encoding::UTF_32LE,
		].each do |enc|
			the_dir = this_dir + 'acceptance/valid'
			the_dir.find do |f|
				case f.extname when '.json'
				it "should round-trip in #{enc}: #{f.basename}" do
						str1 = f.open "rb", external_encoding: Encoding::UTF_8, internal_encoding: enc do |fp| fp.read end
						obj  = RFC8259.load str1
						str2 = RFC8259.dump obj
						str3 = str1.encode(Encoding::UTF_8)
						# not interested in indents
						expect(str2.gsub(/\s+/, '')).to eq(str3.gsub(/\s+/, ''))
					end
				end
			end
		end

		context 'from something outside JSON world' do
			{
				false             => 'false',
				true              => 'true',
				nil               => 'null',
				0                 => '0',
				0.5               => '0.5', # 0.5 has no error
				'foo'             => '"foo"',
				"\"\\\/\b\f\n\r\t"=> '"\"\\\/\b\f\n\r\t"',
				"\xED\xBA\xAD".force_encoding('utf-8')        => '"\\uDEAD"', # invalid UTF8 to be valid escaped UTF8
				'foo'.encode('utf-32le')              => '"foo"',
				"\xDE\xAD".force_encoding('utf-16be') => '"\\uDEAD"',
				[]                => '[ ]',
				[0]               => '[ 0 ]',
				[0,1]             => '[ 0, 1 ]',
				{}                => '{ }',
				{'1'=>1}          => '{ "1": 1 }',
				{''=>''}          => '{ "": "" }',
				(0.0/0.0)         => false,
				(1.0/0.0)         => false,
				BigDecimal("NaN") => false,
				//                => false,
				0..1              => false,
				{{}=>{}}          => false,
				{[]=>[]}          => false,
				{1=>1}            => false,
				{nil=>nil}        => false,
				Object.new        => false,
				Class.new         => false,
				Proc.new {}       => false,
			}.each_pair do |src, expected|
				if expected
					it { expect(RFC8259.dump src).to eq(expected) }
				else
					it { expect{RFC8259.dump src}.to raise_exception }
				end
			end

			it 'raises for loops' do
				expect do
					RFC8259.dump [].tap {|i| i << i }
				end.to raise_exception(Errno::ELOOP)
			end
		end
	end

	context 'versus', skip: true do
		the_dir     = this_dir + 'acceptance/valid'
		the_targets = Array.new
		the_dir.find do |f|
			case f.extname when '.json'
				begin
					f.open 'r:utf-8' do |fp|
						RFC8259.load fp, plain:true
					end
				rescue RuntimeError
					# there are cases JSON can't be represented in PORO
					# we ignore them here.
				else
					the_targets.push f
				end
			end
		end
		the_dir      = this_dir + 'acceptance/invalid'
		the_invalids = Array.new
		the_dir.find do |f|
			case f.extname when '.txt'
				the_invalids.push f
			end
		end

		require 'json'
		require 'oj'
		require 'yajl'
		targets = {
			JSON => {
				load: -> str {
					JSON.parse str
				},
				dump: -> obj {
					begin
						ret = JSON.generate obj
					rescue
						raise "JSON (not us) failed: #{$!.inspect}"
					else
						unless ret.valid_encoding?
							raise "JSON (not us) is broken: generated #{ret.dump}"
						end
						return ret
					end
				},
			},

			Oj   => {
				load: -> str {
					Oj.load str
				},
				dump: -> obj {
					begin
						ret = Oj.dump obj
					rescue
						raise "Oj (not us) failed: #{$!.inspect}"
					else
						unless ret.valid_encoding?
							raise "Oj (not us) is broken: generated #{ret.dump}"
						end
						return ret
					end
				},
			},

			Yajl => {
				load: -> str {
					Yajl::Parser.parse str, allow_comments: false, symbolize_keys: false
				},
				dump: -> obj {
					begin
						ret = Yajl::Encoder.encode obj
					rescue
						raise "Yajl (not us) failed: #{$!.inspect}"
					else
						unless ret.valid_encoding?
							raise "Yajl (not us) is broken: generated #{ret.dump}"
						end
						return ret
					end
				},
			},
		}

		targets.each_pair do |klass, howto|
			describe klass do
				the_invalids.each do |f|
					it "should reject: #{f.basename}" do
						begin
							theirs = f.open 'r:utf-8' do |fp|
								howto[:load].(fp.read)
							end
						rescue
							# ok
						else
							pending "#{klass} (not us) failed to reject: #{theirs.inspect}"
						end
					end
				end

				the_targets.each do |f|
					context f.basename do
						before :all do
							str   = f.open 'r:utf-8' do |fp| fp.read end
							@ours = RFC8259.load str, plain: true
							begin
								@theirs = howto[:load].(str)
							rescue
								pending "#{klass} (not us) failed to accept: #{$!.inspect}"
							end
							# JSON.load sometimes generates Infinity and that's not JSONable
							case @theirs when Array
								case @theirs[0] when Float
									if @theirs[0].infinite?
										pending "#{klass} (not us) generates non-JSONables: #{@theirs.inspect}"
									end
								end
							end
						end

						it "compare load" do
							if @ours != @theirs
								pending "They load differently: \n#{@ours.inspect} versus \n#{@theirs.inspect}"
							end
						end

						it "compare dump ours" do
							ours   = RFC8259.dump @ours
							theirs = howto[:dump].(@ours) rescue pending($!.message)
							if ours.gsub(/\s+/, '') != theirs.gsub(/\s+/, '')
								pending "They dump differently: \n#{ours.dump} versus \n#{theirs.dump}"
							end
						end

						it "compare dump theirs" do
							ours   = RFC8259.dump @theirs
							theirs = (howto[:dump].(@theirs) rescue pending($!.message))
							if ours.gsub(/\s+/, '') != theirs.gsub(/\s+/, '')
								pending "They dump differently: \n#{ours.dump} versus \n#{theirs.dump}"
							end
						end
					end
				end
			end
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
