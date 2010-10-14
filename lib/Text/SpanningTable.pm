package Text::SpanningTable;

use warnings;
use strict;

# ABSTRACT: ASCII tables with support for column spanning.

# this hash-ref holds the characters used to print the table decorations.
our $C = {
	top => {			# the top border, i.e. hr('top')
		left	=> '.-',
		border	=> '-',
		sep	=> '-+-',
		right	=> '-.',
	},
	middle => {			# simple horizontal rule, i.e. hr('middle') or hr()
		left	=> '+-',
		border	=> '-',
		sep	=> '-+-',
		right	=> '-+',
	},
	dhr => {			# double horizontal rule, i.e. hr('dhr') or dhr()
		left	=> '+=',
		border	=> '=',
		sep	=> '=+=',
		right	=> '=+',
	},
	bottom => {			# bottom border, i.e. hr('bottom')
		left	=> "'-",
		border	=> '-',
		sep	=> '-+-',
		right	=> "-'",
	},
	row => {			# row decoration
		left	=> '| ',
		sep	=> ' | ',
		right	=> ' |',
	},
};

=head1 NAME

Text::SpanningTable - ASCII tables with support for column spanning.

=head1 SYNOPSIS

	use Text::SpanningTable;

	# create a table object with four columns of varying widths
	my $t = Text::SpanningTable->new(10, 20, 15, 25);

	# enable auto-newline adding
	$t->newlines(1);
	
	# print a top border
	print $t->hr('top');
	
	# print a row (with header information)
	print $t->row('Column 1', 'Column 2', 'Column 3', 'Column 4');
	
	# print a double horizontal rule
	print $t->dhr; # also $t->hr('dhr');

	# print a row of data
	print $t->row('one', 'two', 'three', 'four');
	
	# print a horizontal rule
	print $t->hr;
	
	# print another row, with one column that spans all four columns
	print $t->row([4, 'Creedance Clearwater Revival']);
	
	# print a horizontal rule
	print $t->hr;
	
	# print a row with the first column normally and another column
	# spanning the remaining three columns
	print $t->row('normal', [3, 'spans three columns']);

	# finally, print the bottom border
	print $t->hr('bottom');

	# the output from all these commands is:
	.----------+------------------+-------------+-----------------------.
	| Column 1 | Column 2         | Column 3    | Column 4              |
	+==========+==================+=============+=======================+
	| one      | two              | three       | four                  |
	+----------+------------------+-------------+-----------------------+
	| Creedance Clearwater Revival                                      |
	+----------+------------------+-------------+-----------------------+
	| normal   | spans three columns                                    |
	'----------+------------------+-------------+-----------------------'

=head1 DESCRIPTION

C<Text::SpanningTable> provides a mechanism for creating simple ASCII tables,
with support for column spanning. It is meant to be used with monospace
fonts such as common in terminals, and thus is useful for logging purposes.

This module is inspired by L<Text::SimpleTable> and can generally produce
the same output (except that C<Text::SimpleTable> doesn't support column
spanning), but with a few key differences:

=over

=item * In C<Text::SimpleTable>, you build your table in the object and
C<draw> it when you're done. In C<Text::SpanningTable>, you can print
your table (or do whatever you want with the output) as it is being built.

=item * C<Text::SimpleTable> takes care of the top and bottom borders of
the table by itself. Due to C<Text::SpanningTable>'s "real-time" nature,
this functionality is not provided, and you have to take care of that yourself.

=item * C<Text::SimpleTable> allows you to pass titles for a header column
when creating the table object. This module doesn't have that functionality,
you have to create header rows (or footer rows) yourself and how you see
fit.

=item * C<Text::SpanningTable> provides a second type of horizontal rules
(called 'dhr' for 'double horizontal rule') that can be used for header
and footer rows (or whatever you see fit).

=item * C<Text::SpanningTable> provides an option to define a callback
function that can be automatically invoked on the module's output when
calling C<row()>, C<hr()> or C<dhr()>.

=item * In C<Text::SimpleTable>, the widths you define for the columns
are the widths of the data they can accommodate, i.e. without the borders
and padding. In C<Text::SpanningTable>, the widths you define are WITH
the borders and padding. If you are familiar with the CSS and the box model,
then columns in C<Text::SimpleTable> have C<box-sizing> set to C<content-box>,
while in C<Text::SpanningTable> they have C<box-sizing> set to C<border-box>.
So take into account that the width of the column's data will be four
characters less than defined.

=back

Like C<Text::SimpleTable>, the columns of the table will always be exactly
the same width as defined, i.e. they will not stretch to accommodate the
data passed to the rows. If a column's data is too big, it will be wrapped
(with possible word-breaking using the '-' character), thus resulting in
more lines of text.

