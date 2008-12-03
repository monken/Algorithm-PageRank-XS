use 5.008005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Algorithm::PageRank::XS',
    VERSION_FROM      => 'lib/Algorithm/PageRank/XS.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Algorithm/PageRank/XS.pm',
       AUTHOR         => 'Michael Axiak <mike@axiak.net>') : ()),
    DEFINE            => '',
    INC               => '-I.',
    OBJECT            => 'XS.o pagerank.o table.c',

    # Remove annoying temp files...
    clean             => {FILES => "*~"},
);
