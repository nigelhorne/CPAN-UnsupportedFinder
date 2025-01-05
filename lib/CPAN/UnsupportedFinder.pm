package CPAN::UnsupportedFinder;

use strict;
use warnings;

use JSON;
use HTTP::Tiny;
use Carp;
use Log::Log4perl;

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    my $self = {
        api_url      => 'https://fastapi.metacpan.org/v1',
        cpan_testers => 'https://api.cpantesters.org/api/v1',
        verbose      => $args{verbose} || 0,
    };

    Log::Log4perl->easy_init($self->{verbose} ? $Log::Log4perl::DEBUG : $Log::Log4perl::ERROR);
    $self->{logger} = Log::Log4perl->get_logger();

    bless $self, $class;
    return $self;
}


sub analyze {
	my ($self, @modules) = @_;
	croak "No modules provided for analysis" unless @modules;

	my @results;
	for my $module (@modules) {
		print "Analyzing $module...\n" if $self->{verbose};

		my $test_data	= $self->_fetch_testers_data($module);
		my $release_data = $self->_fetch_release_data($module);

		my $unsupported = $self->_evaluate_support($module, $test_data, $release_data);
		push @results, $unsupported if $unsupported;
	}

	return \@results;
}

sub output_results {
	my ($self, $results, $format) = @_;
	$format ||= 'text'; # Default to plain text

	if ($format eq 'json') {
		return encode_json($results);
	} elsif ($format eq 'html') {
		return $self->_generate_html_report($results);
	} else {
		return $self->_generate_text_report($results);
	}
}

sub _generate_text_report {
	my ($self, $results) = @_;
	my $report = "";

	for my $module (@$results) {
		$report .= "Module: $module->{module}\n";
		$report .= "Failure Rate: $module->{failure_rate}\n";
		$report .= "Last Update: $module->{last_update}\n";
		$report .= "\n";
	}

	return $report;
}

sub _generate_html_report {
	my ($self, $results) = @_;
	my $html = "<html><body><h1>Unsupported Modules Report</h1><ul>";

	for my $module (@$results) {
		$html .= "<li><strong>$module->{module}</strong>:<br>";
		$html .= "Failure Rate: $module->{failure_rate}<br>";
		$html .= "Last Update: $module->{last_update}<br></li>";
	}

	$html .= "</ul></body></html>";
	return $html;
}


sub _fetch_testers_data {
	my ($self, $module) = @_;
	my $url = "$self->{cpan_testers}/summary/$module";
	return $self->_fetch_data($url);
}

sub _fetch_release_data {
	my ($self, $module) = @_;
	my $url = "$self->{api_url}/release/_search?q=distribution:$module&size=1&sort=date:desc";
	return $self->_fetch_data($url);
}

sub _fetch_data {
    my ($self, $url) = @_;
    $self->{logger}->debug("Fetching data from $url");

    my $http = HTTP::Tiny->new;
    my $response = $http->get($url);

    if ($response->{success}) {
        $self->{logger}->debug("Data fetched successfully from $url");
        return decode_json($response->{content});
    } else {
        $self->{logger}->error("Failed to fetch data from $url: $response->{status}");
        return;
    }
}

sub _fetch_reverse_dependencies {
	my ($self, $module) = @_;
	my $url = "$self->{api_url}/reverse_dependencies/$module";
	return $self->_fetch_data($url);
}

sub _evaluate_support {
	my ($self, $module, $test_data, $release_data) = @_;

	my $failure_rate = $self->_calculate_failure_rate($test_data);
	my $last_update  = $self->_get_last_release_date($release_data);
	# Reverse Dependencies: Modules with many reverse dependencies have higher priority for support.
	my $reverse_deps = $self->_fetch_reverse_dependencies($module);

	if ($failure_rate > 0.5 || !$last_update || $last_update lt '2022-01-01') {
		return {
			module	   => $module,
			failure_rate => $failure_rate,
			last_update  => $last_update || 'Unknown',
			reverse_deps => $reverse_deps->{total} || 0,
		};
	}

	return;
}

sub _calculate_failure_rate {
	my ($self, $test_data) = @_;
	return 0 unless $test_data && $test_data->{results};

	my $total_tests = $test_data->{results}{total};
	my $failures	= $test_data->{results}{fail};

	return $total_tests ? $failures / $total_tests : 1;
}

sub _get_last_release_date {
	my ($self, $release_data) = @_;
	return unless $release_data && $release_data->{hits}{hits}[0];

	return $release_data->{hits}{hits}[0]{_source}{date};
}

1;

__END__

=head1 NAME

CPAN::UnsupportedFinder - Identify unsupported or poorly maintained CPAN modules.

=head1 SYNOPSIS

  use CPAN::UnsupportedFinder;

  my $finder = CPAN::UnsupportedFinder->new(verbose => 1);
  my $results = $finder->analyze('Some::Module', 'Another::Module');

  for my $module (@$results) {
	  print "Module: $module->{module}\n";
	  print "Failure Rate: $module->{failure_rate}\n";
	  print "Last Update: $module->{last_update}\n";
  }

=head1 DESCRIPTION

CPAN::UnsupportedFinder analyzes CPAN modules for test results and maintenance status, flagging unsupported or poorly maintained distributions.

=head1 METHODS

=head2 new

Creates a new instance. Accepts the following arguments:

=over 4

=item verbose

Enable verbose output.

=back

=head2 analyze(@modules)

Analyzes the provided modules. Returns an array reference of unsupported modules.

=head1 AUTHOR

Your Name <your.email@example.com>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.