=head1 METHODS

=head2 new( [@column_widths] )

Creates a new instance of C<Text::SpanningTable> with columns of the
provided widths. If you don't provide any column widths, the table will
have one column with a width of 100 characters.

=cut

sub new {
	my ($class, @cols) = @_;

	my $width; # total width of the table

	# default widths
	@cols = (100) unless @cols and scalar @cols;

	foreach (@cols) {
		$width += $_;
	}

	return bless {
		cols => \@cols,
		width => $width,
		newlines => 0,
	}, $class;
}

=head2 newlines( $boolean )

By default, newlines will NOT be added automatically to the output generated
by this module (for example, when printing a horizontal rule, a newline
character will not be added). Pass a boolean value to this method to
enable/disable automatic newline creation.

=cut

sub newlines {
	$_[0]->{newlines} = $_[1];
}

=head2 exec( \&sub, [@args] )

Define a callback function to be invoked whenever calling C<row()>, C<hr()>
or C<dhr()>. This function will receive, as arguments, the generated output,
and whatever else you've passed to this function (note C<@args> above).

=cut

sub exec {
	my $self = shift;

	$self->{exec} = shift;
	$self->{args} = \@_ if scalar @_;
}

=head2 hr( ['top'|'middle'|'bottom'|'dhr'] )

Generates a horizontal rule of a certain type. Unless a specific type is
provided, 'middle' we be used. 'top' generates a top border for the table,
'bottom' generates a bottom border, and 'dhr' is the same as 'middle', but
generates a 'double horizontal rule' that is more pronounced and thus can
be used for headers and footers.

This method will always result in one line.

=cut

sub hr {
	my ($self, $type) = @_;

	# generate a simple horizontal rule by default
	$type ||= 'middle';

	# start with the left decoration
	my $output = $C->{$type}->{left};

	# print a border for every column in the table, with separator
	# decorations between them
	for (my $i = 0; $i < scalar @{$self->{cols}}; $i++) {
		my $width = $self->{cols}->[$i] - 4;
		$output .= $C->{$type}->{border} x$width;

		# print a separator unless this is the last column
		$output .= $C->{$type}->{sep} unless $i == (scalar @{$self->{cols}} - 1);
	}

	# right decoration
	$output .= $C->{$type}->{right};

	# are we adding newlines?
	$output .= "\n" if $self->{newlines};

	# if a callback function is defined, invoke it
	if ($self->{exec}) {
		my @args = ($output);
		unshift(@args, @{$self->{args}}) if $self->{args};
		$self->{exec}->(@args);
	}

	return $output;
}

=head2 dhr()

Convenience method that simply calls C<hr('dhr')>.

=cut

sub dhr {
	return shift->hr('dhr');
}

=head2 row( @column_data )

Generates a new row of data. The array passed should contain the same
number of columns defined in the instance object, or, if column spanning
is used, the total amount of columns should be the same as defined.

When a column doesn't span, simply pass a scalar. When it does span, pass
an array-ref with two items, the first being the number of columns to span,
and the second with the scalar data. Passing an array-ref with 1 for the
first item is the same as just passing the scalar data (as the column will
simply span itself).

So, for example, if the table has nine columns, the following is a valid
value for C<@column_data>:

	( 'one', [2, 'two and three'], 'four', [5, 'five through nine'] )

If a column's data will be longer than its width, the data will wrapped
and broken, which results in the row being constructed from more than one
lines of text. Thus, as oppose to the C<hr()> method, this method has
two options for a return value. In list context, it will return all the
lines constructing the row (with or without newlines at the end of each
string, see C<newlines()> for more info). In scalar context, however, it
will return the row as a string containing newline characters that separate
the lines of text (once again, a trailing newline will be added to this
string only if a true value was passed to C<newlines()>).

If a callback function has be defined, it will not be invoked with the
complete output of this row (i.e. with all the lines of text that has
resulted), but instead will be called once per each line of text. This is
what makes the callback function so useful, as it helps you cope with
problems resulting from all the newline characters separating these lines.

=cut

