#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;


{
    package Foo;
    use Mouse;

    has 'bar' => (
        is       => 'ro',
        required => 1,
    );

    # Defining this causes the FIRST call to Baz->new w/o param to fail,
    # if no call to ANY Mouse::Object->new was done before.
    sub DEMOLISH {
        my ( $self ) = @_;
        # ... Mouse (kinda) eats exceptions in DESTROY/DEMOLISH";
    }
}

{
    my $obj = eval { Foo->new; };
    like( $@, qr/is required/, "... Foo plain" );
    is( $obj, undef, "... the object is undef" );
}

{
    package Bar;

    sub new { die "Bar died"; }

    sub DESTROY {
        die "Vanilla Perl eats exceptions in DESTROY too";
    }
}

{
    my $obj = eval { Bar->new; };
    like( $@, qr/Bar died/, "... Bar plain" );
    is( $obj, undef, "... the object is undef" );
}

{
    package Baz;
    use Mouse;

    sub DEMOLISH {
        $? = 0;
    }
}

{
    local $@ = 42;
    local $? = 84;

    {
        Baz->new;
    }

    is( $@, 42, '$@ is still 42 after object is demolished without dying' );
    is( $?, 84, '$? is still 84 after object is demolished without dying' );

    local $@ = 0;

    {
        Baz->new;
    }

    is( $@, 0, '$@ is still 0 after object is demolished without dying' );

    Baz->meta->make_immutable, redo
        if Baz->meta->is_mutable
}

{
    package Quux;
    use Mouse;

    sub DEMOLISH {
        die "foo\n";
    }
}

{
    local $@ = 42;

    eval { my $obj = Quux->new };

    like( $@, qr/foo/, '$@ contains error from demolish when demolish dies' );

    Quux->meta->make_immutable, redo
        if Quux->meta->is_mutable
}

