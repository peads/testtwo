# TestTwo, by Patrick Eads, http://testtwo.sourceforge.net
# Version 0.1
# Copyright (C) 2010, Patrick Eads peads@users.sourceforge.net
#
# This file is part of TestTwo
#
# TestTwo is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>,
# or write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307, USA.


# The author's description of TestTwo:
#
# TestTwo is a modification of James Bach's Allpairs program that was written
# in Perl.  Ruby was selected for its ability to easily interface with C (the stand-
# ard implementation of the interpreter being written in that language).  This
# was required since the external interface libraries for Matlab/Simulink are 
# written in C as are many external interfaces.
# Some features include:
# 	-A command-line interface allowing view, save, generate and export features
#		in a more user friendly, albeit simple, manner
#	-Output of test cases to text (tab-seperated) and csv
#	-Export of the test cases to a Matlab formatted text file
#	-Ability to permute ranges and produce randomized values for input
#		within those ranges.  That is, if one has an input that takes
#		a continuous range of values, then one would break the expected
#		(base range) into sub-ranges distributed in some fashion.  The
#		program will then permute the test cases and produce a pseudo-
#		random value (strictly) within that sub-range.
#	-Almost of the features available in the cli are also possible when
#		calling the program from the shell


# Allpairs, as described by James Bach:
#
# This program attempts to find the smallest number of test cases that
# include all pairings of each variable with each other variable.
#
# All permutations of each variable is easy, all pairs is much harder.
# The way this program works is that it makes a checklist of every pair of
# variables, and checks each pair off as it packs it into a test case.
# The program tries to pack as many un-checked-off pairs into each test case
# as possible. It's kind of like packing boxes: if you're smart you can find
# a combination of object for each box that will result in the minimum of wasted
# space. This program is not smart. It just packs the pairs into the test cases
# until every pair has been packed. It does not result in the smallest number
# of cases that could account for all the pairs, but the set will not be too large.
#
# All permutations of 10 variables of 10 values each results in 10^10 = 10 billion
# test cases. This program packs all pairs into a mere 178 cases. It's not
# optimal, but it's not bad, either.


#################################################################################################
# Version History:																				#
#	v0.1:																						#
#		-Removed the tail recursion in the findnext method; changed it to an iterative method	#
#		-Now outputs after the fact since the same data is stored as a string no need to do it  #
#			on the fly																			#
#		-Modified display out similarly to above, so it outputs after the cases are generated	#
#		-Now allows for multiple test case injection via cli									#
#		-Yet again fixed the verbose function and added a quiet flag for debugging/benchmarking	#
#	v0.031:																						#
#		-Fixed a bug with being able to to enable the gcc option in the native Windows cli		#
#		-Fixed a minor bug in the parsing of the injection hash									#
#	v0.03:																						#
#		-Added basic injection of test cases directly into Matlab cli.							#
#		-Thus, it now requires the matlab-ruby library, but only if you are using Matlab-		#
#			related	functions. So, it shouldn't present a problem if not.						#
#			(http://matlab-ruby.rubyforge.org/matlab-ruby/)										#			
#		-Apparently, session inject is the norm with the Matlab/C libs, so there's no need to 	#
#			start a new Matlab session for each test set, nor to store each of them				#
#		-Now can invoke the injection fucntion from the shell (as opposed to just the internal 	#
#		 	cli)																				#
#		-Fixed a bug in setting verbose on/off from the shell (would always be on unless storing#
#			 to file)																			#
#		-Can now run external Matlab scripts (really trivial, but does make it less anoying)	#
#		-Fixed a bug in handling the case that the matlab-ruby library is not installed			#
#		-Deprecated the export function; can now only directly inject to Matlab					#
#	v0.02:																						#
#		-Now has the option to randomly generate and output float values when permuting a range	#
#		-From the cli can now output to txt file copy-paste-able-to-Matlab arrays				#
# 	v0.01: 																						#	
#		-Now compiles and works exactly as (better than?) its predecessor Allpairs.				#
#		-Improved the sorting of parameters by number of values so it always works.				#
#		-Simplified the scoring data structures (scorestrings->scoreints) in findnext()			#
#			so that it's now just a simple integer array.										#
#		-Added ability to use embedded bash script to run the program associated with 			#
#			the parameters of which corollaries are parsing the combinations into a bash		#	
#			compatible array of arrays and making sure that the system HAS bash, gcc, gcov		#	
#			and lcov.																			#
#		-Added storing the combinations of parameter values to both a tab-delimited text file	#
#			and a csv file.																		#
#		-Object-orientized the code																#
#		-Added verbosity option (always on if no output specified								#
#		-Added multiple file and option input at program call									#															
#		-Added basic cli in the case that no input is specified as above						#
#		-Added enumerated output file specification												#
#		-Separated the cli and the test case generator into different classes					#
#		-Reimplemented the bash script to take modifiable command line options					#
# TODO: 																						#
#		-Document the code!!!																	#
#		-Review structures more thoroughly and prettify the code (for real)						#
#		-Parse arguments from shell better (e.g. don't require quotes for multipart flags)		#
#		-Improve exception handling (e.g. when incorrect input is given)						#
#		-Review the more?, readable, score, etc. methods to maximize efficiency (i.e. they don't#
#			need to instantiate the @pairs hash themselves (each time) should only be done once	#	
#################################################################################################
require './engine'

