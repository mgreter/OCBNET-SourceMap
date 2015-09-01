use 5.008000;
use ExtUtils::MakeMaker;

use strict;
use warnings;

# See lib/ExtUtils/MakeMaker.pm for details of how to
# influence content of the Makefile that is written.
WriteMakefile(
	NAME               => 'OCBNET::SourceMap',
	VERSION_FROM       => 'lib/OCBNET/SourceMap.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
	# runtime dependencies
	PREREQ_PM          => {
	    'JSON'                 => 0.01,
	    'File::Slurp'          => 0.01,
		'perl'                 => 5.008000,
		'Carp'                 => 1.01, # core as of 5.008
		'version'              => 0,
		'warnings'             => 0, # core as of 5.008
		'strict'               => 0 # core as of 5.008
	},
	# test dependencies
	TEST_REQUIRES      => {
	},
	# build dependencies
	BUILD_REQUIRES     => {
		'ExtUtils::MakeMaker'  => 6.52,
	},
	# build dependencies
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'  => 6.52,
	},
	# additional information
	META_MERGE => {
		resources => {
			license     => 'http://opensource.org/licenses/MIT',
			homepage    => 'https://metacpan.org/release/OCBNET-SourceMap',
			bugtracker  => 'https://github.com/mgreter/OCBNET-SourceMap/issues',
			repository  => 'https://github.com/mgreter/OCBNET-SourceMap',
		},
	},
	ABSTRACT_FROM      => 'lib/OCBNET/SourceMap.pm', # retrieve abstract from module
	AUTHOR             => q{Marcel Greter <perl-libsass@ocbnet.ch>},
	LICENSE            => 'MIT',
);
