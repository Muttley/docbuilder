sub slurp_json {
	my $self = shift;
	my $filename = shift;

	my $json = $self->slurp ($filename);
	eval {
		$json = decode_json ($json);
	};

	return $json || {};
}