begin
	require './inject'
rescue LoadError
end

require 'rbconfig'

class TtCli

	@testcases = Array.new
	@matlab = nil
	
	def parseFilePaths(files, verbose, outpath, gcc, range)
		curr = TtGenerator.new(gcc, range)
		
		if (files.size < 1) then
			puts "No files input."
		else
			count = 0
			
			files.each{
				|v|
				
				unless outpath == nil then
					if files.size > 1 then
						if outpath.match(/[$\d]+/)
							outpath.sub!(/[$\d]+/, count.to_s)
						else
							outpath << count.to_s
						end
					end
				end
				
				curr.run(v, verbose, outpath)
				@testcases.push(curr)
				
				count = count + 1
			}
			
			runGcov(gcc)
		end
	end
	
	def cliLoop
		verbose = true
		gcc = nil
		outpath = nil
		range = false
		script = nil
		
		
		puts "Entry types:\n\noutput [path to file NO EXTENSION]\nverbose\n[path to input file(s)]\ngcc [path of main C file]\nrange\ninject\nscript [path to matlab script file]\nexit"
		puts
		
		while true
			count = 0
			
			print "? "
			
			input = gets.chomp.split(/\s/)
			input.each{ 
				|v|
				if v.match(/.txt/) then
					count = count + 1
				end
			}
			
			if count == input.size then
				@matlab = nil
				parseFilePaths(input, verbose, outpath, gcc, range)
			elsif input[0].eql?("exit") || input[0].eql?("end") || input[0].eql?("quit") || input[0].eql?("q") then
				exit(0)
			elsif input[0].eql?("verbose") || input[0].eql?("v") || input[0].eql?("-v") then
				if outpath != nil || gcc != nil  || script != nil then
					verbose = !verbose
					puts "Verbose is now #{verbose ? "on" : "off"}"
				else
					puts "Output method not specified; verbose must be on!"
				end
			elsif input[0].eql?("output") || input[0].eql?("o") || input[0].eql?("-o") then
				outpath = (input[1].eql?("") ? nil : input[1])	
				if outpath == nil then
					puts "No output"
					verbose = true
				else
					puts "Output to: " << outpath
				end
			elsif input[0].eql?("gcc") || input[0].eql?("g") || input[0].eql?("-g") then
				gcc = ((input[1].eql?("") || Config::CONFIG['host_os'] =~ /mswin|mingw/) ? nil : input[1])
				puts "gcc is now #{gcc ? "on with C file: #{gcc}" : "off"}"
			elsif input[0].eql?("range") || input[0].eql?("r") || input[0].eql?("-r") then
				range = (not range)
				puts "randomization of ranges is now #{(range ? "on" : "off")}."
			#elsif input[0].eql?("export")then
			#	file_name = (input[1].eql?("") ? nil : input[1])
			#	if @testcases.size > 0 && @testcases.last && file_name then
			#		@matlab.outFile(file_name)
			#	else
			#		puts "A name for the exported file must be specified!"
			#	end
			elsif input[0].eql?("inject")then
				if @testcases.size > 0 then #&& @testcases.last then
					num = (input[1].to_i < 1 ? nil : input[1].to_i)
					if num && @testcases[num - 1] then 
						runMatlab(script, @testcases[num - 1])
					else
						runMatlab(script)
					end
				else
					puts "You should probably generate some test cases first..."
				end
			elsif input[0].eql?("viewlast") || input[0].eql?("last") then
				if @testcases.size > 0 && @testcases.last then
					puts @testcases.last.getOutputTxt
				else
					puts "You should probably generate some test cases first..."
				end
			elsif input[0].eql?("view") then
				if @testcases.size > 0 then
					num = (input[1].to_i < 1 ? nil : input[1].to_i)
					if num && @testcases[num - 1] then
						puts @testcases[num - 1].getOutputTxt
					else
						puts "Please enter the test set you would like to view."
					end
				else
					puts "You should probably generate some test cases first..."
				end
			elsif input[0].eql?("script")then
				script = (input[1].eql?("") ? nil : input[1])
				unless script then
					puts "If you want to run a script, input the path to the script..."
				end
			else
				puts "Invalid input: #{input}\nPlease retry with a correct entry."
				puts "Entry types:\n\noutput [path to file NO EXTENSION]\nverbose\n[path to input file(s)]\ngcc [path of main C file]\nrange\ninject\nscript [path to matlab script file]\nexit"
				puts
			end
		end
	end
	
	def runGcov (gcc)
		if gcc then
			#get the path of the C file
			path = gcc.split(/\//).reverse
			path.shift
			path = path.reverse.join("/") << "/"
			
			`gcc -o ./#{path + "a.out"} -fprofile-arcs -ftest-coverage #{gcc};`
			@testcases.each{
				|v|
				bash = v.getBash
				
				puts `COUNTER=0; args=(#{bash}); while [ $COUNTER -lt ${#args[@]} ];do ./#{path + "a.out"} ${args[$COUNTER]} | cat;let COUNTER=COUNTER+1;done;`
			}
			`gcov #{gcc} ;lcov -c -d ./ -o ./#{path + "a.info"};genhtml -o ./#{path} ./#{path + "a.info"};rm *.gcda; rm *.gcno`
		end
	end
	
	def runMatlab (script, testcase = @testcases.last)
		catch (:matlab){
			unless @matlab then
				@matlab = ToMatlab.new(testcase.getOutputTxt)#@testcases.last.getOutputTxt)
			end
			@matlab.setHash(testcase.getOutputTxt)
			@matlab.injectHash
			if script then
				path = Dir.pwd
				
				if RUBY_PLATFORM =~ /cyg/ then
					path.sub!(/\/cygdrive\//,"")
					tmp = path.split(/\//).shift
					path.sub!("#{tmp}","#{tmp}:")
				end
				
				@matlab.evalString("cd '#{path}'")
				@matlab.evalString("run '#{script}'")
			end
		}
	end
	
	def initialize
		@testcases = Array.new
		outpath = nil
		verbose = false
		gcc = nil
		range = false
		matlab = false
		script = nil
		quiet = false
		
		if (ARGV.size > 0) then
			new_args = Array.new(ARGV)
			
			#puts ARGV.size
			#puts
			#puts ARGV
			
			ARGV.each{
				|v|
				if v.index("-") == 0 then
					if v.eql?("-v") then
						verbose = true
					elsif v.match("-o") then
						outpath = v.split(/\s/).pop
					elsif v.match("-g") then
						gcc = v.split(/\s/).pop
					elsif v.match("-r") then
						range = true
					elsif v.match("-m") then
						range = true
						matlab = true
					elsif v.match("-s") then
						script = v.split(/\s/).pop
					elsif v.match("-q") then
						quiet = true
					end
					new_args.shift
				end
			}
			
			#automatically set verbose on if necessary
			unless outpath || matlab && verbose != true || quiet then
				verbose = true
			end
			
			gcc = (Config::CONFIG['host_os'] =~ /mswin|mingw/ ? nil : gcc)
			parseFilePaths(new_args, verbose, outpath, gcc, range)
			
			if matlab then
				runMatlab(script)
				#unless @matlab then
				#	puts
				#	puts @testcases.last.getOutputTxt
				#	puts
				#	@testcases.last.status
				#end
			end
		else
			cliLoop
		end
	end
end

TtCli.new
