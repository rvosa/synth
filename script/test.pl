#!/usr/bin/perl
use lib 'lib';
use PDL::Audio::Pitches;
use Audio::Synth::Modular;

my $osc = Audio::Synth::Modular::Oscillator->new(
	frequency => a4,
	shape     => 'square',
);
my $env = Audio::Synth::Modular::Envelope->new(
	attack   => 0.1,
	decay    => 0.1,
	sustain  => 1.0,
	release  => 0.5,
	level    => 0.5,
	duration => 0.5,
);
my $flt = Audio::Synth::Modular::Filter->new(
	frequency => a4,
	level     => 0.5,
);
$osc->register($env);
$env->register($flt);