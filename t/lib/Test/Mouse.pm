package Test::Mouse;

use strict;
use warnings;
use Carp qw(croak);
use Mouse::Util qw(find_meta does_role);

use base qw(Test::Builder::Module);

our @EXPORT = qw(meta_ok does_ok has_attribute_ok);

sub meta_ok ($;$) {
    my ($class_or_obj, $message) = @_;

    $message ||= "The object has a meta";

    if (find_meta($class_or_obj)) {
        return __PACKAGE__->builder->ok(1, $message)
    }
    else {
        return __PACKAGE__->builder->ok(0, $message);
    }
}

sub does_ok ($$;$) {
    my ($class_or_obj, $does, $message) = @_;

    if(!defined $does){
        croak "You must pass a role name";
    }
    $message ||= "The object does $does";

    if (does_role($class_or_obj, $does)) {
        return __PACKAGE__->builder->ok(1, $message)
    }
    else {
        return __PACKAGE__->builder->ok(0, $message);
    }
}

sub has_attribute_ok ($$;$) {
    my ($class_or_obj, $attr_name, $message) = @_;

    $message ||= "The object does has an attribute named $attr_name";

    my $meta = find_meta($class_or_obj);

    if ($meta->find_attribute_by_name($attr_name)) {
        return __PACKAGE__->builder->ok(1, $message)
    }
    else {
        return __PACKAGE__->builder->ok(0, $message);
    }
}

# Moose compatible methods/functions

package
    Mouse::Meta::Module;

sub version   { no strict 'refs'; ${shift->name.'::VERSION'}   }
sub authority { no strict 'refs'; ${shift->name.'::AUTHORITY'} }
sub identifier {
    my $self = shift;
    return join '-' => (
       $self->name,
        ($self->version   || ()),
        ($self->authority || ()),
    );
}

package
    Mouse::Meta::Role;

for my $modifier_type (qw/before after around/) {
    my $modifier = "${modifier_type}_method_modifiers";
    my $has_method_modifiers = sub{
        my($self, $method_name) = @_;
        my $m = $self->{$modifier}->{$method_name};
        return $m && @{$m} != 0;
    };

    no strict 'refs';
    *{ 'has_' . $modifier_type . '_method_modifiers' } = $has_method_modifiers;
}


sub has_override_method_modifier {
    my ($self, $method_name) = @_;
    return exists $self->{override_method_modifiers}->{$method_name};
}

sub get_method_modifier_list {
    my($self, $modifier_type) = @_;

    return keys %{ $self->{$modifier_type . '_method_modifiers'} };
}

package
    Mouse::Util::TypeConstraints;

use Mouse::Util::TypeConstraints ();

sub export_type_constraints_as_functions { # TEST ONLY
    my $into = caller;

    foreach my $type( list_all_type_constraints() ) {
        my $tc = find_type_constraint($type)->_compiled_type_constraint;
        my $as = $into . '::' . $type;

        no strict 'refs';
        *{$as} = sub{ &{$tc} || undef };
    }
    return;
}

package
    Mouse::Meta::Attribute;

sub applied_traits{            $_[0]->{traits} } # TEST ONLY
sub has_applied_traits{ exists $_[0]->{traits} } # TEST ONLY

sub has_documentation{ exists $_[0]->{documentation} } # TEST ONLY
sub documentation{            $_[0]->{documentation} } # TEST ONLY

1;

__END__

=pod

=head1 NAME

Test::Mouse - Test functions for Mouse specific features

=head1 SYNOPSIS

  use Test::More plan => 1;
  use Test::Mouse;

  meta_ok($class_or_obj, "... Foo has a ->meta");
  does_ok($class_or_obj, $role, "... Foo does the Baz role");
  has_attribute_ok($class_or_obj, $attr_name, "... Foo has the 'bar' attribute");

=cut

