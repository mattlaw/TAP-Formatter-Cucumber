use strict;
use warnings;

use Test::More;
use Test::Cukes;
use TAP::Harness;

BEGIN {
    our @features = grep -f, glob 't/data/*.feature';

    plan tests => 0 + @features * 1;
}

use TAP::Formatter::Cucumber;

sub capture_cuke_output ($);

Given qr/A test/ => sub { 1 };

When qr/I receive the output/ => sub { 1 };

Then qr/it is formatted nicely/ => sub { 1 };

Given qr/FAIL/ => sub { die "FAIL\n" };

for my $feature (our @features) {
    my $tap = capture_cuke_output $feature;
    my ($cucumber, $cucumber_fh);

    open $cucumber_fh, '>', \$cucumber or die "Canot write to a scalar: $!";

    my $harness = new TAP::Harness {
        stdout => $cucumber_fh,
        merge  => 1,
        # tap    => $tap,
        color  => 1,

        formatter_class => 'TAP::Formatter::Cucumber',
    };
    $harness->runtests($tap);

    # Remove everything after the test report
    $cucumber =~ s/^Test\s+Summary\s+Report\b.*//sm;

    # Remove trailing empty lines
    $cucumber =~ s/^\s+\z//m;

    (my $expected = $feature) =~ s/\.feature$/.expect/;

    is($cucumber, slurp($expected), "Got expected output for $feature");
}

sub capture_cuke_output ($) {
    my $feature = shift;

    # note "Running $feature";

    pipe READ, WRITE;
    if (my $pid = fork) {
        close WRITE;
        local $/;
        my $tap = <READ>;
        waitpid $pid, 0;

        return $tap;
    }
    elsif (defined $pid) {
        close READ;
        my $data = slurp($feature);
        Test::Builder->new->output(\*WRITE);
        Test::Builder->new->failure_output(\*WRITE);
        Test::Cukes::runtests($data);
        exit;
    }
    else {
        die "Cannot fork: $!";
    }
}

sub slurp {
    my $file = shift;
    open my $fh, $file or die "Could not read '$file': $!\n";
    local $/;
    return <$fh>;
}
