#!perl -T

use strict;
use warnings;
use Test::More;
use Text::SpanningTable;

my $t = Text::SpanningTable->new(14, 20, 10);

ok($t, 'Got a proper Text::SpanningTable object');

#diag("\n");
#diag($t->hr('top'));
#diag($t->row('oneoneoneoneoneoneoneoneone', 'two', 'threeaasdf qwerasdf lzxcvszxcvzxcvzxcv zxcv zxcv zxccccccc'));
#diag($t->hr);
#diag($t->row([2, 'round round get around i get around, get around round round i get around, i get around round round round i get around...'], 'asdfasdf'));
#diag($t->hr);
#diag($t->row("now who's the\nfucking child", 'two', 'three'));
#diag($t->hr('bottom'));

#my $t2 = Text::SpanningTable->new(10, 20, 10, 30);
#diag("\n\n");
#diag($t2->hr('top'));
#diag($t2->row('one', 'two', 'three', 'four'));
#diag($t2->hr);
#diag($t2->row('somebody once told me the world is gonna roll me', [2, 'i ain\'t the sharpest tool in the shed'], 'and stuff'));
#diag($t2->hr);
#diag($t2->row([3, 'but if you wanna shoot me you\'re gonna have to fool me, cause i don\'t like it when we\'re in bed'], 'that\'s right girl'));
#diag($t2->hr);
#diag($t2->row('and hey now, you\'re a rock star', [3, 'put on your gay face']));
#diag($t2->hr);
#diag($t2->row('go, weeeeeeeelllllllllllllllllllllllllll', 'hey now', [2, 'you\'re so stupid']));
#diag($t2->hr);
#diag($t2->row([4, 'why you so stupid stupid?']));
#diag($t2->hr);
#diag($t2->row('bitch my man ain\'t your baby\'s daddy'));
#diag($t2->hr('bottom'));

done_testing();
