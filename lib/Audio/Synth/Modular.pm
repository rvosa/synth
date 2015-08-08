package Audio::Synth::Modular;
package Audio::Synth::Modular::Module;
use Moose;
my $id_counter = 1;

has 'buffer' => ( is => 'rw', isa => 'PDL' );
has 'id'     => ( is => 'ro', isa => 'Num' );
has 'size'   => ( is => 'rw', isa => 'Num', default => 44_10 );

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

sub to {
	my ( $self, $input, $name ) = @_;
	my $channel = Audio::Synth::Modular::Channel->new(
		'name'  => $name || 'process',
		'input' => $input,
	);
	my $listeners = $self->listeners;
	push @$listeners, $channel;
	$self->listeners($listeners);
	return $input;	
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
has 'shape'     => ( is => 'rw', isa => enum('sine','square','saw','triangle','pulse','rand') );

my %generators = (
	'sine'     => \&gen_oscil,
	'square'   => \&gen_square,
	'saw'      => \&gen_sawtooth,
	'triangle' => \&gen_triangle,
	'pulse'    => \&gen_pulse_train,
	'rand'     => \&gen_rand,
);

sub process {
	my $self = shift;
	my $gen = $generators{ $self->shape };
	my $pdl = $gen->( $self->buffer // $self->size, $self->frequency, $self->phase );
	$self->buffer($pdl);
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
	my $env = PDL::Audio::gen_adsr( 
		$self->size,
		$self->level,
		$self->attack,
		$self->decay,
		$self->sustain,
		$self->release,
	);
	$self->buffer($self->buffer * $env);
}

package Audio::Synth::Modular::Filter;
use Moose;
use PDL::Audio;

extends 'Audio::Synth::Modular::Throughput';

has 'frequency' => ( is => 'rw', isa => 'Num|PDL' );
has 'radius'    => ( is => 'rw', isa => 'Num|PDL' );

sub process {
	my $self = shift;
	my $buf = $self->buffer;
	PDL::Audio::filter_ppolar(
		$buf,
		$self->radius,
		$self->frequency
	);
	$self->buffer($buf);
}

package Audio::Synth::Modular::FileWriter;
use Moose;
use PDL::Audio;

extends 'Audio::Synth::Modular::Input';

has 'path'     => ( is => 'rw', isa => 'Str', default => 'outfile.au' );
has 'filetype' => ( is => 'rw', isa => 'Int', default => PDL::Audio::FILE_AU );
has 'format'   => ( is => 'rw', isa => 'Int', default => FORMAT_16_LINEAR );

sub process {
	my $self = shift;
	my $buf = $self->buffer;	
	PDL::Audio::waudio(
		PDL::Audio::scale2short($buf),
		'path'     => $self->path,
		'filetype' => $self->filetype,
		'format'   => $self->format,
	);
}

1;