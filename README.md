# testtwo
TestTwo is a test case generator and an evolution of James Bach's Allpairs. It was necessary to have a solid Matlab interface, so Ruby is used to allow easier usage of the external Matlab/C libraries.

## Installation

Simply clone the repository to your local harddisk and use the examples below.

### matlab-ruby (optional)

Obtain a copy of matlab-ruby from http://matlab-ruby.rubyforge.org/matlab-ruby/
and install it.

#### If you are running Windows and Matlab
* download and install Cygwin with Ruby and patch modules
* download matlab-ruby libraries (matlab-ruby-vvv.tgz) #
        [make sure it is the tgz file and not the gem file]
* navigate to the ext directory of the matlab-ruby folder
* patch the extconf.rb with the provided .patch file
        patch p1 extconf.rb < [name_of_patch].patch
                
## Flags

**-g** *[path]* use GCC, gcov/lcov interface (experimental)

**-m** use Matlab injection

**-o** *[outpath]* specify path to store output

**-s** *[path]* specify a Matlab script to run after injection

**-v** verbose

## Examples

#### Generates simple test cases for parameters contained in *foo.txt*

`ruby testtwo.rb foo.txt`

#### Generates test cases from *foo.txt*, outputs them to files *bar.txt* and *bar.csv* and displays verbose output

`ruby testtwo.rb "-o bar" -v foo.txt`

#### Generates test cases from *foo.txt*, and injects resulting parameters into *bar.m*

`ruby testtwo.rb "-s bar.m" -m foo.txt`
