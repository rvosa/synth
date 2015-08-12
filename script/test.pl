#!/usr/bin/perl
use lib 'lib';
use PDL::Audio::Pitches;
use Audio::Synth::Modular;

# one second
my $size = 44_100;

# create an LFO scaled between a3 and a4 in a 1-second cycle
my $pitch_osc = Audio::Synth::Modular::Oscillator->new(
	frequency => 1 / $size,
	shape     => 'sine',
	size      => $size,
	min       => a3,
	max       => a4,
);

# create a sine wave oscillator at whose pitch is modulated
my $osc = Audio::Synth::Modular::Oscillator->new(
	frequency => $pitch_osc,
	shape     => 'saw',
	size      => $size,
);

# create an ADSR envelope
my $amp_env = Audio::Synth::Modular::Envelope->new(
	attack   => 0.01,
	decay    => 0.1,
	sustain  => 0.3,
	release  => 1.0,
	level    => 0.2,
	size     => $size,
);

# create a filter whose frequency is modulated by the ADSR
my $flt = Audio::Synth::Modular::Filter->new(
	radius => 0.95,
	size   => $size,	
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