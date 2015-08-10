#!/usr/bin/perl
use lib 'lib';
use PDL::Audio::Pitches;
use Audio::Synth::Modular;

# create a sine wave oscillator at 440Hz
my $osc = Audio::Synth::Modular::Oscillator->new(
	frequency => a4,
	shape     => 'saw',
	size      => 44_10,
);

# create an ADSR envelope
my $amp_env = Audio::Synth::Modular::Envelope->new(
	attack   => 0.01,
	decay    => 0.1,
	sustain  => 0.3,
	release  => 1.0,
	level    => 0.2,
	size     => 44_10,
);

# create a filter whose frequency is modulated by the ADSR
my $flt = Audio::Synth::Modular::Filter->new(
	radius => 0.95,
	size   => 44_10,	
);

# create a file writer
my $out = Audio::Synth::Modular::FileWriter->new;

# chain the signal
$osc->to($amp_env)->to($flt)->to($out);

for my $i ( 1 .. 10 ) {
	$flt->frequency( a4 * $i );
	$out->path( "deleteme${i}.au" );
	$osc->process;
	$osc->notify;
}