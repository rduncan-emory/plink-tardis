#!/usr/bin/perl
#
#-------------------------------------------------------------------------
# partition-snps-by-chromosome
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
#./partition-snps-by-chromosome.pl --help
#./partition-snps-by-chromosome.pl --options plink-options --N=8 --chr 22
#./partition-snps-by-chromosome.pl --options plink-options --N=100 --chr 2 --summary
#-------------------------------------------------------------------------

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FetchOptions;

#--------------------------------------------#
# process command line input:
#--------------------------------------------#
my $options_file;   # list of plink options
my $chr = 1;        # chromosome number
my $N = 10;         # number of partitions
my $help;
my $summary;
GetOptions('chr=i'      => \$chr,
           'options=s'  => \$options_file,
           'N=i'        => \$N,
           'summary'    => \$summary,
           'help'       => \$help,       # show program help information
    );

# mechanisms for printing help information:
pod2usage(-exitval => 1, -verbose => 2, -output => \*STDOUT)  if ($help);

#-----------------------------------------------------------
# construct the options not specific to any partition:
#-----------------------------------------------------------
my $opts = &FetchOptions($options_file);

$opts =~ m/--bfile\s+(\S+)\s+.+/;
my $bfile = $1;
my $bimfile = sprintf("%s.bim", $bfile);

my $outroot = $bfile;
if($opts =~ m/--out\s+(\S+)\s+.+/){
    # user specified outfile root:
    $outroot = $1;
}
my $chr_filter = `grep -e "^$chr\\s" $bimfile`;
my @chr_data = split('\n', $chr_filter);

my $plink = "plink";  # main executable

my $snp_count = @chr_data;
# summarize the partitioning that would occur then exit:
if($summary){
    print sprintf("chromosome %02i with %5i SNPs:   %i per partition \n", 
                  $chr, $snp_count, $snp_count/$N);
    exit;
}


# various containers used in this script:
my @snp_data;
my @snp;
my @partition = ();
my @position = ();
for(my $j = 1; $j <= $N; $j++){
    my $snp_index = int($snp_count*$j/$N);
    push @partition, $snp_index;
}

@snp_data = split(' ', $chr_data[0]);
my $from_rs = $snp_data[1];
my $to_rs;
my @rs_cli;


# construct the options not specific to any partition:
$opts = sprintf("--noweb %s", $opts);
$opts = sprintf("%s --chr %i", $opts, $chr);
my $outroot_j = sprintf("%s_chr%02i_rsX", $outroot, $chr);

# loop across index of partitions:
for(my $j = 0; $j < $N; $j++){

    # start with fresh opts line:
    my $plink_opts = $opts;

    # the SNP index boundaries for this partition are resolved here:
    @snp_data = split(' ', $chr_data[$partition[$j] - 1]);
    $to_rs = $snp_data[1];
    my $rs_range = sprintf("--snps %s-%s", $from_rs, $to_rs);
    push @rs_cli, $rs_range;
    if($j < $N - 1){
        @snp_data = split(' ', $chr_data[$partition[$j]]);
        $from_rs = $snp_data[1];
    }

    # replace output file root with tagged version:
    $plink_opts =~ s/ --out\s+\S+//;

    my $jx = $j+1;
    my $jxstr = sprintf("%04i", $jx);
    my $outroot = $outroot_j;
    $outroot =~ s/X/$jxstr/;
    $plink_opts = sprintf("%s %s --out %s", $plink_opts, $rs_range, $outroot);

    # print the command with options:
    my $cli = sprintf("%s %s", $plink, $plink_opts);
    print $cli . "\n";
}

__END__


=head1 NAME

partition-snps-by-chromosome.pl - Generate PLINK commands for SNP data partitioned from PLNK MAP files

=head1 SYNOPSIS

partition-snps-by-chromosome.pl --options-file I<OPTIONS_FILE> [--chr I<chromosome_number>] [--N I<partitions>] [OPTIONS]...

Some of the options are better-described in the PLINK documentation:
L<http://pngu.mgh.harvard.edu/~purcell/plink/reference.shtml#options>

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


=item B<--chr I<chromosome_number>>

chromosome number [1-23].  Default is 1.

=item B<--N I<partitions>>

Number of partitions.  Default is 10.

=back

=head1 OPTIONS

=over 4

=item B<--summary>

Summarize the total and per-partition SNP count 
for the specified I<chromosome> and I<N>. 

=item B<--help>

Print this help message and exit.

=back

=head1 DESCRIPTION

Partition SNP indicies contained in PLINK MAP files
then produce commands that can be called for 
PLINK to analyze each partition separately,
e.g., in parallel.


=head1 EXAMPLE

Suppose a dataset and options are specified in the 
options file F<plink-options>.
The PLINK commands for analyzing the SNPs along chromosome 7 
divided into 100 partitions are obtained thus:

partition-snps-by-chromosome.pl --options plink-options --chr=7 --N=100 > cmds

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
