#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Algorithm::PageRank::XS;
my $pr = Algorithm::PageRank::XS->new( );

my @arcs;
for(1 .. 100) {
    push(@arcs, $_, $_ % 10);
}

$pr->graph(\@arcs);
use Devel::Dwarn; DwarnN($pr->result);