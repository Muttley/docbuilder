#!/usr/bin/env perl

use common::sense;

use Data::Dump qw(pp);
use File::Basename;
use FindBin;
use Getopt::Long;
use JSON::XS;

use lib "$FindBin::Bin/lib";

use Mutt::DocBuilder;

my $program = fileparse ($0);

my $options = {
	bootstrap => 0,
	language  => 'en',
	output    => '.',
	source    => './manual',
};

sub bootstrap {
	my $directory = $options->{output};

	my $dirname = $directory ne '.' ? $directory : 'current directory';
	say "Bootstrapping document in $dirname...";

	for my $dir ($directory, "$directory/en", "$directory/images") {
		unless (-d $dir) {
			mkdir $dir
				|| die "Unable to create output directory: $!";
		}
	}

	my $json_encoder = JSON::XS->new->ascii->pretty->allow_nonref;

	my $config = $json_encoder->encode ({
		copyright => (localtime)[5] + 1900,
		index => JSON::XS::false,
		title => 'Untitled Document',
		version => undef,
	});

	open my $fh, '>', "$directory/config.json"
		|| die "Unable to open file: $!";
	print $fh $config;
	close $fh;

	my $replacements = $json_encoder->encode ({
		"global" => {
			"___example___" => "Example Replacement",
		}
	});

	open my $fh, '>', "$directory/replacements.json"
		|| die "Unable to open file: $!";
	print $fh $replacements;
	close $fh;

	my $md = "# Chapter 1\n\nThis is the first chapter.\n";

	open my $fh, '>', "$directory/en/01.00-Chapter1.md"
		|| die "Unable to open file: $!";
	print $fh $md;
	close $fh;
}

sub handle_options {
	GetOptions(
		'bootstrap|b'  => \$options->{bootstrap},
		'language|l=s' => \$options->{language},
		'output|o=s'   => \$options->{output},
		'source|s=s'   => \$options->{source},
		'help|usage|?' => sub { usage(); },
	);
}

sub main {
	handle_options();

	if ($options->{bootstrap}) {
		bootstrap();
		exit;
	}

	Mutt::DocBuilder->new (
		language => $options->{language},
		output   => $options->{output},
		source   => $options->{source}
	)->build;
}

sub usage {
	print qq(
$program

    Processes a manual's source Markdown text files into a single PDF. These
    files must have a .md file extension.

options:

    --b|bootstrap   Bootstrap a new document project.  This creates a base
                    document project in the directory specified by the
                    --o|output option.

    --l|language    Language of the manual to be built. The language
                    sub-directory will automatically be appended to the
                    source directory. (default: "en")

    --o|output      The output directory where the final PDF should be
                    created (default: ".")

    --s|source      Base manual source directory.
                    (default: "./manual")

usage:

    $program
    $program --l de --s ./manual --o /opt/documents
    $program --l fr --s ./manual

);
	exit 1;
}

main();
