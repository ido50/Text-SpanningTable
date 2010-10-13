#!perl -T

use strict;
use warnings;
use Test::More;
use Text::FlexiTable;

my $t = Text::FlexiTable->new(14, 20, 10);

diag("\n");
diag($t->hr('top'));
diag($t->row('oneoneoneoneoneoneoneoneone', 'two', 'threeaasdf qwerasdf lzxcvszxcvzxcvzxcv zxcv zxcv zxccccccc'));
diag($t->hr);
diag($t->row("now who's the\nfucking child", 'two', 'three'));
diag($t->hr('bottom'));

done_testing();
