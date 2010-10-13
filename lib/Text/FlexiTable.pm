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
	dhr => {
		left	=> '+=',
		border	=> '=',
		sep	=> '=+=',
		right	=> '=+',
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

	return bless { cols => \@cols, width => $width, newlines => 0 }, $class;
}

=head2 newlines( $boolean )

=cut

sub newlines {
	$_[0]->{newlines} = $_[1];
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

	$output .= $C->{$type}->{right};
	$output .= "\n" if $self->{newlines};

	return $output;
}

=head2 dhr()

=cut

sub dhr {
	return shift->hr('dhr');
}

=head2 row( @col_data )

=cut

sub row {
	my ($self, @data) = @_;

	my @rows;
	my $done = 0;
	for (my $i = 0; $i < scalar @data; $i++) {
		# is this a spanning column? what is the width of it
		my $width = 0;
		my $text;
		if (ref $data[$i] eq 'ARRAY') {
			$text = $data[$i]->[1];
			foreach (0 .. $data[$i]->[0] - 1) {
				# $data[$i]->[0] is the number of columns this column spans
				$width += $self->{cols}->[$done + $_];
			}
			$width -= $data[$i]->[0] - 1;
			$done += $data[$i]->[0];
		} else {
			$text = $data[$i];
			$width = $self->{cols}->[$done];
			$done++;
		}
		$width -= 4;

		# make sure the column's data is at least 4 characters long
		# (because we're subtracting four from every column to make
		#  room for the borders and separators)
		$text .= ' 'x(4 - length($text)) if length($text) < 4;

		my $new_string = '';
		if (length($text) > $width) {
			while (length($text) && length($text) > $width) {
				if (substr($text, $width - 1, 1) =~ m/^\s$/) {
					$new_string .= substr($text, 0, $width, '') . "\n";
				} elsif (substr($text, $width - 2, 1) =~ m/^\s$/) {
					$new_string .= substr($text, 0, $width - 1, '') . " \n";
				} elsif (substr($text, $width, 1) =~ m/^\s$/) {
					$new_string .= substr($text, 0, $width, '') . "\n";
				} else {
					$new_string .= substr($text, 0, $width - 1, '') . "-\n";
				}
			}
			$new_string .= $text if length($text);
		} else {
			$new_string = $text;
		}
		
		my @fake_rows = split(/\n/, $new_string);
		for (my $j = 0; $j < scalar @fake_rows; $j++) {
			$rows[$j]->[$i] = ref $data[$i] eq 'ARRAY' ? [$data[$i]->[0], $fake_rows[$j]] : $fake_rows[$j];
		}
	}

	for (my $i = 1; $i < scalar @rows; $i++) {
		for (my $j = 0; $j < scalar @{$self->{cols}}; $j++) {
			next if $rows[$i]->[$j];
			
			if (ref $rows[$i - 1]->[$j] eq 'ARRAY') {				
				my $width = length($rows[$i - 1]->[$j]->[1]);
				$rows[$i]->[$j] = [$rows[$i - 1]->[$j]->[0], ' 'x$width];
			}
		}
	}

	my $output = '';
	for (my $i = 0; $i < scalar @rows; $i++) {
		$output .= $C->{row}->{left};
		
		my $push = 0;
		
		for (my $j = 0; $j < scalar @{$rows[$i]}; $j++) {
			my $width = 0;
			my $text;
			
			if (ref $rows[$i]->[$j] eq 'ARRAY') {
				$text = $rows[$i]->[$j]->[1];
				foreach (0 .. $rows[$i]->[$j]->[0] - 1) {
					$width += $self->{cols}->[$push + $_];
				}
				$width -= $rows[$i]->[$j]->[0] - 1;
			} else {
				$text = $rows[$i]->[$j];
				$width = $self->{cols}->[$push];
			}
			$width -= 4;

			$output .= $text && length($text) ? $text . ' 'x($width - length($text)) : ' 'x$width;
			
			$push += ref $rows[$i]->[$j] eq 'ARRAY' ? $rows[$i]->[$j]->[0] : 1;

			$output .= $C->{row}->{sep} unless $push == (scalar @{$self->{cols}});
		}
		
		my $left = scalar @{$self->{cols}} - $push;
		
		if ($left) {
			for (my $k = 1; $k <= $left; $k++) {
				my $width = $self->{cols}->[$push++] - 4;
				$output .= ' 'x$width;
				$output .= $C->{row}->{sep} unless $k == $left;
			}
		}
		
		$output .= $C->{row}->{right} . "\n";
	}

	if (wantarray) {
		my @ret = split(/\n/, $output);
		foreach (@ret) {
			if ($self->{newlines}) {
				$_ .= "\n" unless m/\n$/;
			} else {
				s/\n$//;
			}
		}
		return @ret;
	} else {
		return $output;
	}
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
