#12/17/10 Steve: Added this file to act as a pin configuration choice dialog for users
#TODO: Fix GUI and add the image to the canvas depending on which config is chosen
#12/21/2010 Steve: Fixed GUI and added a basic image to canvas
#5/9/2011 STEVE: WINDOW CORRECTLY REMEMBERS USER CHOICES
#                             FUNCTIONALITY IS COMPLETE
#TODO: MAY ADD MORE THAN 2 CONFIGS

package Scribbler::SetupTile;
use strict;
use Carp qw/cluck confess/;
use Scribbler;
use Scribbler::Constants;
use Scribbler::AtomBlock;
use base qw/Scribbler::Tile/;

#default should be the current pinconfig
my @Icons = qw/setup_1 setup_2 setup_3/;
my %Calls = ();
my $Index = 0;
my ($Self, $Icon, $EditWindow, %Btn, $CanSetup, $Default);

sub new {
         my $invocant = shift;
         my $class = ref($invocant) || $invocant;
         my $parent = shift;
         my $self = Scribbler::Tile::new($class, $parent, @_);
         my $pinc = $self->scribbler->getPinConfiguration;
         $Default = 'setup_' . $pinc if $pinc != 0;
         $Default = 'setup_1' if $pinc == 0;
        # print "Default is: ", $Default, "\n";
         $self->action(icon => $Default);\

         return $self
}

sub emitCode {
        my $self = shift;
        $self->action('icon') =~ m/([^_]+)/;
        my $sensor = $1;
        if ($Calls{$sensor}) {
                $self->worksheet->emitCall($Calls{$sensor});
                $self->subroutine->observed($sensor => 1);
                $self->scribbler->random(0) if $sensor eq 'coin';
        }
}

sub createImage {
        my $self = shift;
        $self->configure(@_) if @_;
        my $icon = $self->action('icon');
        $self->SUPER::createImage(
                tile => 'action',
                icon => ['setup', .6 * $XC, $YC],
                $icon ? (icon => [$icon, 1.4 * $XC, $YC]) : (),
                ghost => 'GREEN'
        )
}

sub icon {
        return 'setup'
}

sub editor {
        $Self = shift;
        $Icon = $Self->action('icon') || $Default;
        $EditWindow = $Self->_createEditWindow() unless $EditWindow;
        $Index = (grep {$Icon eq $Icons[$_]} (0 .. @Icons - 1))[0] || 0;
        $Self->_updateWindow();

        #print "Index is ".$Index."\n";
        my $onDiagram = 'd'.($Index+1);
        $Self->_killDiagrams();
        $CanSetup -> itemconfigure($onDiagram, -state => 'normal');
        $Self->_updateWindow();

        $Self->scribbler->incrementConfigurationCount;
       # print "incremented\n";
        return $EditWindow
}

