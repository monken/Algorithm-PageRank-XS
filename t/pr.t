#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

use Algorithm::PageRank::XS;

my $pr = Algorithm::PageRank::XS->new();


$pr->graph([
    qw(
	       0 1
	       0 2
	       1 2
	       
	       3 4
	       3 5
	       3 6
	       4 3
	       4 6
	       5 3
	       5 6
	       6 4
	       6 3
	       6 5
	       )]);

is_deeply($pr->results(), {
          '6' => '0.280776411294937',
          '4' => '0.219223588705063',
          '1' => '1.70876356196881e-34',
          '3' => '0.280776411294937',
          '0' => '9.23655993404077e-35',
          '2' => '3.16121264703948e-34',
          '5' => '0.219223588705063'
        }, "Ran PageRank on simple graph");

