use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME			=> 'POE::Component::CDRip',
	VERSION_FROM	=> 'CDRip.pm', 
	AUTHOR			=> 'Erick Calder <ecalder@cpan.org>',
	ABSTRACT_FROM	=> 'CDRip.pm',
	PREREQ_PM		=> { POE => '0.22' },
	);
