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

class ToMatlab
	require 'matlab'
	
	@hash = Hash.new{ |label, key| label[key] = [] }
	@e = nil
	
	def injectHash
		begin
			@hash.each{ |l,k| @e.put_variable(l,0)}
			@hash.each{ |l,k| @e.put_variable(l,k.map{ |i| i.to_f})}
		rescue RuntimeError, NoMethodError
			puts "matlab-ruby library not installed!"
			throw :matlab
		end
	end
	
	#def outFile (file_name)
	#	out_file = File.new(file_name + ".txt", "w")
	#	#just makes it pretty to file
	#	@hash.each{
	#		|l,k| 
	#		
	#		tmp = ""
	#		k.each{ |i| tmp << i.to_s << " "}
	#		tmp.chop!
	#		tmp = "#{l} [" << tmp << "]\n"
	#		out_file.write(tmp)
	#		#print tmp
	#		#puts
	#		
	#	}
	#	out_file.close
	#end
	
	def parseString (str)
		cnt, cnt1 = 0,0
		hash = Hash.new{ |label, key| label[key] = [] }
		keys = Array.new
		
		str.each_line{
			|line|
			
			elements_row = line.split(/\t/).size
			temp = line.chomp.gsub(/~/,"").split(/\t/)
			
			#if it's the first go store the labels
			#otherwise, store their associated values
			if cnt < 1 then
				#see Error text
				if line !~ /\t/ then
					puts("Error: The first line of the file must " \
						+ "be a tab-delimited list of labels with more " \
						+ "than one label in it, and no blank labels.\n")
					exit(-1)
				end
				
				#see error text
				if line =~ /\t\t/ then
					puts("Error: Missing column label or extraneous" \
						+ "tabs in the first line of the file. The first" \
						+ "line of the file must be a tab-delimited " \
						+ "list of labels with more than one label in it, " \
						+ "and no blank labels.\n")
					exit(-2)
				end

				keys = temp
			else
				cnt1 = 0
				temp.each{
					|x|
					unless x.eql?("") then
						hash[keys[cnt1]].push(x)
					end
					cnt1 = cnt1 + 1
				}
			end
			
			cnt = cnt + 1
		}
		
		hash
	end
	
	def close
		begin
			@e.close
		rescue RuntimeError, NoMethodError
			puts "matlab-ruby library not installed!"
			throw :matlab
		end
	end
	
	def setHash(str)
		@hash = parseString(str)
	end
	
	def evalString (str)
		begin
			@e.eval_string(str)
		rescue RuntimeError, NoMethodError
			puts "matlab-ruby library not installed!"
			throw :matlab
		end
	end
	
	def initialize (output_string)
		begin
			@e = Matlab::Engine.new
		rescue RuntimeError, NoMethodError
			puts "matlab-ruby library not installed!"
			throw :matlab
		ensure
			@hash = Hash.new{ |label, key| label[key] = [] }
			setHash(output_string)
		end
	end
end
