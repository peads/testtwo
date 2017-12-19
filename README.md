# testtwo
TestTwo is a test case generator and an evolution of James Bach's Allpairs. It was necessary to have a solid Matlab interface, so Ruby is used to allow easier usage of the external Matlab/C libraries.

## Installation

Simply run the script with any Ruby interpreter.


### matlab-ruby (optional)

Obtain a copy of matlab-ruby from http://matlab-ruby.rubyforge.org/matlab-ruby/
and install it.

If you are running Windows and Matlab:
        -download and install Cygwin with Ruby and patch modules
        -download matlab-ruby libraries (matlab-ruby-vvv.tgz) #
                [make sure it is the tgz file and not the gem file]
        -navigate to the ext directory of the matlab-ruby folder
        -patch the extconf.rb with the provided .patch file
                patch p1 extconf.rb < [name_of_patch].patch

                
## Flags

-g [path] use GCC, gcov/lcov interface (experimental)
-m use Matlab injection
-o [outpath] specify path to store output
-s [path] specify a Matlab script to run after injection
-v verbose


## Examples

ruby testtwo.rb foo.txt
ruby testtwo.rb "-o asdf" -v foo.txt
ruby testtwo.rb "-s foo.m" -m bar.txt 
