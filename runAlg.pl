#!/usr/bin/env perl
use Getopt::Std;
use File::Basename;
use strict;

sub avg(@);
my %opt;
getopts ("a:p:s", \%opt);
my $affinity = "";
$affinity = "/affinity $opt{a}" if $opt{a};

my $prog;
if ($opt{p}) {
   $prog = $opt{p};
} else {
   exit;
}

my @sizes;
if ($opt{s}) {
   @sizes = ( 1000, 5000 );
} else {
   for (my $i = 5; $i <= 7; $i++) {
      my $mod = 10**$i;
      for (my $n = 1; $n <= 9; $n++) {
         push(@sizes, $n*$mod) if ($n*$mod >= 300000 && $n*$mod <=30000000);
      }
   }
   #@sizes = ( 5000, 10000, 20000, 30000, 40000, 50000,
   #           100000, 200000, 300000, 400000, 500000,
   #           1000000, 2000000, 3000000, 4000000, 5000000);
}

my @results;

foreach my $size (@sizes) {
   my $i = 0;
   while ($i < 10) {
      printf("size:  %d\n",$size);
      my $cmd = "start $affinity java $prog $size";
      my $result = `$cmd`;
      #$result =~ m/(\d+)\w+|\w(\d+)/;
      push(@results, $result);
      $i++;
   }
}

my %data;
open (DATA, '<', dirname($prog) . '/data/data.txt');
while (my $line = <DATA>) {
   $line  =~ m/(\d+)\s(\d+)/;
   if ($data{$1}) {
      push(@{$data{$1}}, $2);
   } else {
      $data{$1} = [$2];
   }
}

my %avg;

foreach my $time (keys %data) {
   my @arr = @{$data{$time}};
   $avg{$time} = avg(@arr);
}

open (OUTPUT, '>', dirname($prog) . '/data/avgData.txt');
foreach my $time (sort {$a<=>$b} keys %avg) {
   print OUTPUT "$time $avg{$time}\n";
}
close (OUTPUT);

sub avg (@) {
    my $total = 0;
    $total += $_ foreach @_;
    # sum divided by number of components.
    return $total / @_;
}
