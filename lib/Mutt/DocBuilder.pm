package Mutt::DocBuilder;

use common::sense;

use Mutt::Platform qw(temp_directory);
use Data::Dump qw(pp);
use File::Basename;
use File::Copy;
use File::Path;
use JSON::XS;
use Moose;

use namespace::clean -except => [qw(meta)];

has 'base_dir' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $dir = dirname ($0);
		$dir =~ s/\\/\//g;
		return $dir;
	}
);

has 'config' => (
	is => 'ro',
	isa => 'HashRef',
	lazy => 1,
	default => sub {
		my $self = shift;

		my $filename = $self->source . '/config.json';

		my $json;
		eval {
			local $/ = undef;
			open (my $fh, "<", $filename)
				|| die "Unable to open file: $!";
			$json = <$fh>;
			close $fh;
		};

		eval {
			$json = decode_json ($json);
		};

		return $json || {};
	}
);

has 'global_replacements' => (
	is => 'ro',
	isa => 'HashRef',
	lazy => 1,
	default => sub {
		my $self = shift;

		my $filename = $self->templates . '/global-replacements.json';

		my $json;
		eval {
			local $/ = undef;
			open (my $fh, "<", $filename)
				|| die "Unable to open file: $!";
			$json = <$fh>;
			close $fh;
		};

		eval {
			$json = decode_json ($json);
		};

		return $json || {};
	},
);

has 'images' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;
		return $self->base_dir . "/images";
	}
);

has 'index' => (
	is => 'ro',
	isa => 'Int',
	lazy => 1,
	default => sub {
		return shift->config->{index} ? 1 : 0;
	}
);

has 'language' => (
	is => 'ro',
	isa => 'Str',
	required => 1
);

has 'merged_markdown' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;

		return $self->temp_dir . '/' . $self->title . ".md";
	}
);

has 'output' => (
	is => 'ro',
	isa => 'Str',
	required => 1
);

has 'pdf_filename' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;

		my $title = $self->title;

		if ($self->version) {
			$title .= '_v' . $self->version;
		}

		$title .= '_' . uc ($self->language) . ".pdf";

		$title =~ s/\s+/_/g;

		return $title;
	}
);

has 'replacements' => (
	is => 'ro',
	isa => 'HashRef',
	lazy => 1,
	default => sub {
		my $self = shift;

		my $filename = $self->source . '/replacements.json';

		my $json;
		eval {
			local $/ = undef;
			open (my $fh, "<", $filename)
				|| die "Unable to open file: $!";
			$json = <$fh>;
			close $fh;
		};

		eval {
			$json = decode_json ($json);
		};

		$json ||= {};
		$json->{$self->language} ||= {};
		$json->{global} ||= {};

		my $globals = $self->global_replacements;
		for my $key (keys %{$globals}) {
			unless ($json->{global}->{$key}) {
				$json->{global}->{$key} = $globals->{$key};
			}
		}

		unless ($json->{global}->{___VERSION___}) {
			my $version = '';
			if ($self->version) {
				$version = 'v' . $self->version;
			}

			$json->{global}->{___VERSION___} = $version;
		}

		# Replace {{___COPYRIGHT___}} in copyright template with correct start and
		# end years.  If start year is the same as current year then only one year
		# is displayed.
		my $current_year = (localtime)[5] + 1900;
		my $start_year   = $self->config->{copyright} || $current_year;

		my $years;
		if ($current_year ne $start_year) {
			$years = "$start_year-$current_year";
		}
		else {
			$years = "$start_year";
		}

		$json->{global}->{___COPYRIGHT___} = $years;

		return $json;
	},
);

has 'source' => (
	is => 'ro',
	isa => 'Str',
	required => 1
);

has 'source_dir' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;

		return $self->source . '/' . $self->language;
	}
);

has 'table_ids' => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	default => sub {
		my @table_ids;
		return \@table_ids;
	}
);

has 'tag_subroutines' => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	default => sub {
		my @subs = qw(process_images process_indexes process_links process_replacements);
		return \@subs;
	}
);

has 'temp_dir' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $temp_dir = temp_directory . "/docbuilder-$$";

		unless (-d $temp_dir) {
			mkdir $temp_dir
				|| die "Unable to create temp directory '$temp_dir': $!";
		}

		return $temp_dir;
	}
);

has 'templates' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		return shift->base_dir . "/templates";
	}
);

has 'title' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		return shift->config->{title} || "Untitled Document";
	}
);

has 'version' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		return shift->config->{version} || '';
	}
);

has 'xml_file' => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub {
		my $self = shift;
		return $self->temp_dir . '/' . $self->title . ".xml";
	}
);

sub build {
	my $self = shift;

	$self->copy_images;
	$self->merge_markdown;
	$self->markdown_to_xml;
	$self->create_table_ids;
	$self->parse_xml;
	$self->xml_to_pdf;
	$self->cleanup;
}

sub cleanup {
	rmtree (shift->temp_dir);
}

