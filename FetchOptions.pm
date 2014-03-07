#-------------------------------------------------------------------------
# FetchOptions.pm
#-------------------------------------------------------------------------
#
#-------------------------------------------------------------------------
# Richard Duncan
# Emory University, School of Medicine
# Department of Human Genetics
# richard.duncan@emory.edu
#
#-------------------------------------------------------------------------
# perl module to construct string of plink command line arguments
# specified in file
#-------------------------------------------------------------------------
# sample usage:
#
# use Plink::FetchOptions;
# my $plink_cmd_options = &FetchOptions("plink-options");
#-------------------------------------------------------------------------

package FetchOptions;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT);

our $VERSION = 201403061023;
our @ISA = qw(Exporter);
our @EXPORT = qw(FetchOptions);


sub FetchOptions {

    # filename for plink options:
    my $options_file = shift;

    # construct the options not specific to any partition:
    my $opts = "";
    open(OPTS, "< $options_file");
    while(my $option = <OPTS>){
        chomp $option;
        if($option !~ m/^\#/) {

            my @opt_array = split(' ', $option);
            if($opt_array[1]){
                $opts = sprintf("%s --%s=%s", $opts, $opt_array[0], $opt_array[1]);
            } else {
                $opts = sprintf("%s --%s", $opts, $opt_array[0]);
            }

        } # match leading #

    } # while <OPTS>

    return $opts;
} # get_plink_options

1;

__END__


=head1 NAME

Plink::FetchOptions - Construct PLINK command line option string from file 

=head1 SYNOPSIS

  use Plink::FetchOptions;

  $plink_options = FetchOptions('plink-options-file');

=head1 DESCRIPTION

Store PLINK options used in a two column file where the first column
are plink command line options (without any leading '--' decorations)
and the second column is the value of the corresponding parameter when needed.

Here are example file contents:

#-- plink-options.txt --------------------
bfile    AA
covar    covariate.cov
R        Rplink.R
maf      0.0
outroot  plink
silent
#-----------------------------------------

The corresponding command line to be passed to PLINK would be
--bfile=AA --covar=covariate.cov --R=Rplink.R --maf=0.0 --outroot=plink --silent

Note that the --silent takes no argument, and so the second column in that row is 
left empty.

The call to produce the string of command line options for this case would be:

  $plink_options = FetchOptions('plink-options.txt');

Subsequent construction of the PLINK command might be something like this:

  $plink_cmd = sprintf("plink %s", $plink_options);

=head2 EXPORT

FetchOptions

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
