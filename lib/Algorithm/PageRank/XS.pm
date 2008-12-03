package Algorithm::PageRank::XS;

use 5.008005;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Algorithm::PageRank::XS', $VERSION);

=head1 NAME

Algorithm::PageRank::XS - A Fast PageRank implementation

=head1 DESCRIPTION

This module implements a simple PageRank algorithm in C. The goal is
to quickly get a vector that is closed to the eigenvector of the
stochastic matrix of a graph.

L<Algorithm::PageRank> does some pagerank calculations, but it's 
slow and memory intensive. This module was developed to compute pagerank
on graphs with millions of arcs. This module will not, however, scale
up to quadrillions of arcs (see L<TODO>).

=head1 SYNOPSYS

    use Algorithm::PageRank::XS;

    my $pr = Algorithm::PageRank::XS->new();

    $pr->graph([
              'John'  => 'Joey',
              'John'  => 'James',
              'Joey'  => 'John',
              'James' => 'Joey',
              ]
              );

    $pr->results();
    # {
    #      'James' => '0.569840431213379',
    #      'Joey'  => '1',
    #      'John'  => '0.754877686500549'
    # }



    #
    #
    # The following simple program takes up arcs and prints the ranks.
    use Algorithm::PageRank::XS;

    my $pr = Algorithm::PageRank::XS->new();

    while (<>) {
        chomp;
        my ($from, to) = split(/\t/, $_);
        $pr->add_arc($from, $to);
    }

    while (my ($name, $rank) = each(%{$pr->results()})) {
        print("$name,$rank\n");
    }

=head1 METHODS

=head2 new %PARAMS

Create a new PageRank object. Possible parameters:

=over 4

=item alpha

This is (1 - how much people can move from one node to another unconnected one randomly). Decreasing
this number makes convergence more likely, but brings us further from the true eigenvector.

=item max_tries

The maximum number of tries until we give up trying to achieve convergence.

=item convergence

The maximum number the difference between two subsequent vectors must be before we say we are
"convergent enough". The convergence rate is the rate at which C<alpha^t> goes to 0. Thus,
if you set C<alpha> to C<0.85>, and C<convergence> to C<0.000001>, then you will need C<85> tries.

=back

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

=head2 add_arc

Add an arc to the pagerank object before running the computation.
The actual values don't matter. So you can run:

    $pr->add_arc("Apple", "Orange");

and you mean that C<"Apple"> links to C<"Orange">.

=cut
sub add_arc ($$$) {
    my ($self, $from, $to) = @_;

    $from = $self->_dim_map($from);
    $to = $self->_dim_map($to);
    pr_tableadd($self->{table}, $from, $to) or croak("Unable to add arc to pagerank table.");
}


=head2 graph

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

=head2 results

Compute the pagerank vector, and return it as a hash.

Whatever you called the nodes when specifying the arcs will be the keys of this hash, where the
values will be the vector.

The result vector is normalized such that the maximum value is C<1>. This is to prevent extremely
small values for large data sets. You can normalize it any other way you like if you don't like this.

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


# PRIVATE METHODS
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

sub init ($) {
    my $self = $_[0];
    $self->{dim_map} = {};
    $self->{rev_map} = {};
    $self->{table} = pr_tableinit();
}


1;
__END__

=head1 BUGS

None known.

=head1 TODO

=over 4

=item * We may want to support C<double> values rather than single floats

=item * We may or may not want to adjust the weighting of individual arcs, as you cannot do now.

=item * At present the indexes are C<unsigned int>, rather than C<size_t>. Thus this will not scale with 64-bit architectures.

=item * It'd be nice to be able to use C<mmap(2)> to efficiently use the hard drive to scale to places where memory can't take us.

=back

=head1 PERFORMANCE

This module is pretty fast. I ran this on a 1 million node set with 4.5 million arcs in 57 seconds on my 32-bit 1.8GHz laptop. Let me know if you have any performance tips. It's orders of magnitude faster than L<Algorithm::PageRank>, but performance tests will be here shortly.

=head1 SEE ALSO

L<Algorithm::PageRank>

=head1 AUTHOR

Michael Axiak <mike@axiak.net>

=head1 COPYRIGHT

Copyright (C) 2008 by Michael Axiak <mike@axiak.net>

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself

=cut