sub copy_images {
	my $self = shift;

	say "Copying document images...";

	for my $path ($self->images, $self->source . '/images') {
		if (-d $path) {
			opendir (my $dh, $path)
				|| die "Unable to open directory: $!";

			while (my $entry = readdir $dh) {
				next if ($entry eq '.' || $entry eq '..');
				copy ("$path/$entry", $self->temp_dir . '/.')
					|| die "Failed to copy image file: $!";
			}

			closedir $dh;
		}
	}
}

sub create_table_ids {
	my $self = shift;

	my $table_ids = $self->table_ids;

	# Extract all table titles in order so that ids can be inserted during
	# parse-xml
	open (my $ifh, "<:utf8", $self->xml_file)
		|| die "Unable to open file: $!";

	while (my $line = <$ifh>) {
		if ($line =~ m/<table>/m) {
			<$ifh>;

			# This will be the table's title
			my $table_id = <$ifh>;

			# Convert title to supported id format...
			$table_id =~ s/^\s+//g;
			$table_id =~ s/\s+$//g;
			$table_id = lc $table_id;
			$table_id =~ s/[^a-z0-9 ]//g;
			$table_id =~ s/ /-/g;

			push @{$table_ids}, "tbl-$table_id";
		}
	}

	close $ifh;
}

sub markdown_to_xml {
	my $self = shift;

	my @args = qw(pandoc -s -f markdown -t docbook -o);
	push @args, $self->xml_file;
	push @args, $self->merged_markdown;

	system (@args) == 0
		or die "system @args failed: $?";
}

