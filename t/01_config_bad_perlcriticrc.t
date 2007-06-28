#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################


# Test that all the problems in an rc file get reported and not just the first
# one that is found.


use strict;
use warnings;
use English qw{ -no_match_vars };
use Readonly;

use Test::More;

use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic;

Readonly::Scalar my $TEST_COUNT => 12;
plan tests => $TEST_COUNT;

Readonly::Scalar my $PROFILE => 't/01_bad_perlcriticrc';
Readonly::Scalar my $INVALID_PARAMETER_MESSAGE =>
    q{The BuiltinFunctions::RequireBlockGrep policy doesn't take a "no_such_parameter" option.};
Readonly::Scalar my $REQUIRE_POD_SECTIONS_SOURCE_MESSAGE_PREFIX =>
    q{The value for the Documentation::RequirePodSections "source" option ("Zen_and_the_Art_of_Motorcycle_Maintenance") is not one of the allowed values: };

eval {
    my $critic = Perl::Critic->new( '-profile' => $PROFILE );
};

my $test_passed;
my $eval_result = $EVAL_ERROR;

$test_passed =
    ok( $eval_result, 'should get an exception when using a bad rc file' );

die "No point in continuing.\n" if not $test_passed;

$test_passed =
    isa_ok(
        $eval_result,
        'Perl::Critic::Exception::AggregateConfiguration',
        '$EVAL_ERROR',
    );

die "No point in continuing.\n" if not $test_passed;

my @exceptions = @{ $eval_result->exceptions() };

my @parameters = qw{
    exclude include severity single-policy theme top verbose
};

my %expected_regexes =
    map
        { $_ => generate_global_message_regex( $_, $PROFILE ) }
        @parameters;

my $expected_exceptions = 2 + scalar @parameters;
is(
    scalar @exceptions,
    $expected_exceptions,
    'should have received the correct number of exceptions'
);
if (@exceptions != $expected_exceptions) {
    diag "Exception: $_" foreach @exceptions;
}

while (my ($parameter, $regex) = each %expected_regexes) {
    is(
        ( scalar grep { m/$regex/ } @exceptions ),
        1,
        "should have received one and only one exception for $parameter",
    );
}

is(
    ( scalar grep { $INVALID_PARAMETER_MESSAGE eq $_ } @exceptions ),
    1,
    "should have received an extra-parameter exception",
);

is(
    ( scalar grep { is_require_pod_sections_source_exception($_) } @exceptions ),
    1,
    "should have received an invalid source exception for RequirePodSections",
);

sub generate_global_message_regex {
    my ($parameter, $file) = @_;

    return
        qr/
            \A
            The [ ] value [ ] for [ ] the [ ] global [ ]
            "$parameter"
            .*
            found [ ] in [ ] "$file"
        /xms;
}

sub is_require_pod_sections_source_exception {
    my ($exception) = @_;

    my $prefix =
        substr
            $exception,
            0,
            length $REQUIRE_POD_SECTIONS_SOURCE_MESSAGE_PREFIX;

    return $prefix eq $REQUIRE_POD_SECTIONS_SOURCE_MESSAGE_PREFIX;
}

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :