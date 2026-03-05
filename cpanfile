# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.008';

requires 'Carp';
requires 'ExtUtils::MakeMaker', '6.64';
requires 'HTTP::Tiny';
requires 'JSON::MaybeXS';
requires 'Log::Log4perl';
requires 'Object::Configure';
requires 'Params::Get';
requires 'Return::Set';
requires 'Scalar::Util';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};
on 'test' => sub {
	requires 'Test::Compile';
	requires 'Test::DescribeMe';
	requires 'Test::HTML::Lint';
	requires 'Test::JSON';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::RequiresInternet';
	requires 'Test::Warnings';
};
on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
