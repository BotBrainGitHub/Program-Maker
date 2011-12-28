package Scribbler::StandardTile;
use strict;
use Carp qw/cluck confess/;
use Scribbler;
use Scribbler::Constants;
use Scribbler::AtomBlock;
use base qw/Scribbler::ActionTile/;

my $Default = 1;
my ($Self, $EditWindow, $CanPause, %BtnPause, $Index, $Position2Index, @Times, @TimeList, $Time, @CanCall, $CallIndex, $Icon, $IIndex, $TempHolder, $newIndex);
my @Icons = qw/servo9 servo10 servo11 servo12 servo13/;
my $DefaultIcon = 'servo9';
sub new {
         my $invocant = shift;
         my $class = ref($invocant) || $invocant;
         my $parent = shift;
         my $self = Scribbler::ActionTile::new($class, $parent, @_);
         $self->action(icon => 'servo9', text => "1 to 1 S:1", last => '0', time => '1', pos2 => '1', newText => '1');
         return $self
}
foreach (0 .. 100)
{
 push @Times, sprintf('%d', ($_));
}
for(my $count = 1; $count <= 20; $count = $count + 1)
{
 push @TimeList, sprintf('%.0f', $count);
}
sub emitCode {
        my $self = shift;
        my $position = $self->action('newText');
                my $temp = $self->action('last');
                my $from = $self->action('pos2');
                #my $time = $self->action('time') * 1000;
                my $time = $self->action('time');
                #print $position, "\t", $from, "\t", $time, "\n";
        $self->worksheet->appendCode("LeftMotor = $position");
                    if(($position - $from) > 0)
                        {
                                #my $delay = $time / (((9*$position+300) - (9*$from+300)) / 8);
                                #$delay = 5;
                                my $delay = $time;
                                $self->worksheet->appendCode("MoveTime = $delay");
                                $self->worksheet->appendCode("RightMotor = $from");
                        }
                    else
                        {
                                #my $delay = $time / (((9*$from+300) - (9*$position+300)) / 8);
                                #$delay = sprintf "%.0f", $delay;
                                my $delay = $time;
                                $self->worksheet->appendCode("MoveTime = $delay");
                                $self->worksheet->appendCode("RightMotor = $from");
                        }
        if($temp == 0)
            {
                if(($position - $from) > 0)
                        {
                                $self->worksheet->emitCall('Servo9SetHigh');
                        }
                        else
                        {
                                $self->worksheet->emitCall('Servo9SetLow');
                        }
        }
        elsif($temp == 1)
        {
            if(($position - $from) > 0)
                        {
                                $self->worksheet->emitCall('Servo10SetHigh');
                        }
                        else
                        {
                                $self->worksheet->emitCall('Servo10SetLow');
                        }
        }
        elsif($temp == 2)
        {
            if(($position - $from) > 0)
                        {
                                $self->worksheet->emitCall('Servo11SetHigh');
                        }
                        else
                        {
                                $self->worksheet->emitCall('Servo11SetLow');
                        }
        }
        elsif($temp == 3)
        {
            if(($position - $from) > 0)
                        {
                                $self->worksheet->emitCall('Servo12SetHigh');
                        }
                        else
                        {
                                $self->worksheet->emitCall('Servo12SetLow');
                        }
        }
        elsif($temp == 4)
        {
            if(($position - $from) > 0)
                        {
                                $self->worksheet->emitCall('Servo13SetHigh');
                        }
                        else
                        {
                                $self->worksheet->emitCall('Servo13SetLow');
                        }
        }
}

sub editor {
        $Self = shift;
        my $time = $Self->action('newText') || $Default;
        $Icon = $Self->action('icon') || $DefaultIcon;
        $Index = (grep {$time eq $Times[$_]} (0 .. @Times))[0];
        $IIndex = $Self->action('last');
        $newIndex = $Self->action('time') || 1;
        $time = $Self->action('pos2') || 1;
        $Position2Index = (grep {$time eq $Times[$_]} (0 .. @Times))[0];
        $EditWindow = $Self->_createEditWindow() unless $EditWindow;

                $Self->_evtChangeSlider();
        $Icon = $Icons[$IIndex];
               # print "IIndex is ", $IIndex, "\n";

        _updateCall();
        $Self->_updateWindow;
        return $EditWindow
}

