#!/usr/bin/env perl
use Getopt::Std;
use File::Basename;
use strict;

# prototypes
sub avg(@);

# Command line arguments
my %opt;
getopts ("a:p:sr:n:di:h", \%opt);

if ($opt{h}) {
   my $help =  "runAlg.pl -- Program to run DataStructs & Alg java programs\n" .
               " -a #   :  Affinity\n" .
               "        :  Decimal value | Binary bit mask  | Allow threads on processors\n" .
               "        :                |                  |\n" .
               "        :  1             | 00000001         | 0\n" .
               "        :  3             | 00000011         | 0 and 1\n" .
               "        :  7             | 00000111         | 0, 1, and 2\n" .
               "        :  15            | 00001111         | 0, 1, 2, and 3\n" .
               "        :  31            | 00011111         | 0, 1, 2, 3, and 4\n" .
               "        :  63            | 00111111         | 0, 1, 2, 3, 4, and 5\n" .
               "        :  127           | 01111111         | 0, 1, 2, 3, 4, 5, and 6\n" .
               "        :  255           | 11111111         | 0, 1, 2, 3, 4, 5, 6, and 7\n" .
               " -d     :  Do not run the java program.\n" .
               "        :  Just run the averaging and graph on supplied data\n" .
               " -h     :  Display help menu\n" .
               " -i #   :  Number of rounds\n" .
               " -n #   :  Number of iterations per size, default 10\n" .
               " -p *** :  Name of the java program\n" .
               " -r #,# :  Set the size delimiters\n" .
               " -s     :  Run a test run of the java program\n" .
               "        :  Sizes are 1000 and 5000\n";
   print $help;   
   exit;
}

# this will run the program in the background or in new terminal
my $starter;
if ($^O eq "linux")
   # run in new terminal
   $starter = "xterm -e";
else
   # run invisable 
   $starter = "start /B"

# Set the affinity for the java process
# This is the cores the program can run on
# This is only useful on Windows
# Use decimal value

# Decimal value | Binary bit mask  | Allow SQL Server threads on processors
#               |                  |
# 1             | 00000001         | 0
# 3             | 00000011         | 0 and 1
# 7             | 00000111         | 0, 1, and 2
# 15            | 00001111         | 0, 1, 2, and 3
# 31            | 00011111         | 0, 1, 2, 3, and 4
# 63            | 00111111         | 0, 1, 2, 3, 4, and 5
# 127           | 01111111         | 0, 1, 2, 3, 4, 5, and 6
# 255           | 11111111         | 0, 1, 2, 3, 4, 5, 6, and 7

my $affinity = "";
# if running windows, set the affinity
if ($^O eq "MSWin32")
   $affinity = "/affinity $opt{a}" if $opt{a};

# Set the java program that is going to be run
my $prog;
if ($opt{p}) {
   $prog = $opt{p};
} else {
   exit;
}

# This section actually runs the program
# You would skip this part if you already have the data
#  and just want to run the stats and create the graph
unless ($opt{d}) {
   # Set the boundries for sizes
	my $low = 0;
	my $high = 0;
	if ($opt{r} =~ m/(\d+),(\d+)/) {
		$low = int($1);
		$high = int($2);
	}

   # Create the array of sizes
	my @sizes;

   # Test the java program
	if ($opt{s}) {
	   @sizes = ( 1000, 5000 );

   # Create even "jumps" between the numbers
   # 30 is the default
	} else {
      use integer;
      my $int = ($opt{i}) ? $opt{i} : 30;
		my $by = ($high - $low) / $int;
		my $i = $low;
		while ($i <= $high) {
			push(@sizes, $i);
			$i = $i + $by;
		}
	}

   # Create the results array
	my @results;

   # Set the number of runs per number
   # 10 is the default
	my $n = ($opt{n}) ? $opt{n} : 10;
	foreach my $size (@sizes) {
	   my $i = 0;
	   while ($i < $n) {
         # print the size being run on the terminal
         printf("size:  %d\n",$size);
         # run the program
         # the "start /B" will run the program in the background of the current terminal
         # Note that this is only useful on Windows. I never write the Unix options
         my $cmd = "$starter \"$affinity java $prog $size\"";
         my $result = `$cmd`;
         # push the result data to the array
         # This next line was useful at some point but I can't remember what 
         #  I used it for. Damn BubbleSort
         push(@results, $result);
         $i++;
	   }
	}
}

