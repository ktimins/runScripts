#!/usr/bin/env perl
use Getopt::Std;
use File::Basename;
use strict;

############
## TODO:
##	- Change the file seperators to use File::Spec
##    They currently are "\" and will not work on *NIX, I think

# prototypes
sub avg(@);

# Command line arguments
my %opt;
# getopts ("a:p:sr:n:di:ht:", \%opt);
getopts ("a:dhi:n:p:r:st:", \%opt);

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
               "        :  Sizes are 1000 and 5000\n".
							 " -t     :  Set the title for the plot\n";
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
   # "Size  time     percent
   # "####  ###.#    #.#####"
   # the multiply then divide by 1Million is there to remind me that
   # that it is milliseconds to nanoseconds 
   # and the divide is dividing the 1000000 "lookups" done in the java program
   #  to get per lookup
   print OUTPUT sprintf("%d\t%.1f\t%f\n",$size,($avg{$size}),
                        $avgPer{$size});
}
# close the file
close (OUTPUT);


my $filename = fileparse($prog, qr/\.[^.]*/)[0];
$opt{t} = $filename if ($opt{t} eq '');

my $plotCode = "".
"#!/gnuplot
#
#    
#    	G N U P L O T
#    	Version 4.6 patchlevel 0    last modified 2012-03-04 
#    	Build System: MS-Windows 32 bit 
#    
#    	Copyright (C) 1986-1993, 1998, 2004, 2007-2012
#    	Thomas Williams, Colin Kelley and many others
#    
#    	gnuplot home:     http://www.gnuplot.info
#    	faq, bugs, etc:   type \"help FAQ\"
#    	immediate help:   type \"help\"  (plot window: hit 'h')
# set terminal wxt 0
# set output
unset clip points
set clip one
unset clip two
set bar 1.000000 front
set border 31 front linetype -1 linewidth 1.000
set timefmt z \"%d/%m/%y,%H:%M\"
set zdata 
set timefmt y \"%d/%m/%y,%H:%M\"
set ydata 
set timefmt x \"%d/%m/%y,%H:%M\"
set xdata 
set timefmt cb \"%d/%m/%y,%H:%M\"
set timefmt y2 \"%d/%m/%y,%H:%M\"
set y2data 
set timefmt x2 \"%d/%m/%y,%H:%M\"
set x2data 
set boxwidth
set style fill  empty border
set style rectangle back fc  lt -3 fillstyle   solid 1.00 border lt -1
set style circle radius graph 0.02, first 0, 0 
set style ellipse size graph 0.05, 0.03, first 0 angle 0 units xy
set dummy x,y
set format x \"% g\"
set format y \"% g\"
set format x2 \"% g\"
set format y2 \"% g\"
set format z \"% g\"
set format cb \"% g\"
set format r \"% g\"
set angles radians
unset grid
set raxis
set key title \"\"
set key inside left top vertical Right noreverse enhanced autotitles nobox
set key noinvert samplen 4 spacing 1 width 0 height 0 
set key maxcolumns 0 maxrows 0
set key noopaque
unset label
unset arrow
set style increment default
unset style line
unset style arrow
set style histogram clustered gap 2 title  offset character 0, 0, 0
unset logscale
set offsets 0, 0, 0, 0
set pointsize 1
set pointintervalbox 1
set encoding default
unset polar
unset parametric
unset decimalsign
set view 60, 30, 1, 1
set samples 100, 100
set isosamples 10, 10
set surface
unset contour
set clabel '%8.3g'
set mapping cartesian
set datafile separator whitespace
unset hidden3d
set cntrparam order 4
set cntrparam linear
set cntrparam levels auto 5
set cntrparam points 5
set size ratio 0 1,1
set origin 0,0
set style data points
set style function lines
set xzeroaxis linetype -2 linewidth 1.000
set yzeroaxis linetype -2 linewidth 1.000
set zzeroaxis linetype -2 linewidth 1.000
set x2zeroaxis linetype -2 linewidth 1.000
set y2zeroaxis linetype -2 linewidth 1.000
set ticslevel 0.5
set mxtics default
set mytics default
set mztics default
set mx2tics default
set my2tics default
set mcbtics default
set xtics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0 autojustify
set xtics autofreq  norangelimit
set ytics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0 autojustify
set ytics autofreq  norangelimit
set ztics border in scale 1,0.5 nomirror norotate  offset character 0, 0, 0 autojustify
set ztics autofreq  norangelimit
set nox2tics
set noy2tics
set cbtics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0 autojustify
set cbtics autofreq  norangelimit
set rtics axis in scale 1,0.5 nomirror norotate  offset character 0, 0, 0 autojustify
set rtics autofreq  norangelimit
set title \"Merge Sort Runtime\" 
set title  offset character 0, 0, 0 font \"\" norotate
set timestamp bottom 
set timestamp \"\" 
set timestamp  offset character 0, 0, 0 font \"\" norotate
set rrange [ * : * ] noreverse nowriteback
set trange [ * : * ] noreverse nowriteback
set urange [ * : * ] noreverse nowriteback
set vrange [ * : * ] noreverse nowriteback
set xlabel \"n (1000x)\" 
set xlabel  offset character 0, 0, 0 font \"\" textcolor lt -1 norotate
set x2label \"\" 
set x2label  offset character 0, 0, 0 font \"\" textcolor lt -1 norotate
set xrange [ 5.00000 : * ] noreverse nowriteback
set x2range [ 67.1174 : 192.303 ] noreverse nowriteback
set ylabel \"Time (sec)\" 
set ylabel  offset character 0, 0, 0 font \"\" textcolor lt -1 rotate by -270
set y2label \"\" 
set y2label  offset character 0, 0, 0 font \"\" textcolor lt -1 rotate by -270
set yrange [ * : * ] noreverse nowriteback
set y2range [ -62.1175 : 42.6398 ] noreverse nowriteback
set zlabel \"\" 
set zlabel  offset character 0, 0, 0 font \"\" textcolor lt -1 norotate
set zrange [ * : * ] noreverse nowriteback
set cblabel \"\" 
set cblabel  offset character 0, 0, 0 font \"\" textcolor lt -1 rotate by -270
set cbrange [ * : * ] noreverse nowriteback
set zero 1e-008
set lmargin  -1
set bmargin  -1
set rmargin  -1
set tmargin  -1
set locale \"English_United States.1252\"
set pm3d explicit at s
set pm3d scansautomatic
set pm3d interpolate 1,1 flush begin noftriangles nohidden3d corners2color mean
set palette positive nops_allcF maxcolors 0 gamma 1.5 color model RGB 
set palette rgbformulae 7, 5, 15
set colorbox default
set colorbox vertical origin screen 0.9, 0.2, 0 size screen 0.05, 0.6, 0 front bdefault
set style boxplot candles range  1.50 outliers pt 7 separation 1 labels auto unsorted
set loadpath 
set fontpath 
set psdir
set fit noerrorvariables
GNUTERM = \"wxt\"
set term png size
set output '" . dirname($prog) . "\\data\\" . $filename . ".png'
set arrow from 0,0 to 30000,9.5255 nohead lt -1 lw 1.2
plot '". dirname($prog) . "\\data\\avgData.txt' using  ($1/1000):($2/1000) with linespoints title \"" . $opt{t} . "\"
#    EOF
set term wxt
replot";
open (PLOT, '>', dirname($prog)."\\".$filename."plt");
print PLOT $plotCode;
close (PLOT);

