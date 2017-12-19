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

class TtGenerator
	@bash = String.new
	@gcc = false
	@labels_h =  Hash.new 
	@labels_a = Array.new
	@listorder_h = Hash.new
	@listorder_a = Array.new
	@lists = Hash.new{ |label, key| label[key] = [] }
	@neededvalues = Array.new
	@output_txt = String.new
	@paircases = Hash.new{ |label, key| label[key] = Hash.new{ |label, key| label[key] = [] }  } 
	@pairs = Hash.new{ |label, key| label[key] = {} } 
	@range = false
	@slug = Array.new
	@vars = Array.new
	
	
	def maketables (path, tablename)

		# populates array LABELS and hash LISTS indexed by table name. 
		# Multiple tables can be processed, that way.
		count = 0
		data = File.open(path,"r")
		elements_labels = 0
		
		data.each_line{
			|line|
			
			elements_row = line.split(/\t/).size
			index = 0
			temp = line.chomp.split(/\t/)
			
			#if it's the first go store the parameter names
			#otherwise, store their associated values
			if count < 1 then
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

				@labels_a = temp
				@labels_h[tablename] = temp
				temp.each{
					|key|
					
					if @listorder_a.include?(key) then
						#see error text
						puts("Each column " \
							+ "must have a unique label. " \
							+ "Label #{key} is not unique.\n") 
						exit(-3)
					else 
						@listorder_a.push(index)
						@listorder_h.store(key,index)
						index = index + 1
					end
				}
				
				elements_labels = index
			else
				index = 0
				
				temp.each{
					|x|
					if not x.eql?("") then
						@lists[@labels_h[tablename][index]].push(x)
					end
					index = index + 1
				}
				
				if elements_row != elements_labels then
					#see error text
					puts("Error in the table. This row:\n\n#{line}\n" \
						+ "has #{elements_row} columns instead of #{elements_labels}.\n" \
						+ "\nThe data table should be tab delimited. " \
						+ "Each row of the table must have the same number " \
						+ "of columns as the first row (the label row). " \
						+ "Check for extra tabs or spurious lines in the table.\n")
						exit(-4)
				end
			end
			
			count = count + 1
		}
		
		@labels_a = @labels_a.sort{
			|a,b|
			@lists[b].size <=> @lists[a].size
		}
		@labels_h[tablename] = @labels_a
		
		index = 0 
		@labels_a.each{
			|element|
			@listorder_h[element] = index
			index = index + 1
		}
		index = 0
		while (index < @labels_a.size)
			@vars[index] = @lists[@labels_h[tablename][index]].size
			index = index + 1
		end
	end

	def populate
		c, v, s, y = 0,0,0,0
		
		while c < @vars.size - 1
			v = c + 1
			while v < @vars.size
				x = 0
				while x < @vars[c]
					y = 0
					while y < @vars[v]
						@pairs["#{c}-#{v}"]["#{x}-#{y}"] = 0
						y = y + 1
					end
				x = x + 1
				end
			v = v + 1
			end
		c = c + 1
		end
	end

	def more?
		c, v, s, y = 0,0,0,0
		
		c = 0
		while c < @vars.size - 1
		
			v = c + 1
			while v < @vars.size
			
				x = 0
				while x < @vars[c]
				
					y = 0
					while y < @vars[v]
						if @pairs["#{c}-#{v}"]["#{x}-#{y}"] == 0 then
							return true
						end
						
						y = y + 1
					end
					
				x = x + 1
				end
				
			v = v + 1
			end
			
		c = c + 1
		end
		return false
	end