# hashes to hold the parsed data and matched percentage
my %data;
my %percent;

# Open the data.txt file for writing
open (DATA, '<', dirname($prog) . '/data/data.txt');

# parse the data, line by line from the file
while (my $line = <DATA>) {
   # Parse line
   # Titles    "size    time  matches "
   # Format:   "#####   ###   #.######"
   $line  =~ m/(\d+)\s+(\d+)\s+([\d.]+)/;
   
   # Check if the size already exists as a key in the hash
   if ($data{$1}) {
      # if, add the time to the array in the value of that key 
      # Good luck understanding that.
      push(@{$data{$1}}, $2);
   } else {
      # if the key doesn't already exists
      # Create one with the time as the value
      $data{$1} = [$2];
   }
   
   # Check if the size already exists as a key in the hash
   if ($percent{$1}) {
      # if, add the percent to the array in the value of that key
      push(@{$percent{$1}}, $3);
	} else {
      # if the key doesn't already exists
      # Create one with the percent as the value
      $percent{$1} = [$3];
   }
}

# Create the hashes for the averages
my %avg;
my %avgPer;

foreach my $size (keys %data) {
   # get the times for the size and store in a temp array
   # not needed but little nicer on the eyes
   my @arr = @{$data{$size}};
   # Run the avg function on the array
   # save result in hash with key as the size
   $avg{$size} = avg(@arr);
}

# same as the foreach above, but with percentages
foreach my $size (keys %percent) {
   my @arr = @{$percent{$size}};
   $avgPer{$size} = avg(@arr);
}
   
# Open the file for averages for writing
open (OUTPUT, '>', dirname($prog) . '/data/avgData.txt');

# run avg data through in sorted fashion (easy on eyes when reading the txt file
foreach my $size (sort {$a<=>$b} keys %avg) {
   # write to the file in the format:
   # "Size  time     percent"
   # "####  ###.#    #.#####"
   # the multiply then divide by 1Million is there to remind me that
   # that it is milliseconds to nanoseconds 
   # and the divide is dividing the 1000000 "lookups" done in the java program
   #  to get per lookup
   print OUTPUT sprintf("%d\t%.1f\t%f\n",$size,(1000000*($avg{$size}))/1000000,
                        $avgPer{$size});
}
# close the file
close (OUTPUT);

# Write to the file
# again, "start /B" runs in background of current terminal
# only on windows.
# "gnuplot *****.plt" will run that file on gnuplot
# make sure you have edited the plt correctly if using this method
my $graphCMD =  "$starter \"gnuplot binarytree.plt\"";
# Run
system($graphCMD);

# Average an array of numeric data
sub avg (@) {
   # get an array using the data is assending order
	@_ = sort{$a <=> $b} @_;
   # get rid of the top and bottom outliers
	pop(@_);
	shift(@_);	
   # sum the numbers
   my $total = 0;
   $total += $_ foreach (@_);
   # get average
   return $total / @_;
}


##############################################
# Java method to print data to file for this script

#	public static void printToDataTxt( int size, double pFound, long startTime, 
#									   long endTime, String curFile ) {
#		// Get the current directory.
#		java.io.File currentDir = new java.io.File( curFile );
#		// Get the file seperator for OS independent execution
#		char sep = File.separatorChar;
#		String absolutePath = currentDir.getAbsolutePath();
#		// Get the path of current directory
#		String filePath = absolutePath.substring( 0, 
#			absolutePath.lastIndexOf( sep ));
#		// Set path of data directory
#		String dataDir = filePath + sep + "data";
#		// Set file to output data from array
#		String file = dataDir + sep + "data" + ".txt";
#		try {
#			// Check if data directory exists
#			File dataD = new File(dataDir);
#			if (!dataD.exists())  { dataD.mkdir(); }
#			// Write Data to file
#			FileWriter fstream = new FileWriter( file, true );
#			BufferedWriter out = new BufferedWriter( fstream );
#			out.write(String.format("%d\t%d\t%f", size, 
#									(endTime - startTime), pFound));
#			out.newLine();
#			out.close();
#		} catch ( Exception e ) {
#			System.err.println( "Cant write to file: " + file );
#		}
#	}