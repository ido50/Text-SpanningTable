package Text::FlexiTable;

use warnings;
use strict;

# ABSTRACT: ASCII tables with support for column spanning.

our $C = {
	top => {
		left	=> '.-',
		border	=> '-',
		sep	=> '-+-',
		right	=> '-.',
	},
	middle => {
		left	=> '+-',
		border	=> '-',
		sep	=> '-+-',
		right	=> '-+',
	},
	bottom => {
		left	=> "'-",
		border	=> '-',
		sep	=> '-+-',
		right	=> "-'",
	},
	row => {
		left	=> '| ',
		sep	=> ' | ',
		right	=> ' |',
	},
};

=head1 NAME

Text::FlexiTable - ASCII tables with support for column spanning.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new( @col_lengths )

=cut

sub new {
	my ($class, @cols) = @_;

	my $width;
	
	unless (@cols) {
		$width = 100;
		@cols = (100);
	}

	foreach (@cols) {
		$width += $_;
	}

	return bless { cols => \@cols, width => $width }, $class;
}

=head2 hr( ['top'|'middle'|'bottom'] )

=cut

sub hr {
	my ($self, $type) = @_;

	$type ||= 'middle';

	my $output = $C->{$type}->{left};

	for (my $i = 0; $i < scalar @{$self->{cols}}; $i++) {
		my $num = $self->{cols}->[$i] - 4;
		$output .= $C->{$type}->{border} x$num;
		
		$output .= $C->{$type}->{sep} unless $i == (scalar @{$self->{cols}} - 1);
	}

	$output .= $C->{$type}->{right} . "\n";

	return $output;
}

# create a matrix that will hold all columns and 'pseudo-rows' of the row


=head2 row( @col_data )

=cut

sub row {
	my ($self, @data) = @_;

	my @rows;
	for (my $i = 0; $i < scalar @data; $i++) {
		$data[$i] .= ' 'x(4 - length($data[$i])) if length($data[$i]) < 4;
		my $new_string = '';
		my $width = $self->{cols}->[$i] - 4;
		if (length($data[$i]) > $width) {
			while (length($data[$i]) && length($data[$i]) > $width) {
				if (substr($data[$i], $width - 1, 1) =~ m/^\s+$/) {
					$new_string .= substr($data[$i], 0, $width, '') . "\n";
				} elsif (substr($data[$i], $width, 1) =~ m/^\s+$/) {
					$new_string .= substr($data[$i], 0, $width, '') . "\n";
				} else {
					$new_string .= substr($data[$i], 0, $width - 1, '') . "-\n";
				}
			}
			$new_string .= $data[$i] if length($data[$i]);
		} else {
			$new_string = $data[$i];
		}
		
		my @fake_rows = split(/\n/, $new_string);
		for (my $j = 0; $j < scalar @fake_rows; $j++) {
			$rows[$j]->[$i] = $fake_rows[$j];
		}
	}

	my $output = '';
	for (my $i = 0; $i < scalar @rows; $i++) {
		$output .= $C->{row}->{left};
		for (my $j = 0; $j < scalar @{$self->{cols}}; $j++) {
			my $width = $self->{cols}->[$j] - 4;
			$output .= exists $rows[$i]->[$j] ? $rows[$i]->[$j] . ' 'x($width - length($rows[$i]->[$j])) : ' 'x$width;
			$output .= $C->{row}->{sep} unless $j == (scalar @{$rows[$i]} - 1);
		}
		$output .= $C->{row}->{right} . "\n";
	}

	return $output;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-flexitable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-FlexiTable>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Text::FlexiTable

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-FlexiTable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-FlexiTable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-FlexiTable>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-FlexiTable/>

=back

=head1 ACKNOWLEDGEMENTS

Sebastian Riedel and Marcus Ramberg, authors of L<Text::SimpleTable>, on
which this module is based.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
