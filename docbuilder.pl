#!/usr/bin/env perl

# Copyright (c) 2013-2017 Paul Maskelyne <muttley@muttleyville.org>.
#
# All rights reserved. Use of this code is allowed under the
# Artistic License 2.0 terms, as specified in the LICENSE file
# distributed with this code, or available from
# http://www.opensource.org/licenses/artistic-license-2.0.php

use common::sense;

use Data::Dump qw(pp);
use File::Basename;
use FindBin;
use Getopt::Long;
use JSON::XS;
use Path::Class;

use lib "$FindBin::Bin/lib";

use Mutt::DocBuilder;

my $program = fileparse ($0);

my $options = {
	debug => $ENV{DOCBUILDER_DEBUG} ||= 0,
	config => [],
	output => '.',
	source => './manual',
	language => 'en',
	bootstrap => 0,
	replacements => [],
	global_replacements => [],
};

sub bootstrap {
	my $base_dir = dir ($options->{output});

	my $dirname = "$base_dir" ne '.' ? "$base_dir" : 'current directory';

	say "Bootstrapping document in $dirname...";

	my @dirs = (
		$base_dir,
		dir ($base_dir, 'en'),
		dir ($base_dir, 'images')
	);

	for my $dir (@dirs) {
		unless (-d $dir) {
			mkdir $dir
				|| die "Unable to create output directory: $!";
		}
	}

	my $json_encoder = JSON::XS->new->ascii->pretty->allow_nonref;

	write_data_to_file(
		file ($base_dir, 'config.json'),
		$json_encoder->encode({
			copyright => (localtime)[5] + 1900,
			index     => JSON::XS::false,
			title     => 'Untitled Document',
			version   => undef,
		})
	);

	write_data_to_file(
		file ($base_dir, 'replacements.json'),
		$json_encoder->encode({
			global => {
				___example___ => "Example Replacement",
			}
		})
	);

	write_data_to_file(
		file ($base_dir, 'en', '01.00-Chapter1.md'),
		"# Chapter 1\n\nThis is the first chapter.\n"
	);

	write_data_to_file(
		file ($base_dir, 'images', '.empty'),
		""
	);
}

sub main {
	GetOptions(
		'debug|d' => \$options->{debug},
		'config|c=s' =>  $options->{config},
		'output|o=s' => \$options->{output},
		'source|s=s' => \$options->{source},
		'bootstrap|b' => \$options->{bootstrap},
		'help|usage|?' => sub { usage(); },
		'language|l=s' => \$options->{language},
		'replacements|r=s' => $options->{replacements},
		'global_replacements|g=s' => $options->{global_replacements},
	);

	if ($options->{bootstrap}) {
		bootstrap;
		exit;
	}

	my $docbuilder = Mutt::DocBuilder->new(
		debug    => $options->{debug},
		language => $options->{language},
		output   => $options->{output},
		source   => $options->{source}
	);

	for my $set (qw(config global_replacements replacements)) {
		for my $option (@{ $options->{$set} }) {
			my ($key, $value) = split /\=/, $option, 2;
			$docbuilder->$set->{$key} = $value;
		}
	}

	$docbuilder->build;

	if ($docbuilder->debug) {
		say "DEBUG: Temporary files can found at this location: "
			. $docbuilder->temp_dir;
	}
}

sub usage {
	print qq(
$program

    Processes a directory of source Markdown into a single PDF. These files
    must have a .md file extension.

    See the full documentation for details on additionally supported markup
    tags for inserting various document elements.

options:

    -b|bootstrap           Bootstrap a new document project.  This creates a
                           base document project in the directory specified
                           by the -o|output option.

    -d|debug               If debug mode is enabled, the temporary files
                           created when the document is being built are
                           kept for investigative reasons

    -l|language            Language of the manual to be built. The language
                           sub-directory will automatically be appended to
                           the source directory. (default: "en")

    -o|output              The output directory where the final PDF should be
                           created (default: ".")

    -s|source              Base manual source directory.
                           (default: "./manual")

    -c|config              config.json item formatted as key=value, can be
                           specified multiple times

    -g|global-replacement  global replacements.json item formatted as
                           key=value, can be specified multiple times

    -r|replacement         language specific replacements.json item formatted
                           as key=value, can be specified multiple times,
                           will be placed in the replacements list for the
                           language specified by the --language option

usage:

    $program
    $program -l de -s ./manual -o /opt/documents
    $program -l en -s . -c version=1.0.2
    $program -l fr -s ./manual

);
	exit 1;
}

sub write_data_to_file {
	my $file = shift;
	my $data = shift;

	open my $fh, '>', "$file"
		or die "Unable to open file '$file': $!";

	print $fh $data;

	close $fh;
}

main;
