package Algorithm::PageRank::XS;

use 5.008005;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Algorithm::PageRank::XS', $VERSION);

=head1 NAME

Algorithm::PageRank::XS - Fast PageRank implementation

=head1 DESCRIPTION

<Algorithm::PageRank> does some pagerank calculations, but it's 
slow and memory intensive. This was developed to compute pagerank
on graphs with millions of arcs. It will not, however, scale up to
quadrillions of arcs unless you have a lot of local memory. This is
not a distributed algorithm.

=head1 SYNOPSYS

    use Algorithm::PageRank::XS;

    my $pr = Algorithm::PageRank::XS->new(alpha => 0.85);

    $pr->graph([
              0 => 1,
              0 => 2,
              1 => 0,
              2 => 1,
              ]
              );

    $pr->result();


    # This simple program takes up arcs and prints the ranks.

    use Algorithm::PageRank::XS;

    my $pr = Algorithm::PageRank::XS->new(alpha => 0.85);

    while (<>) {
        chomp;
        my ($from, to) = split(/\t/, $_);
        $pr->add_arc($from, $to);
    }

    while (my ($name, $rank) = each(%{$pr->result()})) {
        print("$name,$rank\n");
    }

=head1 CONSTRUCTORS

=over

=item new %PARAMS

Create a new PageRank object. Parameters are: C<alpha>, C<max_tries>, and C<convergence>. C<alpha> is the damping constant (how far from the true eigenvector you are. C<max_tries> is the maximum number of iterations to run. C<convergence> is how close our vectors must be before we say we are done.

=cut

sub new {
    my ($class, %params) = @_;

    my $self = {
        alpha => 0.85,
        max_tries => 200,
        convergence => 0.001,

        %params,

        dim_map => {},
        rev_map => {},
    };

    bless $self, $class;
    $self->init();
    return $self;
}


sub init ($) {
    my $self = $_[0];
    $self->{dim_map} = {};
    $self->{rev_map} = {};
    $self->{table} = pr_tableinit();
}

=item add_arc

Add an arc to the pagerank object before running the computation.
The actual values don't matter. So you can run:

    $pr->add_arc("Apple", "Orange");

To mean that C<"Apple"> links to C<"Orange">.

=cut

sub add_arc ($$$) {
    my ($self, $from, $to) = @_;

    $from = $self->_dim_map($from);
    $to = $self->_dim_map($to);
    pr_tableadd($self->{table}, $from, $to) or croak("Unable to add arc to pagerank table.");
}

=item graph

Add a graph, which is just an array of from, to combinations.
This is equivalent to calling C<add_arc> a bunch of times, but may
be more convenient.

=cut

sub graph ($$) {
    my ($self, $graph) = @_;

    if (scalar @{$graph} % 2 == 1) {
        croak("Odd number of members of graph. Even number expected.");
    }
    for (my $i = 0; $i < scalar @{$graph}; $i += 2) {
        $self->add_arc($graph->[$i], $graph->[$i + 1]);
    }
}

=item results

Compute the pagerank vector, and return it as a hash.

Whatever you called the nodes when specifying the arcs will be the keys of this hash, where the values will be the vector (which should sum to C<1>).

=cut

sub results ($) {
    my $self = $_[0];

    if (pr_tablesize($self->{table}) < 2) {
        carp("Unable to compute PageRank since graph size is too small.");
        return [];
    }

    my $results = pr_pagerank($self->{table}, scalar keys %{$self->{dim_map}}, $self->{alpha}, $self->{convergence}, $self->{max_tries});
    if (!$results or ref $results ne 'ARRAY') {
        return {};
    }

    my %better_results = ();
    for (my $i=0; $i < scalar @{$results}; $i++) {
        $better_results{$self->{rev_map}->{$i}} = $results->[$i];
    }
    undef $results;

    pr_tabledel($self->{table});

    $self->init();
    
    return \%better_results;
}

sub _dim_map ($$) {
    my ($self, $item) = @_;

    if (defined($self->{dim_map}->{$item})) {
        return $self->{dim_map}->{$item};
    }
    else {
        my $i = scalar keys %{$self->{dim_map}};
        $self->{dim_map}->{$item} = $i;
        $self->{rev_map}->{$i} = $item;
        return $i;
    }
}

1;
__END__

=back

=head1 PERFORMANCE

This module is pretty fast. I ran this on a 1 million node set with 4.5 million arcs in 57 seconds on my 32-bit 1.8GHz laptop. Let me know if you have any performance tips.

=head1 COPYRIGHT

Copyright (C) 2008 by Michael Axiak <mike@axiak.net>

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself

=cut
