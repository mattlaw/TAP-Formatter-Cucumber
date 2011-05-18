package TAP::Formatter::Cucumber;

use strict;
use warnings;

=head1 NAME

TAP::Formatter::Cucumber - Shiny formatting for Test::Cukes tests

=head1 VERSION

0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    $ prove --formatter TAP::Formatter::Cucumber t

=head1 DESCRIPTION

This module displays the output of Test::Cukes tests in a format similar to
that produced by C<cucumber>.

The supported formats at present are:

=over

=item passed

Green. Used for passing tests i.e. TAP 'ok'.

=item failed

Red. Used for failing tests and related diagnostics. i.e. TAP 'not ok'

=item skipped

Cyan. Used for TAP skip messages

=item pending

Yellow. Used for TAP TODO tests, not supported by L<Test::Cukes> at time of
writing.

=item comment

Grey. Used for the step definition file/line comments

=back

Note that this is only a subset of the colours used by cucumber. See
L<https://github.com/cucumber/cucumber/wiki/Console-Colours> for the canonical
list. Notably all C<< *_param >> elements are unsupported.

=cut

use base qw( TAP::Formatter::Console );

use TAP::Formatter::Cucumber::Session;

BEGIN {
    # https://github.com/cucumber/cucumber/wiki/Console-Colours
    # I have no idea what the *_param ones mean..
    our %colour_map = (
        undefined     => 'yellow',
        pending       => 'yellow',
        pending_param => 'yellow,bold',
        failed        => 'red',
        failed_param  => 'red,bold',
        passed        => 'green',
        passed_param  => 'green,bold',
        skipped       => 'cyan',
        skipped_param => 'cyan,bold',
        comment       => 'grey',
        tag           => 'cyan',
    );

    if (defined $ENV{CUCUMBER_COLORS}) {
        my $valid_map = join '|', map quotemeta, keys %colour_map;
        for my $spec (split ':', $ENV{CUCUMBER_COLORS}) {
            # override existing values, ignore invalid ones
            my ($key, $value) = $spec =~ /^($valid_map)=([[:alpha:],])$/
                or next;

            $colour_map{$key} = $value;
        }
    }

    # Alias to work with Term::ANSIColor
    # this may or may not work with Win32::Console
    my %alias = (
        grey   => 'white',
        yellow => 'bright_yellow',
        red    => 'bright_red',
        green  => 'bright_green',
        cyan   => 'bright_cyan',
    );

    my $alias_pattern = join '|', map quotemeta, keys %alias;
    s/($alias_pattern)/$alias{$1}/e for values %colour_map;
}

sub open_test {
    my %args; @args{qw( formatter name parser )} = @_;

    return new TAP::Formatter::Cucumber::Session \%args;
}

sub output_cuke_element {
    my ($self, $type, $text) = @_;
    our %colour_map;

    if (my $found = $colour_map{$type}) {
        $self->_set_colors( split /,/, $found );
        $self->_output($text);
        $self->_set_colors('reset');
    }
    else {
        $self->_output($text);
    }
}

1;

__END__

=head1 ENVIRONMENT

=over

=item CUCUMBER_COLORS

Overrides the colours used for the various elements, as described on
L<https://github.com/cucumber/cucumber/wiki/Console-Colours>.

=back

=head1 SEE ALSO

=over

=item L<Test::Cukes>

=item L<Cucumber|https://github.com/cucumber/cucumber/wiki>

=back

=head1 AUTHOR

Matthew Lawrence E<lt>mattlaw@cpan.orgE<gt>

=cut


