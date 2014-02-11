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
#./partition-snps-by-chromosome.pl --N=8 --bfile=AA --out=BDI --covar=covariate.cov --Rplink=Rplink.R --silent --chr 22
#./partition-snps-by-chromosome.pl --N=100 --bfile=AA --chr 2 --summary
#-------------------------------------------------------------------------


use strict;
use warnings;
use Time::Local;
use Getopt::Long;
use Pod::Usage;

#--------------------------------------------#
# process command line input:
#--------------------------------------------#
my $chr = 1;
my $N = 10;                # number of partitions
my $bfile = "AA";          # binary plink data file root
my $covar = "covariate.cov";
my $Rplink = "Rplink.R";
my $maf = 0.0;
my $outroot = "plink";
my $remove;
my $silent;
my $help;
my $summary;
GetOptions('chr=i'    => \$chr,
		   'N=i'      => \$N,
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

my $bimfile = sprintf("%s.bim", $bfile);
my $chr_filter = `grep -e "^$chr\\s" $bimfile`;
my @chr_data = split('\n', $chr_filter);

my $plink = "plink";  # main executable

my $snp_count = @chr_data;
# summarize the partitioning that would occur then exit:
if($summary){
	print sprintf("SNP count in chromosome %i:   %i\n", $chr, $snp_count);
	print sprintf("SNP count in each partition:  %i\n", $snp_count/$N);
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
my $opts = sprintf("--noweb");
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
    $opts = sprintf("%s --R %s", $opts, $Rplink);
}
if($chr){
    $opts = sprintf("%s --chr %i", $opts, $chr);
}
if($silent){
    $opts = sprintf("%s --silent", $opts);
}
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

	# construct the command options for this set of SNPs:
    my $jx = "$j+1";
    my $outroot = $outroot_j;
    $outroot =~ s/X/$jx/ee;
    $plink_opts = sprintf("%s %s --out %s", $plink_opts, $rs_range, $outroot);

	# print the command with options:
    my $cli = sprintf("%s %s", $plink, $plink_opts);
    print $cli . "\n";
    system $cli;
}

__END__


=head1 NAME

partition-snps-by-chromosome.pl - Generate PLINK commands for SNP data partitioned from PLNK MAP files

=head1 SYNOPSIS

partition-snps-by-chromosome.pl [--chr I<chromosome_number>] [--N I<partitions>]  [--bfile I<input_fileroot>] [--out I<output_fileroot>] [OPTIONS]...

Some of the options are better-described in the PLINK documentation:
L<http://pngu.mgh.harvard.edu/~purcell/plink/reference.shtml#options>

=head1 ARGUMENTS

=over 4

=item B<--chr I<chromosome_number>>

chromosome number [1-23].  Default is 1.

=item B<--N I<partitions>>

Number of partitions.  Default is 10.

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

=item B<--covar I<covariate_file>>

Name of covariates file to be used by PLINK.

=item B<--Rplink I<Rscript>>

Name of R plugin script to be used by PLINK.

=item B<--maf I<minor_allele_freq>>

Specify the minor allele frequency used in PLINK call.

=item B<--remove <remove_individuals_file>>

File of individuals for PLINK to remove.

=item B<--summary

Summarize the total and per-partition SNP count 
for the specified I<chromosome> and I<N>. 

=item B<--silent>

Pass --silent in the PLINK command line call.  
The only time it makes sense to not pass this is during testing/debugging, since PLINK can be rather verbose in in its std output.

=item B<--help>

Print this help message and exit.

=back

=head1 DESCRIPTION

Partition SNP indicies contained in PLINK MAP files
then produce commands that can be called for 
PLINK to analyze each partition separately,
e.g., in parallel.


=head1 EXAMPLE

Suppose the SNPs along chromosome 7 specified in dataset F<AA.bim> are 
to be analyzed with covariate data contained in F<covariate.cov> 
using R plugin script F<Rplink.R>.  
Also, the PLINK file output is to be written to files with root 
beginning with the string I<BDI> while non-file output is suppressed 
via the --silent option.

The SNPs will be divided into 100 partitions and a separate PLINK
command will be developed for each partition using the command

partition-snps-by-chromosome.pl --chr=7 --N=100 --bfile=AA --out=BDI --covar=covariate.cov --Rplink=Rplink.R --silent


=head1 AUTHOR


 Richard Duncan, richard.duncan@emory.edu
 Emory University, School of Medicine
 Department of Human Genetics


=cut  

exit;
