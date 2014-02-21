#!/usr/bin/env perl

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
	bootstrap => 0,
	config    => [],
	debug     => $ENV{DOCBUILDER_DEBUG} ||= 0,
	language  => 'en',
	output    => '.',
	source    => './manual',
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
}

sub main {
	GetOptions(
		'bootstrap|b'  => \$options->{bootstrap},
		'config|c=s'   =>  $options->{config},
		'debug|d'      => \$options->{debug},
		'language|l=s' => \$options->{language},
		'output|o=s'   => \$options->{output},
		'source|s=s'   => \$options->{source},

		'help|usage|?' => sub { usage(); }
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

	for my $config_option (@{$options->{config}}) {
		my ($key, $value) = split (/\=/, $config_option, 2);
		$docbuilder->config->{$key} = $value;
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

    -b|bootstrap   Bootstrap a new document project.  This creates a base
                   document project in the directory specified by the
                   -o|output option.

    -c|config      Additional config options in key=value format. These
                   options will override any with the same name in the
                   document's config.json file.  Can be specified mutliple
                   times.

    -d|debug       Enable debug mode. Keeps generated temporary files for debug
                   purposes. Can also be enabled by setting a DOCBUILDER_DEBUG
                   environment variable to '1'.

    -l|language    Language of the manual to be built. The language
                   sub-directory will automatically be appended to the
                   source directory. (default: "en")

    -o|output      The output directory where the final PDF should be
                   created (default: ".")

    -s|source      Base manual source directory.
                   (default: "./manual")

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