sub _createEditWindow {
        my $self = shift;
        my $scribbler = $self->scribbler;
        my $mw = $scribbler->mainwindow->Toplevel(-title => $scribbler->translate('Set the Configuration'), -background => 'BLACK');
        $mw->withdraw;
        $scribbler->windowIcon($mw, 'grinder');
        my $frame1 = $mw->Frame(-background => $BG)->pack(-side => 'top', -expand => 1, -fill => 'x');
        my $frame2 = $frame1->Frame(-background => $BG)->pack(-side => 'left', -expand => 1, -fill => 'y');
        my $frame3 = $mw->Frame(-background => $BG)->pack(-side => 'bottom', -padx => 2, -pady => 2, -expand => 1, -fill => 'x');
        foreach ($Default) {
                $Btn{$_} = $frame3->ToggleButton(
                        -width => $BTN_SZ,
                        -height => $BTN_SZ,
                        -ontrigger => 'release',
                        -latching => 0,
                        -onrelief => 'flat',
                        -offrelief => 'flat',
                        -pressrelief => 'flat',
                        -onbackground => $BG,
                        -offbackground => $BG,
                        -borderwidth => 0,
                        $_ eq $Default ? (
                                -pressimage => $scribbler->button("multi_$_" . '_press'),
                                -offimage => $scribbler->button("multi_$_" . '_release')
                        ) : (
                                -pressimage => $scribbler->button($_ . '_press'),
                                -offimage => $scribbler->button($_ . '_release'),
                        ),
                        -command => [\&_evtClickButton, $_]
                )->pack(-side => 'left', -anchor => 'w', -pady => 0, -padx => 0);
        }
        foreach (qw/no okay/) {
                $Btn{$_} = $frame3->ToggleButton(
                        -width => $BTN_SZ,
                        -height => $BTN_SZ,
                        -ontrigger => 'release',
                        -latching => 0,
                        -onrelief => 'flat',
                        -offrelief => 'flat',
                        -pressrelief => 'flat',
                        -onbackground => $BG,
                        -offbackground => $BG,
                        -borderwidth => 0,
                        $_ eq $Default ? (
                                -pressimage => $scribbler->button("multi_$_" . '_press'),
                                -offimage => $scribbler->button("multi_$_" . '_release')
                        ) : (
                                -pressimage => $scribbler->button($_ . '_press'),
                                -offimage => $scribbler->button($_ . '_release'),
                        ),
                        -command => [\&_evtClickButton, $_]
                )->pack(-side => 'right', -pady => 0, -padx => 0)
        }
        $CanSetup = $frame1->Canvas(
                    -height => 450,
                    -width => 430,
                    -background => 'LIGHTBLUE',
        )->pack(-side => 'right', -expand => 1, -fill => 'y');
        #Diagram 1 image
        $CanSetup->createImage(
                  225, 225,
                  -image => $scribbler->icon('diagram_one'),
                  -tags => ['diagram', 'd1']
        );
        #Diagram 2 image
        $CanSetup->createImage(
                 225, 225,
                 -image => $scribbler->icon('diagram_two'),
                 -tags => ['diagram', 'd2'],
                 -state => 'hidden'
        );
         #Diagram 3 image
        $CanSetup->createImage(
                 225, 225,
                 -image => $scribbler->icon('diagram_three'),
                 -tags => ['diagram', 'd3'],
                 -state => 'hidden'
        );
     #    #Diagram 4 image
     #   $CanSetup->createImage(
     #            225, 225,
     #            -image => $scribbler->icon('diagram_four'),
     #            -tags => ['diagram', 'd4'],
     #            -state => 'hidden'
     #   );
     #    #Diagram 5 image
     #   $CanSetup->createImage(
     #            225, 225,
     #            -image => $scribbler->icon('diagram_five'),
     #            -tags => ['diagram', 'd5'],
     #            -state => 'hidden'
     #   );
     $Self->_killDiagrams();
                     my $onDiagram = 'd'.($Index+1);
          $CanSetup -> itemconfigure($onDiagram, -state => 'normal');
        $scribbler->tooltip($Btn{$Default}, 'Select the computation to perform');
        return $mw
}

sub _evtClickButton {
        my $btn = shift;
        my $okay = $btn eq 'okay';
        if ($okay || $btn eq 'no')
        {
                if ($okay)
                {
                     $Self->action('icon', $Icon);
                     $Self->scribbler->setPinConfiguration($Index+1);
                }
                if ($btn eq 'no')
                {
        #                 $Index = ($Index + 1) % @Icons;
        #                 print "Index at no click is ".$Index."\n";
        #                         $Self->scribbler->setPinConfiguration($Index);
        #                         $Self->_killDiagrams();
        #                         my $onDiagram = 'd'.$Index;
        #                        $CanSetup -> itemconfigure($onDiagram, -state => 'normal');
                }
                $Self->{'done'} = $btn
        #change setup button clicked
        } elsif ($btn eq $Default) {
                $Index = ($Index + 1) % @Icons;
                $Icon = $Icons[$Index];
                $Self->_killDiagrams();
                my $onDiagram = 'd'.($Index+1);
                $CanSetup -> itemconfigure($onDiagram, -state => 'normal');
                $Self->_updateWindow();
        }
}

sub _killDiagrams {
    $CanSetup -> itemconfigure('diagram', -state => 'hidden');
}

sub _updateWindow {
        my $self = shift;
        my $scribbler = $self->scribbler;
       #print "Icon is ", $scribbler->button("multi_$Icon\_press"), "\n";
        $Btn{$Default}->pressimage($scribbler->button("multi_$Icon\_press"));
        $Btn{$Default}->offimage($scribbler->button("multi_$Icon\_release"))
}

sub try (&$) {
   my($try, $catch) = @_;
   eval { $try };
   if ($@) {
      local $_ = $@;
      &$catch;
   }
}

sub catch (&) { $_[0] }


1;