# Write to the file
# again, "start /B" runs in background of current terminal
# only on windows.
# "gnuplot *****.plt" will run that file on gnuplot
# make sure you have edited the plt correctly if using this method
my $graphCMD =  "$starter \"gnuplot " . dirname($prog) . "\\" . $filename . "plt\"";
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
#
# This should be used in the main of the program to pass the args to the java program correctly
#
#	public static void main( String args[] ) throws InterruptedException {
#	
#		// Set treesize, lookupSize, and lookup array.
#		// Java throws exception if variables aren't set as the try may fail
#		// when getting command line argument
#		int treeSize = 0;
#		final int lookupSize = 1000000;
#		int lookup[] = new int[lookupSize];
#		try {
#			// Reset size and mydata
#			treeSize = Integer.parseInt( args[0] );
#		} catch ( NumberFormatException e ) {
#			// If no arg or arg isn't an int,
#			// exit the program
#			System.err.println( e + " is not valid" );
#			System.exit( 1 );
#		}
#

# Put this at the end of your main to call the printToDataTxt method
#
#		// Print data to file
#		printToDataTxt( treeSize, (double)(found)/(double)(lookupSize), startTime,
#						endTime, args[0] )
#

# Java method to print data to file for this script
#
#	/**
#	 * Prints the size and delta(time) to file.
#	 * @param	size		The number of numbers in data set
#	 * @param	startTime	The starting time in ms
#	 * @param	endTime		The ending time in ms
#	 */
#
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