sub _createEditWindow {
        my $self = shift;
        my $scribbler = $self->scribbler;
        my $mw = $scribbler->mainwindow->Toplevel(-title => ucfirst($scribbler->translate('Standard Servos')));
        $mw->withdraw;
        $scribbler->windowIcon($mw, 'pause_light');
        my $frame1 = $mw->Frame(-background => $BG)->pack(-side => 'top');

        my $scaTime = $frame1->Scale(
                -background => '#556666',
                -activebackground => 'BLACK',
                -troughcolor => 'GREEN',
                -command => \&_evtChangeSlider,
                -to => 1,
                -from => 100,
                -relief => 'sunken',
                -width => $SLIDER_WIDTH,
                -sliderlength => $SLIDER_LENGTH,
                -showvalue => 0,
                -variable => \$Index
        )->pack(-side => 'right', -padx => 2, -pady => 2, -expand => 1, -fill => 'y');
        $scribbler->tooltip($scaTime, 'To position');

        my $scaTime2 = $frame1->Scale(
                -background => '#556666',
                -activebackground => 'BLACK',
                -troughcolor => 'RED',
                -command => \&_evtChangeSlider,
                -to => 1,
                -from => 100,
                -relief => 'sunken',
                -width => $SLIDER_WIDTH,
                -sliderlength => $SLIDER_LENGTH,
                -showvalue => 0,
                -variable => \$Position2Index
        )->pack(-side => 'left', -padx => 2, -pady => 2, -expand => 2, -fill => 'x');
        $scribbler->tooltip($scaTime2, 'From position');
        my $frame2 = $mw->Frame(-background => $BG)->pack(-padx => 2, -pady => 2, -side => 'bottom', -expand => 1, -fill => 'x');

        foreach (qw/no okay/) {
                $BtnPause{$_} = $frame2->ToggleButton(
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
                        $_ eq 'call_' ? (
                                -pressimage => $scribbler->button("multi_$_" . '_push'),
                                -offimage => $scribbler->button("multi_$_" . '_off'),
                        ) : (
                                -pressimage => $scribbler->button($_ . '_press'),
                                -offimage => $scribbler->button($_ . '_release'),
                        ),
                        -command => [\&_evtClickButton, $_]
                )->pack(-side => 'right', -anchor => 'e')
        }

        foreach ($DefaultIcon) {
                #print $_, "\n";
                $BtnPause{$_} = $frame2->ToggleButton(
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
                        -pressimage => $scribbler->button("multi_$_" . '_press'),
                        -offimage => $scribbler->button("multi_$_" . '_release'),
                        -command => [\&_evtClickButton, $_]
                )->pack(-side => 'left', -anchor => 'w')
        }

        $frame2->Label(
                -background => $BG,
                -foreground => 'RED',
                -text => 'From:',
                -font => $Self->scribbler->font('tilefont')
        )->pack(-side => 'left', -expand => 1, -fill => 'x');
           $frame2->Label(
                -background => $BG,
                -foreground => 'RED',
                -textvariable => \$Position2Index,
                -font => $Self->scribbler->font('tilefont')
        )->pack(-side => 'left', -expand => 1, -fill => 'x');


         $frame2->Label(
                -background => $BG,
                -foreground => 'GREEN',
                -text => 'To:',
                -font => $Self->scribbler->font('tilefont')
        )->pack(-side => 'left', -expand => 1, -fill => 'x');

        $frame2->Label(
                -background => $BG,
                -foreground => 'GREEN',
                -textvariable => \$Time,
                -font => $Self->scribbler->font('tilefont')
        )->pack(-side => 'left', -expand => 1, -fill => 'x');

        $frame2->Label(
                -background => $BG,
                -foreground => 'YELLOW',
                -text => 'Step size:',
                -font => $Self->scribbler->font('tilefont')
        )->pack(-side => 'left', -expand => 1, -fill => 'x');

        $frame2->Spinbox(
                -readonlybackground => 'BLACK', -foreground => 'YELLOW',
                -selectbackground => 'BLACK', -selectforeground => 'YELLOW',
                -takefocus => 0, -state => 'readonly', -buttonbackground => '#404040',
                -width => 4, -values => [@TimeList],
                -textvariable => \$newIndex, -justify => 'right',
                -font => $scribbler->font('tilefont')
        )->pack(-side => 'right');
        return $mw
}

sub _evtClickButton {
        my $btn = shift;
        if ($btn =~ m/okay|no/) {

                $Self->action(text =>$Position2Index . " to " . $Index . " S:" . $newIndex) if $btn eq 'okay';
                $Self->action(newText => $Index) if $btn eq 'okay';
                                $Self->action(last => $IIndex) if $btn eq 'okay';
                                $Self->action(time => $newIndex) if $btn eq 'okay';
                                $Self->action(pos2 => $Position2Index) if $btn eq 'okay';
                                my $temp = "servo".($IIndex+9);
                                #print "Icon: ", $temp, "\n";
                $Self->action(icon => $temp) if $btn eq 'okay';
                $Self->{'done'} = $btn

        } elsif ($btn eq $DefaultIcon) {
                $IIndex = ($IIndex + 1) % @Icons;
                $Icon = $Icons[$IIndex];
                $Self->_updateCall();
        }
}

sub _updateCall {
        my $scribbler = $Self->scribbler;
        $BtnPause{$DefaultIcon}->pressimage($scribbler->button("multi_$Icon\_press"));
        $BtnPause{$DefaultIcon}->offimage($scribbler->button("multi_$Icon\_release"))
       }

sub _evtChangeSlider {
       $Time = $Times[$Index];
}

sub _updateWindow {
        my $self = shift;
        my $scribbler = $self->scribbler;
      }

1;