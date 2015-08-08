package Audio::Synth::Modular;
package Audio::Synth::Modular::Module;
use Moose;
my $id_counter = 1;

has 'buffer' => ( is => 'rw', isa => 'PDL' );
has 'id'     => ( is => 'ro', isa => 'Num' );
has 'size'   => ( is => 'rw', isa => 'Num', default => 44_100 );

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;
	my %args;	
	if ( @_ == 1 && ref $_[0] ) {
		%args = %{ $_[0] };
	}
	else {
		%args = @_;
	}
	$args{'id'} = $id_counter++;
	return $class->$orig(%args);
};

package Audio::Synth::Modular::Input;
use Moose;
extends 'Audio::Synth::Modular::Module';

sub process {
	my $class = shift->blessed;
	die "$class should process() its buffer, but doesn't";
}

package Audio::Synth::Modular::Output;
use Moose;
extends 'Audio::Synth::Modular::Module';

has 'listeners' => ( is => 'rw', isa => 'ArrayRef[Audio::Synth::Modular::Channel]' );

sub register {
	my ( $self, $input, $name ) = @_;
	my $channel = Audio::Synth::Modular::Channel->new(
		'name'  => $name || 'process',
		'input' => $input,
	);
	my $listeners = $self->listeners;
	push @$listeners, $channel;
	$self->listeners($listeners);	
}

sub notify {
	my $self = shift;
	my %inputs;
	my $buffer    = $self->buffer;
	my $listeners = $self->listeners;
	for my $channel ( @$listeners ) {
		my $name = $channel->name;
		my $in   = $channel->input;
		my $id   = $in->id;
		$name eq 'process' ? $in->buffer($buffer) : $in->$name($buffer);
		$inputs{$id} = $in;
	}
	for my $in ( values %inputs ) {
		$in->process;
		if ( $in->can('notify') ) {
			$in->notify;
		}
	}
}

package Audio::Synth::Modular::Throughput;
use Moose;

extends 'Audio::Synth::Modular::Input', 'Audio::Synth::Modular::Output';

package Audio::Synth::Modular::Channel;
use Moose;

has 'input' => ( is => 'rw', isa => 'Audio::Synth::Modular::Input' );
has 'name'  => ( is => 'rw', isa => 'Str' );

package Audio::Synth::Modular::Oscillator;
use Moose;
use Moose::Util::TypeConstraints;
use PDL::Audio;

extends 'Audio::Synth::Modular::Throughput';

has 'frequency' => ( is => 'rw', isa => 'Num|PDL' );
has 'phase'     => ( is => 'rw', isa => 'Num|PDL', default => 0 );
has 'shape'     => ( is => 'rw', isa => enum(qw[sine square saw triangle pulse rand]) );

my %generators = (
	'sine'     => \&gen_oscil,
	'square'   => \&gen_square,
	'saw'      => \&gen_sawtooth,
	'triangle' => \&gen_triangle,
	'pulse'    => \&gen_pulse_train,
	'gen_rand' => \&gen_rand,
);

sub process {
	my $self = shift;
	my $gen = $generators{ $self->shape };
	$self->buffer($gen->( $self->buffer // $self->size, $self->frequency, $self->phase ));
}

package Audio::Synth::Modular::Envelope;
use Moose;
use PDL::Audio;

extends 'Audio::Synth::Modular::Throughput';

has 'attack'   => ( is => 'rw', isa => 'Num|PDL' );
has 'decay'    => ( is => 'rw', isa => 'Num|PDL' );
has 'sustain'  => ( is => 'rw', isa => 'Num|PDL' );
has 'release'  => ( is => 'rw', isa => 'Num|PDL' );
has 'level'    => ( is => 'rw', isa => 'Num|PDL' );

sub process {
	my $self = shift;
	my $buf = $self->buffer // $self->size;
	my $pdl = PDL::Audio::gen_adsr( 
		$buf,
		$self->level,
		$self->attack,
		$self->decay,
		$self->sustain,
		$self->release,
	);
	$self->buffer($buf);
}

package Audio::Synth::Modular::Filter;
use Moose;

extends 'Audio::Synth::Modular::Throughput';

has 'frequency' => ( is => 'rw', isa => 'Num|PDL' );
has 'level'     => ( is => 'rw', isa => 'Num|PDL' );

1;