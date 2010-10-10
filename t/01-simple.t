#!perl -T

use strict;
use warnings;
use Test::More;
use Text::FlexiTable;

my $t = Text::FlexiTable->new(14, 20, 10);

diag("\n");
diag($t->hr('top'));
diag($t->row('one', 'two', 'three'));
diag($t->hr);
diag($t->row('one', 'two', 'three'));
diag($t->hr('bottom'));

done_testing();
