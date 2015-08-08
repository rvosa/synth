#!/usr/bin/perl
use lib 'lib';
use PDL::Audio::Pitches;
use Audio::Synth::Modular;

my $osc = Audio::Synth::Modular::Oscillator->new(
	frequency => a2,
	shape     => 'saw',
);
my $env = Audio::Synth::Modular::Envelope->new(
	attack   => 0.01,
	decay    => 0.1,
	sustain  => 0.3,
	release  => 1.0,
	level    => 0.2,
);
my $flt = Audio::Synth::Modular::Filter->new(
	frequency => a2,
	radius    => 0.1,
);
my $out = Audio::Synth::Modular::FileWriter->new( path => 'deleteme.au' );
$osc->to($env)->to($flt)->to($out);
$osc->process;
$osc->notify;