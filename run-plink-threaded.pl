#!/usr/bin/perl
#
#-------------------------------------------------------------------------
# run-plink-threaded.pl
#-------------------------------------------------------------------------
# This script will spawn threads of plink commands from a list in
# the specified input file.
#
# sequence of steps to accomplish this:
# 1. use partitioning script to write SNP data partitions to file 'cmds':
#
# ./partition-snps-genome.pl --options plink-options --M=100 > cmds
#
# 2. keep N threads of plink processes running until the input list (cmds) is exhausted.
#
# ./run-plink-threaded.pl --in cmds --ncpu 4
#
#------------------------------------------------------------------------------------------------------
# command line options:
#------------------------------------------------------------------------------------------------------
#  option        argument           default           description
#  ---------  ---------------   -----------------     -------------------------------------------------
#  --in           string                              file of plink commands for individual partitions
#  --ncpu        integer               4              number of parallel threads
#
#-------------------------------------------------------------------------
# who, where:
#-------------------------------------------------------------------------
# Richard Duncan
# Emory University, School of Medicine
# Department of Human Genetics
# richard.duncan@emory.edu
#
#-------------------------------------------------------------------------
# sample command line:
#-------------------------------------------------------------------------
# ./run-plink-threaded.pl --in PARTITION_FILE --ncpu 4
#

use strict;
use warnings;
use Parallel::ForkManager;
use Getopt::Long;

# debug flag:
my $debug;
my $MAX_PROCESSES = 4;
my $cmds_file;
GetOptions('debug'       => \$debug,
           'in=s'        => \$cmds_file,
           'ncpu=i'      => \$MAX_PROCESSES,
        );

my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

open(CMDS, "< $cmds_file");

while(my $line = <CMDS>){

	print $line;

	# Forks and returns the pid for the child:
	my $pid = $pm->start and next;

	chomp $line;
	my $cmd = $line;
	system $cmd;

	$pm->finish; # Terminates the child process
}

close(CMDS);
