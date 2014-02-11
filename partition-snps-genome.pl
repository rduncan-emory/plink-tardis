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
#./partition-snps-genome.pl --M=100 --bfile=AA --out=BDI --covar=covariate.cov --Rplink=Rplink.R --silent
#./partition-snps-genome.pl --M=50 --bfile=AA --summary
#-------------------------------------------------------------------------

use strict;
use warnings;
use Time::Local;
use Getopt::Long;
use Pod::Usage;

#--------------------------------------------#
# process command line input:
#--------------------------------------------#
my $chr23;                 # include chromosome 23?
my $M = 100;               # number of SNPs per batch
my $bfile = "AA";          # binary plink data file root
my $covar = "covariate.cov";
my $Rplink = "Rplink.R";
my $maf = 0.0;
my $outroot = "plink";
my $remove;
my $silent;
my $help;
my $summary;
GetOptions('chr23'    => \$chr23,
		   'M=i'      => \$M,
		   'bfile=s'  => \$bfile,
		   'covar=s'  => \$covar,
		   'Rplink=s' => \$Rplink,
		   'remove=s' => \$remove,
		   'out=s'    => \$outroot,
		   'maf=f'    => \$maf,
		   'silent'   => \$silent,
		   'summary'  => \$summary,
           'help'     => \$help,       # show program help information
    );

# mechanisms for printing help information:
pod2usage(-exitval => 1, -verbose => 2, -output => \*STDOUT)  if ($help);

my $chr_max = 22;
if($chr23){
	$chr_max = 23;
}

my $bimfile = sprintf("%s.bim", $bfile);
my $plink = "plink";  # main executable
my $partition_snps_chromosome = "./partition-snps-by-chromosome.pl";

# construct the options not specific to any partition:
my $opts = "";
if($bfile){
    $opts = sprintf("%s --bfile %s", $opts, $bfile);
}
if($remove){
    $opts = sprintf("%s --remove %s", $opts, $remove);
}
if($maf > 0.0){
    $opts = sprintf("%s --maf %s ", $opts, $maf);
    $outroot = sprintf("%s_maf=%3.2f", $outroot, $maf);
}
if($covar){
    $opts = sprintf("%s --covar %s", $opts, $covar);
}
if($Rplink){
    $opts = sprintf("%s --Rplink %s", $opts, $Rplink);
}
if($silent){
    $opts = sprintf("%s --silent", $opts);
}

# start with fresh opts line:
my $common_plink_opts = $opts;

for my $chr (1..$chr_max){

	if($chr){
		$opts = sprintf("%s --chr %i", $common_plink_opts, $chr);
	}

	my $chr_filter = `grep -e "^$chr\\s" $bimfile`;
	my @chr_data = split('\n', $chr_filter);

	my $snp_count = @chr_data;
	my $N = $snp_count/$M;

	if($M){
		$opts = sprintf("%s --N %i", $opts, $N);
	}

	if($summary){
		#print sprintf("%i partitions of chromosome %i\n", $N, $chr);
		#my $cli = sprintf("%s %s", $partition_snps_chromosome, $opts);
		my $cli = sprintf("%s %s --summary", $partition_snps_chromosome, $opts);
		system $cli;
	}
	else{
		# print the command with options:
		my $cli = sprintf("%s %s", $partition_snps_chromosome, $opts);
		print $cli . "\n";
		system $cli;
	}
}



__END__


=head1 NAME

partition-snps-genome.pl - Generate PLINK commands for SNP data partitioned across all chromosomes

=head1 SYNOPSIS

partition-snps-genome.pl [--M I<SNPs_per_batch>] [--bfile I<input_fileroot>] [--out I<output_fileroot>] [OPTIONS]...

Some of the options are better-described in the PLINK documentation:
L<http://pngu.mgh.harvard.edu/~purcell/plink/reference.shtml#options>

=head1 ARGUMENTS

=over 4

=item B<--M I<SNPs_per_batch>>

Partition each chromosome to fit M SNPs in each batch call.

=item B<--bfile I<input_fileroot>>

Binary input data filename used by PLINK.
Default is 'AA'.

=item B<--out I<output_fileroot>>

Root of output file.  
Subsequently, the actual output files will be tagged 
with other parameter settings, e.g., chromosome number,
to ensure uniqueness.
Default is 'plink'.

=back

=head1 OPTIONS

=over 4

=item B<--chr23>

Pass this option to include chromosome 23.

=item B<--covar I<covariate_file>>

Name of covariates file to be used by PLINK.

=item B<--Rplink I<Rscript>>

Name of R plugin script to be used by PLINK.

=item B<--maf I<minor_allele_freq>>

Specify the minor allele frequency used in PLINK call.

=item B<--remove <remove_individuals_file>>

File of individuals for PLINK to remove.

=item B<--summary

Summarize but do not perform the partitioning scheme for the specified inputs.

=item B<--silent>

Pass --silent in the PLINK command line call.  
The only time it makes sense to not pass this is during testing/debugging, since PLINK can be rather verbose in in its std output.

=item B<--help>

Print this help message and exit.

=back

=head1 DESCRIPTION

Partition SNP indicies for all chromosomes contained in PLINK MAP files
then produce commands that can be called for PLINK to analyze each partition 
separately, e.g., in parallel.


=head1 EXAMPLE

Suppose the SNPs across chromosome 1-22 specified in dataset F<AA.bim> are 
to be analyzed with covariate data contained in F<covariate.cov> 
using R plugin script F<Rplink.R>.  
Also, the PLINK file output is to be written to files with root 
beginning with the string I<BDI> while non-file output is suppressed 
via the --silent option.

To produce PLINK command line calls with 100 SNPs in each seperate batch,

partition-snps-genome.pl --M=100 --bfile=AA --out=BDI --covar=covariate.cov --Rplink=Rplink.R --silent


=head1 AUTHOR


 Richard Duncan, richard.duncan@emory.edu
 Emory University, School of Medicine
 Department of Human Genetics


=cut  

exit;
