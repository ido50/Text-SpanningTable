#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::FlexiTable' ) || print "Bail out!
";
}

diag( "Testing Text::FlexiTable $Text::FlexiTable::VERSION, Perl $], $^X" );
