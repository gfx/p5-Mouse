#!/usr/bin/perl

use Test::More;

# without explicit 'strict'
{
    package Foo;
    use Mouse;
    use 5.010;

    eval 'sub bar { $x = 1 ; return $x }';
    ::ok($@, '... got an error because strict is on');
    ::like($@, qr/Global symbol \"\$foo\" requires explicit package name/, '... got the right error');

}

# with explicit 'strict'
{
  package Foo;
  use Mouse;
  use 5.010;
  use strict;

  eval 'sub bar { $x = 1 ; return $x }';
  ::ok($@, '... got an error because strict is on');
  ::like($@, qr/Global symbol \"\$x\" requires explicit package name/, '... got the right error');

}

done_testing();