sub row {
	my ($self, @data) = @_;

	my @rows; # will hold a matrix of the table

	my $done = 0; # how many columns have we generated yet?

	# go over all columns provided
	for (my $i = 0; $i < scalar @data; $i++) {
		# is this a spanning column? what is the width of it?
		my $width = 0;

		my $text; # will hold column's text

		if (ref $data[$i] eq 'ARRAY') {
			# this is a spanning column
			$text = $data[$i]->[1];

			foreach (0 .. $data[$i]->[0] - 1) {
				# $data[$i]->[0] is the number of columns this column spans
				$width += $self->{cols}->[$done + $_];
			}

			# subtract the number of columns this column spans
			# minus 1, because two adjacent columns share the
			# same separating border
			$width -= $data[$i]->[0] - 1;
			
			# increase $done with the number of columns we have
			# just parsed
			$done += $data[$i]->[0];
		} else {
			# no spanning
			$text = $data[$i];
			$width = $self->{cols}->[$done];
			$done++;
		}

		# make sure the column's data is at least 4 characters long
		# (because we're subtracting four from every column to make
		#  room for the borders and separators)
		$text .= ' 'x(4 - length($text)) if length($text) < 4;
		
		# subtract four from the width, for the column's decorations
		$width -= 4;

		# if the column's text is longer than the available width,
		# we need to wrap it.
		my $new_string = ''; # will hold parsed text
		if (length($text) > $width) {
			while (length($text) && length($text) > $width) {
				# if the $width'th character of the string
				# is a whitespace, just break it with a
				# new line.
				
				# else if the $width'th - 1 character of the string
				# is a whitespace, this is probably the start
				# of a word, so add a whitespace and a newline.
				
				# else if the $width'th + 1 character is a whitespace,
				# it is probably the end of a word, so just
				# break it with a newline.
				
				# else we're in the middle of a word, so
				# we need to break it with '-'.
				
				
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

		# if this row's data was split into more than one lines,
		# we need to store these lines appropriately in our table's
		# matrix (@rows).
		my @fake_rows = split(/\n/, $new_string);
		for (my $j = 0; $j < scalar @fake_rows; $j++) {
			$rows[$j]->[$i] = ref $data[$i] eq 'ARRAY' ? [$data[$i]->[0], $fake_rows[$j]] : $fake_rows[$j];
		}
	}

	# suppose one column's data was wrapped into more than one lines
	# of text. this means the matrix won't have data for all these
	# lines in other columns that did not wrap (or wrapped less), so
	# let's go over the matrix and fill missing cells with whitespace.
	for (my $i = 1; $i < scalar @rows; $i++) {
		for (my $j = 0; $j < scalar @{$self->{cols}}; $j++) {
			next if $rows[$i]->[$j];
			
			if (ref $rows[$i - 1]->[$j] eq 'ARRAY') {				
				my $width = length($rows[$i - 1]->[$j]->[1]);
				$rows[$i]->[$j] = [$rows[$i - 1]->[$j]->[0], ' 'x$width];
			}
		}
	}

	# okay, now we go over the matrix and actually generate the
	# decorated output
	my $output = '';
	for (my $i = 0; $i < scalar @rows; $i++) {
		$output .= $C->{row}->{left};
		
		my $push = 0; # how many columns have we generated already?

		# print the columns
		for (my $j = 0; $j < scalar @{$rows[$i]}; $j++) {
			my $width = 0;
			my $text;

			if (ref $rows[$i]->[$j] eq 'ARRAY') {
				# a spanning column, calculate width and
				# get the text
				$text = $rows[$i]->[$j]->[1];
				foreach (0 .. $rows[$i]->[$j]->[0] - 1) {
					$width += $self->{cols}->[$push + $_];
				}
				$width -= $rows[$i]->[$j]->[0] - 1;
			} else {
				# normal column
				$text = $rows[$i]->[$j];
				$width = $self->{cols}->[$push];
			}
			$width -= 4;

			# is there any text for this column? if not just
			# generate whitespace
			$output .= $text && length($text) ? $text . ' 'x($width - length($text)) : ' 'x$width;

			# increase the number of columns we just processed
			$push += ref $rows[$i]->[$j] eq 'ARRAY' ? $rows[$i]->[$j]->[0] : 1;

			# print a separator, unless this is the last column
			$output .= $C->{row}->{sep} unless $push == (scalar @{$self->{cols}});
		}

		# have we processed all columns? (i.e. has the user provided
		# data for all the columns?) if not, generate empty columns
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

	# invoke callback function, if any
	if ($self->{exec}) {
		my @args;
		push(@args, @{$self->{args}}) if $self->{args};
		foreach (split/\n/, $output) {
			chomp;
			push(@args, $_);
			$self->{exec}->(@args);
			pop @args;
		}
	}

	# is the user expecting an array? if so, split the output using
	# the newlines, otherwise just return it as is
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
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-SpanningTable>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Text::SpanningTable

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-SpanningTable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-SpanningTable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-SpanningTable>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-SpanningTable/>

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