sub merge_markdown {
	my $self = shift;

	my $replacements = $self->replacements;

	say "Creating merged book source: " . $self->merged_markdown;

	open (my $ofh, '>:utf8', $self->merged_markdown)
		|| die "Unable to open output file: $!";

	# Insert the document title
	print $ofh "%" . $self->title . "\n\n";

	# Insert the copyright message
	my $copyright = $self->slurp ($self->templates . '/copyright.md') || '';

	$copyright =~ s/{{___COPYRIGHT___}}/$replacements->{global}->{___COPYRIGHT___}/g;
	$copyright =~ s/{{___COMPANY_NAME___}}/$replacements->{global}->{___COMPANY_NAME___}/g;

	print $ofh "$copyright\n\n";

	# Now merge the remaining files
	for my $file (sort $self->source_files) {
		say "Processing file: $file";

		open (my $ifh, '<:utf8', $self->source_dir . '/' .$file)
			|| die "Unable to open input file: $!";

		while (my $line = <$ifh>) {

			my $prev_line;
			do {
				$prev_line = $line;
				for my $sub (@{$self->tag_subroutines}) {
					$line = $self->$sub ($line);
				}
			} until ($line eq $prev_line);

			# Leave escaped tags alone and remove the escape character as a
			# final step
			$line =~ s/\\{{/{{/g;

			print $ofh $line;
		}

		print $ofh "\n\n";
		close $ifh;
	}

	close $ofh;
}

sub parse_xml {
	my $self = shift;

	my $table_ids = $self->table_ids;
	my $table_idx = 0;

	open (my $ofh, ">:utf8", $self->xml_file . '.1')
		|| die "Unable to open file: $!";

	open (my $ifh, "<:utf8", $self->xml_file)
		|| die "Unable to open file: $!";

	while (my $line = <$ifh>) {
		if ($line =~ m/<sect1/) {
			print $ofh "<?hard-pagebreak?>\n";
		}
		elsif ($line =~ m/<programlisting>/) {
			$line =~ s/<programlisting>\n/<programlisting>/g;
		}
		elsif ($line =~ m/<table>/) {
			my $table_id = $table_ids->[$table_idx];
			$table_idx++;
			$line =~ s/<table>/<table id="$table_id">/g;
		}
		elsif ($line =~ m/<\/article>/ && $self->index) {
			$line = "<?hard-pagebreak?>\n<index />\n$line";
		}
		elsif ($line =~ m/<title>$/) {
			$line =~ s/<title>\n/<title>/g;
			my $text = <$ifh>;
			my $end_title = <$ifh>;

			for ($text, $end_title) {
				$_ =~ s/^\s+//g;
				$_ =~ s/\s+$//g;
			}
			$line .= $text . $end_title . "\n";
		}

		print $ofh $line;
	}

	close $ifh;
	close $ofh;

	unlink $self->xml_file;
	copy ($self->xml_file . '.1', $self->xml_file);
	unlink $self->xml_file . '.1';
}

sub process_images {
	my $self = shift;
	my $line = shift;

	# Support custom images tags, eg.:
	#
	# {{img:image_filename.png(Optional Image Title)|Comma:1,Seperated:1,Params:1}}
	if ($line =~ m/(?<!\\)(\{\{img:([^|()]+)(?:\((.+)\))?(?:\|([^}]+))?\}\})/m) {
		my $captured_tag      = quotemeta $1;
		my $captured_filename = $2;
		my $captured_title    = $3;
		my $captured_params   = $4;

		# Build the image object using filename and params, if any...
		my @imagedata_params;

		if ($captured_params) {
			my @split_params = split (/,/, $captured_params);

			for my $param (@split_params) {
				my ($key, $value) = split (/:/, $param);
				push @imagedata_params, "$key=\"$value\"";
			}
		}

		push @imagedata_params, "fileref=\"$captured_filename\"";

		# Base imagedata markup
		my $imageobject = "<imageobject><imagedata ";
		$imageobject .= join (' ', @imagedata_params);
		$imageobject .= " /></imageobject>";

		# If there's a title then we turn it into a figure, otherwise
		# it's just treated asn an inlinemediaobject
		if ($captured_title) {
			$captured_title =~ s/^\s+//g;
			$captured_title =~ s/\s+$//g;

			my $figure_id = lc $captured_title;
			$figure_id =~ s/[^a-z0-9 ]//g;
			$figure_id =~ s/ /-/g;

			$imageobject = "<figure id=\"fig-$figure_id\"><title>$captured_title</title>"
				. "<mediaobject>$imageobject<textobject><phrase>"
				. "$captured_title</phrase></textobject></mediaobject>"
				. "</figure>";
		}
		else {
			$imageobject = "<inlinemediaobject>$imageobject</inlinemediaobject>";
		}

		$line =~ s/$captured_tag/$imageobject/g;
	}

    return $line;
}

sub process_indexes {
	my $self = shift;
	my $line = shift;

	# Support indexes
	#
	# {{index:sausage:primary|secondary|tertiary}}
	#
	if ($line =~ m/(?<!\\)(\{\{index:([^|}]+)(?:\|([^|]+))?(?:\|([^|]+))?(?:\|([^|]+))?\}\})/m) {
		my $captured_tag = quotemeta $1;
		my $word      = $2;
		my $primary   = $3;
		my $secondary = $4;
		my $tertiary  = $5;

		if (!$primary) {
			$primary = $word;
		}

		my $index_object = "<indexterm>";
		$index_object .= "<primary>$primary</primary>";

		if ($secondary) {
			$index_object .= "<secondary>$secondary</secondary>";
		}

		if ($tertiary) {
			$index_object .= "<tertiary>$tertiary</tertiary>";
		}

		$index_object .= "</indexterm>$word";

		$line =~ s/$captured_tag/$index_object/g;
	}

	return $line;
}

sub process_links {
	my $self = shift;
	my $line = shift;

	# Support link tags
	#
	# {{link:Section Title}}
	#
	if ($line =~ m/(?<!\\)(\{\{link\|(figure|section|table):(.+)\}\})/m) {
		my $captured_tag = quotemeta $1;
		my $type  = lc $2;
		my $label = $3;

		$label = lc $label;
		$label =~ s/[^a-z0-9 ]//g;
		$label =~ s/ /-/g;

		if ($type eq 'figure') {
			$label = "fig-$label";
		}
		elsif ($type eq 'table') {
			$label = "tbl-$label";
		}

		my $link = "<xref linkend='$label' />";

		$line =~ s/$captured_tag/$link/g;
	}

	return $line;
}

sub process_replacements {
	my $self = shift;
	my $line = shift;

	my $replacements = $self->replacements;

	if ($line =~ m/(?<!\\)\{\{/m) {
		for my $key (keys %{$replacements->{$self->language}}) {
			$line =~ s/{{$key}}/$replacements->{$self->language}->{$key}/g;
		}

		for my $key (keys %{$replacements->{global}}) {
			$line =~ s/{{$key}}/$replacements->{global}->{$key}/g;
		}
	}

	return $line;
}

sub slurp {
	my $self = shift;
	my $filename = shift;

	my $text;
	eval {
		local $/ = undef;
		open (my $fh, "<:utf8", $filename)
			|| die "Unable to open file: $!";
		$text = <$fh>;
		close $fh;
	};

	return $text;
}

sub source_files {
	my $self = shift;

	my $dir = $self->source . '/' . $self->language;

	opendir (my $dh, $self->source_dir)
		|| die "Unable to open directory: $!";

	my @source_files;

	while (my $entry = readdir $dh) {
		next if ($entry eq '.' || $entry eq '..');
		next unless $entry =~ m/\.md$/;
		push @source_files, $entry;
	}

	closedir $dh;

	return @source_files;
}

sub xml_to_pdf {
	my $self = shift;

	my $base_dir = $self->base_dir;
	my $xml_file = $self->xml_file;
	my $pdf_filename = $self->output . '/' . $self->pdf_filename;

	$pdf_filename =~ s/\\/\//g;

	my @args = (
		"fop",
		"-c",   "$base_dir/conf/fop.xconf",
		"-xml", "$xml_file",
		"-xsl", "$base_dir/style/stylesheet.xsl",
		"-pdf", "\"$pdf_filename\""
	);

	system (@args) == 0
		or die "system @args failed: $?";
}

__PACKAGE__->meta->make_immutable;

1;