#	def findnext(old)
#		c, v, x, y = 0,0,0,0
#		best = 120
#		casevalues = Array.new(old)
#		scores = Array.new()
#		scoreints = Array.new(@vars.sort{|a,b| b<=>a}[0]){ |index| Array.new(@vars.sort{|a,b| b<=>a}[0]){|i| 120}}
#		
#		c = 0
#		while c < @vars.size
#			if casevalues[c] == 120 then
#				#puts "broken at #{c}"
#				break
#			end
#			c = c + 1
#		end
#		
#		if c == @vars.size then
#			return casevalues
#		end
#
#		x = 0
#		while x < @vars[c]
#			scores = Array.new
#			
#			v = 0
#			while v < @vars.size
#				if v == c then
#					scores[v] = 0
#					v = v + 1
#					next
#				end
#
#				if v < c then
#					scores[v] = @pairs["#{v}-#{c}"]["#{casevalues[v]}-#{x}"]
#				else
#					best = 120
#					
#				y = 0
#				while y < @vars[v]
#					if @pairs["#{c}-#{v}"]["#{x}-#{y}"] < best then
#						best = @pairs["#{c}-#{v}"]["#{x}-#{y}"]
#						end
#						
#						y = y + 1
#					end
#					
#					scores[v] = best
#				end
#				
#				v = v + 1
#			end
#			
#			scoreints[x] = scores.sort
#			scoreints[x].push(x)
#			
#			x = x + 1
#		end
#
#		casevalues[c] = scoreints.sort[0].pop
#		
#		#store whether or not parameter c needs be matched
#		if scoreints.sort[0][1] == 0 then
#			@neededvalues[c] = "N"
#		else
#			@neededvalues[c] = "Y"
#		end
#			
#		return findnext(casevalues)
#	end	
	
	def findnext1(slug)
		c, v, x, y = 0,0,0,0
		best = 120
		casevalues = Array.new(slug)
		
		while c < @vars.size
			scores = Array.new()
			scoreints = Array.new(@vars.sort{|a,b| b<=>a}[0]){ |index| Array.new(@vars.sort{|a,b| b<=>a}[0]){|i| 120}}

			x = 0
			while x < @vars[c]
				scores = Array.new
				
				v = 0
				while v < @vars.size
					if v == c then
						scores[v] = 0
						v = v + 1
						next
					end

					if v < c then
						scores[v] = @pairs["#{v}-#{c}"]["#{casevalues[v]}-#{x}"]
					else
						best = 120
						
						y = 0
						while y < @vars[v]
							if @pairs["#{c}-#{v}"]["#{x}-#{y}"] < best then
								best = @pairs["#{c}-#{v}"]["#{x}-#{y}"]
							end
							
							y = y + 1
						end
						
						scores[v] = best
					end
					
					v = v + 1
				end
				
				scoreints[x] = scores.sort
				scoreints[x].push(x)
				
				x = x + 1
			end

			casevalues[c] = scoreints.sort[0].pop
			
			#store whether or not parameter c needs be matched
			if scoreints.sort[0][1] == 0 then
				@neededvalues[c] = "N"
			else
				@neededvalues[c] = "Y"
			end
			c = c + 1
		end
		
		#print casevalues
		#puts
		
		return casevalues
	end

	def checkin (casevalues, casenumber)
		c, v = 0,0
		
		while c < @vars.size - 1
		
			v = c + 1
			while v < @vars.size
				@pairs["#{c}-#{v}"]["#{casevalues[c]}-#{casevalues[v]}"] = @pairs["#{c}-#{v}"]["#{casevalues[c]}-#{casevalues[v]}"] + 1
				@paircases["#{c}-#{v}"]["#{casevalues[c]}-#{casevalues[v]}"].push(casenumber)
				
				v = v + 1
			end
			
			c = c + 1
		end
	end

	def status
		puts"var1\tvar2\tvalue1\tvalue2\tappearances\tcases"
		
		c = 0
		while c < @vars.size - 1
		
			v = c + 1
			while v < @vars.size
				
				x = 0
				while x < @vars[c]
					
					y = 0
					while y < @vars[v]
						print @labels_a[c]
						print"\t"
						print @labels_a[v]
						print"\t"
						print gettable("tables",c)[x]#@lists[@labels_h["tables"][c]][x]
						print"\t"
						print gettable("tables",v)[y]#@lists[@labels_h["tables"][v]][y]
						print"\t"
						print @pairs["#{c}-#{v}"]["#{x}-#{y}"]
						print"\t"
						#print @paircases["#{c}-#{v}"]["#{x}-#{y}"]
						temp = String.new
						@paircases["#{c}-#{v}"]["#{x}-#{y}"].each{
							|val|
							temp = temp << val.to_s << ","
						}
						print temp.chop
						puts 
						
						y = y + 1
					end
					
					x = x + 1 
				end

				v = v + 1
			end
			
			c = c + 1
		end
	end

	def gettable (tablename, index)
		if index.eql?("labels") then
			return @labels_h[tablename]
		else
			return @lists[@labels_h[tablename][index]]
		end
	end

	def score (casevalues)
		c,v,score = 0,0,0
		
		while c < @vars.size - 1
			v = c + 1
			while v < @vars.size
				if @pairs["#{c}-#{v}"]["#{casevalues[c]}-#{casevalues[v]}"] == 0 then
					score = score + 1
				end
				v = v + 1
			end
			c = c + 1
		end
			
		return score
	end

	def simplRand (ar)
		min = ar.min
		max = ar.max
		
		r = (min >= max ? nil : (max.abs + min.abs) * rand() - min.abs) #scale range into positive, unscale to range
		r = (r < min || r > max ? simplRand(ar): r) #make sure it's not outside the range, return
	end

	def parseRange (numStr)
		if numStr =~ /[,]{1}/ && numStr =~ /[0-9]+/
			numStr.gsub(/[^0-9\-,.]/, "").split(/,/).map{ |i| i.to_f} #this monstrosity turns the string range into an array of floats
		end
	end

	def readable (casevalues)
		t = 0
		newcase = ""
		@bash = @bash << "\""
		val = ""
		
		while t < casevalues.size
			if (not @range) && @neededvalues[@listorder_a[t]].eql?("Y") then
				newcase = newcase << "~"
			end
			
			val = (gettable("tables",@listorder_a[t]))[casevalues[@listorder_a[t]]]
			
			if @range && val =~ /[\[,\]]/ then
				val = simplRand(parseRange(val)).to_s
			end	
				
			newcase = newcase << val#(gettable("tables",@listorder_a[t]))[casevalues[@listorder_a[t]]]
			newcase = (t < casevalues.size - 1 ? newcase << "\t" : newcase)
			
			if @gcc then
				@bash = @bash << "\"" << (gettable("tables",@listorder_a[t]))[casevalues[@listorder_a[t]]] << "\""
				@bash = (t < casevalues.size - 1 ? @bash << " " : @bash)
			end
			
			t = t + 1
		end
		
		@bash = @bash << "\" "
		
		return newcase
	end

	def reset
		@labels_h =  Hash.new 
		@labels_a = Array.new
		@listorder_h = Hash.new
		@listorder_a = Array.new
		@lists = Hash.new{ |label, key| label[key] = [] }
		@neededvalues = Array.new
		@output_txt = String.new
		@paircases = Hash.new{ |label, key| label[key] = Hash.new{ |label, key| label[key] = [] }  } 
		@pairs = Hash.new{ |label, key| label[key] = {} } 
		@slug = Array.new
		@vars = Array.new
	end

	def run (filepath, verbose, outpath)
		i, count = 0,1
		cases = Array.new
		
		reset
		maketables(filepath, "tables")
		populate
		
		#no need to define or initialize these at the top if maketables fails
		readable = String.new
		@slug = Array.new(@vars.size){ |index| 120 }
		score = Array.new
		
		
		@output_txt = @output_txt << "\t"
		@labels_a.sort{
			|a,b|
			@listorder_h[a] <=> @listorder_h[b]
		}.each{
			|v|
			
			@output_txt = @output_txt << "#{v}\t"
		}
		
		@output_txt = @output_txt << "\n"
		
		while more?
			@neededvalues = Array.new
			cases = findnext1(@slug)
			readable = readable(cases)
			tmp = count.to_s << "\t" << readable
			score.push(score(cases).to_s)
			
			checkin(cases, count)

			@output_txt = @output_txt << tmp.strip << "\n"
			count = count + 1
		end
		
		unless outpath == nil then 
			file_output_txt = File.open(outpath + ".txt", "w")
			file_output_csv = File.open(outpath + ".csv", "w")
			file_output_txt.write(@output_txt)
			file_output_csv.write(@output_txt.gsub(/\t/, ";").gsub(/^[0-9]/){ |m| "Test" << m} )
			file_output_txt.close
			file_output_csv.close
		end
		
		if verbose then
			cnt = 0
			tmp = Array.new(score)
			
			puts
			@output_txt.sub(/^/, "test").each_line{
				|l|
				if cnt < 1 then
					print l.sub(/$/,"pairings")
				else
					print l.sub(/$/, "\t#{tmp.shift}") 
				end
				cnt = cnt + 1
			}
			puts
			status
			puts
		end

		@output_txt.gsub!(/^\t/,"t\t")
	end
	
	def getBash
		return @bash
	end
	
	def getOutputTxt
		return @output_txt
	end
	
	def initialize(gcc, range)
		@gcc = gcc
		@range = range
		@bash = String.new
		
		reset
	end
end
