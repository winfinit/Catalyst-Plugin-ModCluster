use 5.008_008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::ModCluster',
    VERSION_FROM      => 'lib/Catalyst/Plugin/ModCluster.pm', # finds $VERSION
    PREREQ_PM         => {
        "Net::MCMP" => "0.01",
        "Catalyst"  => "0",
        "Text::SimpleTable" => "0"
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Catalyst/Plugin/ModCluster.pm', # retrieve abstract from module
       AUTHOR         => 'Roman Jurkov <winfinit@cpan.org>') : ()),
);
