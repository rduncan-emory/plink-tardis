#!/usr/bin/perl
#
#-------------------------------------------------------------------------
# make-plink-schedule.pl
#-------------------------------------------------------------------------
# This script will create the necessary batch files for plink commands 
# and a schedule of qsub calls.  
#
# sequence of steps to accomplish this:
# 1. use partition-plink-data.pl to write SNP data partitions to file
#
#./partition-plink-data.pl --N=8 --bfile=AA --out=BDI --covar=covariate.cov --Rplink=Rplink.R \
#  --silent --chr 22 > plink-partitions
#
# where the printed commands are written to the file plink-partitions.
#
# 2. create all corresponding batch files and a schedule of commands to run them
#
# ./make-plink-schedule.pl --in=plink-partitions --out=plink-qsubs --template=run-plink.template
#
#------------------------------------------------------------------------------------------------------
# command line options:
#------------------------------------------------------------------------------------------------------
#  option        argument           default           description
#  ---------  ---------------   -----------------     -------------------------------------------------
#  --pmem     8 <= int <= 512          8              amount of RAM in GB to use per core use
#  --in           string                              file of plink commands for individual partitions
#  --out          string        plink-schedule.sh     schedule file for batch commands
#  --template     string        run-plink.template    template file for individual batch files
#
# NB:  Increasing memory beyond 8 GB effectively decreases the number of available processors per node
#      resulting in charges for pmem/8 cores.  For example, pmem=16 will cost the same as using 2 cores
#      even when only one core is scheduled.
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
# ./make-plink-schedule.pl --pmem=8 --in=PARTITION_FILE --out=SCHEDULE_FILE --template=TEMPLATE_FILE
#

use strict;
use Getopt::Long;

my $pmem = 8;                               # RAM needed for each individual batch call
my $pfile;                                  # list of plink commands by partition
my $sfile = "plink-schedule.sh";            # list of qsub calls to batch scripts
my $template_file = "run-plink.template";   # batch script template
GetOptions('pmem=i'     => \$pmem,
           'in=s'       => \$pfile,
		   'out=s'      => \$sfile,
		   'template=s' => \$template_file,
);

open(PARTITIONS, "< $pfile");

# open schedule file and handle the bang line:
my $needs_bang = 1;
if(! -e $sfile){
	my $needs_bang = 0;
}
open(SCHEDULE, ">> $sfile");
if($needs_bang){
	print SCHEDULE "#!/bin/sh\n";
}

open(TEMPLATE, "< $template_file");
my $template = `cat $template_file`;
close(TEMPLATE);

my $line;
while($line = <PARTITIONS>){
	my $is_cmd = $line =~ m/^plink/;
	if($is_cmd){
		chomp $line;
		my $cmd = $line;

		# name of corresponding job id and batch file:
		$line =~ m/--out\s(.+)$/;
		my $jobid = $1;
		my $batch_file = sprintf("%s.sh", $jobid);

		# which partition:
		$jobid =~ m/rs([0-9]+)/;
		my $rs = $1;

		# which chromosome:
		$line =~ m/--chr\s([0-9]+)/;
		my $chr = $1;

		# populate the batch script with job-specific parameters:
		my $param = $template;
		$param =~ s/JOB_NAME/$jobid/;
		$param =~ s/PARTITION/$rs/;
		$param =~ s/CHR_K/part of chromosome $chr/;
		$param =~ s/PLINK_CMD/$line/;
		$param =~ s/PMEM/$pmem/;
		open(BATCH, "> $batch_file");
		print BATCH $param;
		close(BATCH);

		# list the qsub call in the schedule file:
		my $qsub_call = sprintf("qsub %s\n", $batch_file);
		print SCHEDULE $qsub_call;
	}
} # while PARTITIONS

close(SCHEDULE);
chmod 0755, $sfile;  # ensure schedule file is executable

close(PARTITIONS);

