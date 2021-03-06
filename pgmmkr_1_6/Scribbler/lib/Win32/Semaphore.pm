#---------------------------------------------------------------------
package Win32::Semaphore;
#
# Copyright 1998-2008 Christopher J. Madsen
#
# Created: 3 Feb 1998 from the ActiveWare version
#   (c) 1995 Microsoft Corporation. All rights reserved.
#       Developed by ActiveWare Internet Corp., http://www.ActiveState.com
#
#   Other modifications (c) 1997 by Gurusamy Sarathy <gsar@cpan.org>
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# $Id: Semaphore.pm 284 2008-04-17 02:17:41Z cmadsn $
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Use Win32 semaphore objects for synchronization
#---------------------------------------------------------------------

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);

use Win32::IPC 1.00 '/./';      # Import everything

BEGIN
{
  $VERSION = '1.07';

  @ISA = qw(Win32::IPC);        # Win32::IPC isa Exporter
  @EXPORT_OK = qw(
    wait_any wait_all INFINITE
  );

  require XSLoader;
  XSLoader::load('Win32::Semaphore', $VERSION);
} # end BEGIN bootstrap

# Deprecated ActiveWare functions:
sub Create  { $_[0] = Win32::Semaphore->new(@_[1..3]) }
sub Open  { $_[0] = Win32::Semaphore->open($_[1]) }
*Release = \&release;           # Alias release to Release

1;
__END__

=head1 NAME

Win32::Semaphore - Use Win32 semaphore objects from Perl

=head1 VERSION

This document describes version 1.07 of Win32::Semaphore, released April 16, 2008 as part of Win32-IPC version 1.07.


=head1 SYNOPSIS
	require Win32::Semaphore;

	$sem = Win32::Semaphore->new($initial,$maximum,$name);
	$sem->wait;

=head1 DESCRIPTION

This module allows access to Win32 semaphore objects.  The C<wait>
method and C<wait_all> & C<wait_any> functions are inherited from the
L<Win32::IPC> module.

=head2 Methods

=over 4

=item $semaphore = Win32::Semaphore->new($initial, $maximum, [$name])

Constructor for a new semaphore object.  C<$initial> is the initial
count, and C<$maximum> is the maximum count for the semaphore.  If
C<$name> is omitted or C<undef>, creates an unnamed semaphore object.

If C<$name> signifies an existing semaphore object, then C<$initial>
and C<$maximum> are ignored and the object is opened.  If this
happens, C<$^E> will be set to 183 (ERROR_ALREADY_EXISTS).

=item $semaphore = Win32::Semaphore->open($name)

Constructor for opening an existing semaphore object.

=item $semaphore->release([$increment, [$previous]])

Increment the count of C<$semaphore> by C<$increment> (default 1).
If C<$increment> plus the semaphore's current count is more than its
maximum count, the count is not changed.  Returns true if the
increment is successful, or zero if it fails (additional error
information can be found in C<$^E>).

The semaphore's count (before incrementing) is stored in the second
argument (if any).

It is not necessary to wait on a semaphore before calling C<release>,
but you'd better know what you're doing.

=item $semaphore->wait([$timeout])

Wait for C<$semaphore>'s count to be nonzero, then decrement it by 1.
See L<Win32::IPC>.

=back

=head2 Deprecated Functions and Methods

B<Win32::Semaphore> still supports the ActiveWare syntax, but its use
is deprecated.

=over 4

=item Win32::Semaphore::Create($SemObject,$Initial,$Max,$Name)

Use C<$SemObject = Win32::Semaphore-E<gt>new($Initial,$Max,$Name)> instead.

=item Win32::Semaphore::Open($SemObject, $Name)

Use C<$SemObject = Win32::Semaphore-E<gt>open($Name)> instead.

=item $SemObj->Release($Count,$LastVal)

Use C<$SemObj-E<gt>release($Count,$LastVal)> instead.

=back

=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

Win32::Semaphore requires no configuration files or environment variables.

It runs under 32-bit or 64-bit Microsoft Windows, either natively or
under Cygwin.


=head1 DEPENDENCIES

L<Win32::IPC>


=head1 INCOMPATIBILITIES

Prior to version 1.06, Win32::Semaphore treated C<undef> values
differently.  In version 1.06 and later, passing C<undef> as the value
of an optional parameter is the same as omitting that parameter.  In
previous versions, C<undef> was interpreted as either the empty string
or 0 (along with a warning about "Use of uninitialized value...").


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 AUTHOR

Christopher J. Madsen E<lt>F<perl AT cjmweb.net>E<gt>

Please report any bugs or feature requests to
S<< C<< <bug-Win32-IPC AT rt.cpan.org> >> >>,
or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Win32-IPC>

Loosely based on the original module by ActiveWare Internet Corp.,
L<http://www.ActiveState.com>


=head1 LICENSE AND COPYRIGHT

Copyright 1998-2008 Christopher J. Madsen

Created: 3 Feb 1998 from the ActiveWare version
  (c) 1995 Microsoft Corporation. All rights reserved.
      Developed by ActiveWare Internet Corp., http://www.ActiveState.com

  Other modifications (c) 1997 by Gurusamy Sarathy <gsar@cpan.org>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
