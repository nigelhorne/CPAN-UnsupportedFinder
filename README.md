# NAME

CPAN::UnsupportedFinder - Identify unsupported or poorly maintained CPAN modules.

# VERSION

Version 0.01

# SYNOPSIS

    use CPAN::UnsupportedFinder;

    my $finder = CPAN::UnsupportedFinder->new(verbose => 1);
    my $results = $finder->analyze('Some::Module', 'Another::Module');

    for my $module (@$results) {
            print "Module: $module->{module}\n";
            print "Failure Rate: $module->{failure_rate}\n";
            print "Last Update: $module->{last_update}\n";
    }

# DESCRIPTION

CPAN::UnsupportedFinder analyzes CPAN modules for test results and maintenance status, flagging unsupported or poorly maintained distributions.

# METHODS

## new

Creates a new instance. Accepts the following arguments:

- verbose

    Enable verbose output.

## analyze(@modules)

Analyzes the provided modules. Returns an array reference of unsupported modules.

# AUTHOR

Nigel Horne <njh@bandsman.co.uk>

# LICENSE

This program is released under the following licence: GPL2
