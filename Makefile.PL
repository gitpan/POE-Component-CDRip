#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		    => 'POE::Component::CDRip',
	VERSION_FROM	=> 'CDRip.pm', 
	AUTHOR          => 'Erick Calder <ecalder@cpan.org>',
	ABSTRACT        => 'POE Component for running the cdparanoia ripper.',
	PREREQ_PM       => { POE => '0.22' },
	);
