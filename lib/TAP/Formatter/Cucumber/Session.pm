package TAP::Formatter::Cucumber::Session;

use strict;
use warnings;

=head1 NAME

TAP::Formatter::Cucumber::Session

=cut

use base qw( TAP::Formatter::Console::Session );

# Quick-n-dirty state accessors
BEGIN {
    for my $field (qw( in_feature last_comment last_test scenarios )) {
        my $glob = do { no strict 'refs'; \*$field };
        *$glob = sub {
            my $slot = \shift->{"cuke_$field"};
            $$slot = shift if @_;
            return $$slot;
        }
    }
}

sub _initialize {
    my $self = shift;

    $self->scenarios([]);

    return $self->SUPER::_initialize(@_);
}

my $cuke_test_re = qr{
    ^
    (?:not\s+)?
    ok\s+[0-9]+
    \s*(?:-|(?i:\#\s*skip|todo))\s* # Description required
    (?=Given|[WT]hen|And|But) # to begin with a Gherkin keyword
}x;

sub result {
    my ($self, $result) = @_;

    if ($result->is_comment) {
        local $_ = $result->raw;

        if (my ($cuke_comment) = /^# (.*:[0-9]+)$/) {
            $self->last_comment($cuke_comment);
        }
        elsif (s/^#\s+(?=Scenario:)/  /) {
            # This is usually green, but I'm not sure if it's logically
            # "passed"

            push @{$self->scenarios}, { name => $_, type => 'passed' };
        }
        elsif (s/^# (?=Feature:)// || $self->in_feature) {
            $self->in_feature(1);

            s/^#\s+/  /;
            return unless /\S/;

            # This is a hardcoded white colour
            $self->formatter->_set_colors("bright_white");
            $self->formatter->_output("$_\n");
            $self->formatter->_set_colors('reset');

            return;
        }
        elsif ($self->last_test && ! $self->last_test->is_ok) {
            # This is diagnostic output for a failed test
            # indent with 6 spaces
            s/^#\s+/      /;

            push @{$self->scenarios->[-1]{diag}}, $_ if /\S/;
        }
        else {
            $self->formatter->_output("$_\n");
        }

        $self->in_feature(0);
    }
    elsif ($result->is_test) {
        $self->last_test($result);
        my $test_type = (
            $result->has_todo ? 'pending' :
            $result->has_skip ? 'skipped' :
            $result->is_ok    ? 'passed'  :
                                'failed'
        );

        my $cuke_name = $result->raw;

        if ($cuke_name =~ s{$cuke_test_re}{    }) {

            # $self->formatter->_output("Orig:\n", $cuke_name, "\n\nNow:\n$out\n\n");
            push @{ $self->scenarios }, {
                type    => $test_type,
                name    => $cuke_name,
                comment => $self->last_comment,
            };

            $self->last_comment('');
        }
        else {
            # Not a cuke test, just output
            $self->formatter->_output($result->as_string, "\n");
        }
    }
}

sub close_test {
    my $self   = shift;

    # Could use List::Util::max
    my $maxlength = 0;
    for my $length (map length $_->{name}, @{$self->scenarios}) {
        $maxlength = $length if $length > $maxlength;
    }

    for my $section (@{ $self->scenarios }) {
        $self->formatter->output_cuke_element(@$section{qw( type name )});

        if ($section->{comment}) {
            my $indent = $maxlength - length $section->{name};

            # $self->formatter->_output("$maxlength / $indent");

            my $comment = ' ' x $indent . " # $section->{comment}";

            $self->formatter->output_cuke_element('comment', $comment);
        }
        $self->formatter->_output("\n");

        for my $diag (@{$section->{diag} || []}) {
            $self->formatter->output_cuke_element($section->{type}, $diag);
            $self->formatter->_output("\n");
        }
    }
}

1;

__END__

=head1 AUTHOR

Matthew Lawrence E<lt>mattlaw@cpan.orgE<gt>

=cut
