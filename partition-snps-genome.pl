#!/usr/bin/perl
#
#-------------------------------------------------------------------------
# partition-snps-genome.pl
#-------------------------------------------------------------------------
#
#-------------------------------------------------------------------------
# Richard Duncan
# Emory University, School of Medicine
# Department of Human Genetics
# richard.duncan@emory.edu
#
#-------------------------------------------------------------------------
# sample commands:
#-------------------------------------------------------------------------
#./partition-snps-genome.pl --help
#./partition-snps-genome.pl --options plink-options --M=100
#./partition-snps-genome.pl --options plink-options --M=50 --summary
#-------------------------------------------------------------------------

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FetchOptions;

#--------------------------------------------#
# process command line input:
#--------------------------------------------#
my $options_file;     # list of plink options
my $M = 100;          # number of SNPs per batch
my $chr23;            # include chromosome 23?
my $help;
my $summary;
GetOptions('chr23'      => \$chr23,
           'options=s'  => \$options_file,
           'M=i'        => \$M,
           'summary'    => \$summary,
           'help'       => \$help,       # show program help information
    );

#-----------------------------------------------------------
# mechanisms for printing help information:
#-----------------------------------------------------------
pod2usage(-exitval => 1, -verbose => 2, -output => \*STDOUT)  if ($help);

my $chr_max = 22;
if($chr23){
    $chr_max = 23;
}

my $plink = "plink";  # main executable
my $partition_snps_chromosome = "./partition-snps-by-chromosome.pl";


#-----------------------------------------------------------
# construct the options not specific to any partition:
#-----------------------------------------------------------
my $opts = &FetchOptions($options_file);
$opts =~ m/--bfile\s+(\S+)\s+.+/;
my $bfile = $1;
my $bimfile = sprintf("%s.bim", $bfile);

#-----------------------------------------------------------
# start with fresh opts line:
#-----------------------------------------------------------
my $chromosome_options = sprintf("--options=%s", $options_file);


#-----------------------------------------------------------
# begin partitioning by chromosome:
#-----------------------------------------------------------
for my $chr (1..$chr_max){

    $opts = sprintf("%s --chr %i", $chromosome_options, $chr);

    # grep bimfile for lines of chromosome $chr:
    my $chr_filter = `grep -e "^$chr\\s" $bimfile`;
    my @chr_data = split('\n', $chr_filter);

    # how many SNPs per partition on this chromosome:
    my $snp_count = @chr_data;
    my $N = $snp_count/$M;
    $opts = sprintf("%s --N %i", $opts, $N);

    if($summary){
        #-----------------------------------------------------------
        # the --summary option only prints a per-chromosome 
        #   breakdown of SNP partitions:
        #-----------------------------------------------------------
        my $cli = sprintf("%s %s --summary", $partition_snps_chromosome, $opts);
        #print $cli . "\n";
        system $cli;
    }
    else{
        #-----------------------------------------------------------
        # print the full list of command lines for each partition:
        #-----------------------------------------------------------
        my $cli = sprintf("%s %s", $partition_snps_chromosome, $opts);
        print $cli . "\n";
        system $cli;
    }
}



__END__


=head1 NAME

partition-snps-genome.pl - Generate PLINK commands for SNP data partitioned across all chromosomes

=head1 SYNOPSIS

partition-snps-genome.pl --options-file I<OPTIONS_FILE> [--M I<SNPs_per_batch>] [OPTIONS]...

=head1 ARGUMENTS

=over 4

=item B<--options-file I<OPTIONS_FILE>>

Two column file of PLINK options common to all partitions.
The first column are PLINK option tags (without the '--') and the
second column are the corresponding settings if applicable.
An example options file may look like this:

 #-- plink-options.txt --------------------
 bfile    AA
 covar    covariate.cov
 R        Rplink.R
 maf      0.0
 outroot  plink
 silent
 #-----------------------------------------

PLINK options are described in the PLINK documentation:
L<http://pngu.mgh.harvard.edu/~purcell/plink/reference.shtml#options>


=item B<--M I<SNPs_per_batch>>

Partition each chromosome to fit M SNPs in each batch call.
The default is M=100.

=back

=head1 OPTIONS

=over 4

=item B<--chr23>

Pass this option to include SNPs from chromosome 23.
NB:  This has not yet been well-considered.

=item B<--summary>

Summarize but do not perform the partitioning scheme for the specified inputs.

=item B<--help>

Print this help message and exit.

=back

=head1 DESCRIPTION

Partition SNP indicies for all chromosomes contained in PLINK MAP files
then produce commands that can be called for PLINK to analyze each partition 
separately, e.g., in parallel.


=head1 EXAMPLE

Suppose the PLINK command line options are listed in file F<plink-options>.
To produce PLINK command line calls with 100 SNPs in each seperate batch:

partition-snps-genome.pl --M 100 --options plink-options > cmds

In this case, the plink commands were printed to the file F<cmds>.

=head1 AUTHOR

 Richard Duncan, richard.duncan@emory.edu
 Emory University, School of Medicine
 Department of Human Genetics


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Richard Duncan
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
  list of conditions and the following disclaimer in the documentation and/or
  other materials provided with the distribution.

* Neither the name of the {organization} nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut  

exit;
