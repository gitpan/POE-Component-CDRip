#
#	CD ripping POE component
#	Copyright (c) Erick Calder, 2002.
#	All rights reserved.
#

package POE::Component::CDRip;

use warnings;
use strict;
use Carp;

use POE		qw(Wheel::Run Filter::Line Driver::SysRW);
use vars	qw($VERSION);

$VERSION = (qw($Revision: 1.3 $))[1];

my %stat = (
	':-)' => 'Normal operation, low/no jitter',
	':-|' => 'Normal operation, considerable jitter',
	':-/' => 'Read drift',
	':-P' => 'Unreported loss of streaming in atomic read operation',
	'8-|' => 'Finding read problems at same point during reread; hard to correct',
	':-0' => 'SCSI/ATAPI transport error',
	':-(' => 'Scratch detected',
	';-(' => 'Gave up trying to perform a correction',
	'8-X' => 'Aborted (as per -X) due to a scratch/skip',
	':^D' => 'Finished extracting',
	);

sub new {
	my $class = shift;
	my $opts = shift;

	my $self = bless({}, $class);

	$self->{dev} = "/dev/cdrom";
	$self->{alias} = "console";

	my %opts = !defined($opts) ? () : ref($opts) ? %$opts : ($opts, @_);
	%$self = (%$self, %opts);

	return $self;
	}

sub rip {
	my $self = shift ;
	my ($n, $fn) = @_;

	POE::Session->create(
		inline_states => {
			_start		=> \&_start,
			_stop		=> \&_stop,
			got_output	=> \&got_output,
			got_error	=> \&got_error,
			got_done	=> \&got_done
			},
		args => [$self, $n, $fn]
		);
	}

sub _start {
	my ($heap, $self, $n, $fn) = @_[HEAP, ARG0 .. ARG2];

	$heap->{self} = $self;

	my @cmd = ("cdparanoia", "-d", $self->{dev}, $n, $fn);
	$heap->{child} = POE::Wheel::Run->new(
		Program		=> \@cmd,
		StdioFilter	=> POE::Filter::Line->new(),	# Child speaks in lines
		Conduit		=> "pty",
		StdoutEvent	=> "got_output", 				# Child wrote to STDOUT
		CloseEvent	=> "got_done",
		);
	}

sub _stop {
	kill 9, $_[HEAP]->{child}->PID;
	}

sub got_output {
	my ($kernel, $heap) = @_[KERNEL, HEAP];
	local $_ = $_[ARG0];

	$heap->{from} = $1	if /from sector\s+(\d+)/;
	$heap->{to} = $1	if /to sector\s+(\d+)/;

	if (/PROGRESS/) {
		my $blk = substr($_, 50, 6); $blk =~ s/\.+/$heap->{from}/;
		my $st = substr($_, 65, 3);	# smiley
		my $stmsg = $stat{$st};
		my $p = ($blk - $heap->{from}) / ($heap->{to} - $heap->{from});
		$p = int(100 * $p);
		$kernel->post($heap->{self}{alias}
			, status => [$blk, $p, $st, $stmsg]
			);
		}
	}

sub got_error {
	$_[KERNEL]->post($_[HEAP]->{alias}, error => $_[ARG0]);
	}

sub got_done {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $kernel->post($heap->{self}{alias}, "done");
    delete $heap->{child};
	}

1;

__END__

=head1 NAME

POE::Component::CDRip - POE Component for running cdparanoia, a CD ripper.

=head1 SYNOPSIS

use POE qw(Component::CDRip);

$cdp = POE::Component::CDRip->new(alias => $alias);
$cdp->rip(3, "/tmp/03.rip");

$poe_kernel->run();

=head1 DESCRIPTION

PoCo::CDRip's C<new()> method takes the following parameters:

=over 4

=item alias

	alias => $alias

C<alias> is the name of a session to which the callbacks below will be
posted.  This defaults to B<console>.

=item dev

	dev => "/dev/cdrom"

Indicates the device to rip from.  If left unspecified, defaults to the value shown above.

=back

=head2 Methods

=item rip <track-number>, <file-name>

    e.g. $cdp->rip(3, "/tmp/tst.rip");

Rips the given track number into the given file name.  Both parameters are required.

=head2 Callbacks

As noted above, all callbacks are either posted to the session alias 
given to C<new()>.

=item status

Fired during processing.  ARG0 is the block number being processed whilst ARG1 represents the percentage of completion expressed as a whole number between 0 and 100.

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 DATE

$Date: 2002/09/10 09:11:20 $

=head1 VERSION

$Revision: 1.3 $

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2002 Erick Calder. This product is distributed under the MIT License. A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.opensource.org/licenses/mit-license.html> to obtain a copy of this license.
=cut
