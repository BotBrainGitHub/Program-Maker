# 12/05/2010
# Done: touch buttons added (under obstacle), touch condition added, touch function emits properly
# Done: New logic system added to IR and Touch sensors
# 12/09/2010
# Done: Removed the MIN / MAX tiles from light sensors


package Scribbler::ConditionalTile;
use strict;
use utf8;
use Carp qw/cluck confess/;
use Scribbler;
use Scribbler::Constants;
use Scribbler::AtomBlock;
use Tie::IxHash;
use base qw/Scribbler::Tile/;

my @Offsets = ([-15, -6], [2, -5]);

sub new {
         my $invocant = shift;
         my $class = ref($invocant) || $invocant;
         my $parent = shift;
         return Scribbler::Tile::new($class, $parent, @_);
}

sub code {
        my $self = shift;
        return '' unless $self->subclass =~ m/(if_begin|unless_begin|andif|andunless|else_begin)/;
        my $subclass = $1;
        my $returnvalue;
        my $irvalue = $self->_ircondition;
        if($irvalue != -1)
        {
            $returnvalue = 'irFreq = ' . $irvalue . "\n\t";
        }
        if ($subclass eq 'if_begin') {
                $returnvalue = $returnvalue . 'IF (' . $self->_condition
        } elsif ($subclass eq 'unless_begin') {
                $returnvalue = $returnvalue . 'IF (NOT(' . $self->_condition . ')'
        } elsif ($subclass eq 'andif') {
                $returnvalue = $returnvalue . ' AND ' . $self->_condition
        } elsif ($subclass eq 'andunless') {
                $returnvalue = $returnvalue . ' AND NOT(' . $self->_condition . ')'
        }
        if($irvalue != -1)
        {
            $returnvalue = $returnvalue . ") THEN";
        }
        return $returnvalue;
}
sub _ircondition {
 my $self = shift;
 my $condition = $self->action('icon');
 my $value = (($self->action('text') || '0') =~ m/(\d+)/)[0];
 if($condition eq 'obstacle_wr' || $condition eq 'obstacle_rw') {
   return $value-1;
 } else {
   return -1;
 }
}
sub _condition {
        my $self = shift;
        my $condition = $self->action('icon');
        my $value = (($self->action('text') || '0') =~ m/(\d+)/)[0];
        if ($condition =~ m/flag_(.+)/) {
                return "Flag_$1 = 1"
      #New logic system for IR sensor
        } elsif ($condition eq 'obstacle_wr') {
                my $cond = 'LeftObstacle = 1';
                $cond .= " AND ObstacleCount >= $value" if $value;
                return $cond
        } elsif ($condition eq 'obstacle_rw') {
                my $cond = 'RightObstacle = 1';
                $cond .= " AND ObstacleCount >= $value" if $value;
                return $cond
      #Old Logic system for IR Sensor
      #  } elsif ($condition =~ m/obstacle_([wr])([wr])/) {
      #          my $cond = $1 eq 'r' ? 'LeftObstacle = 0' : 'LeftObstacle = 1';
      #          $cond .= ' AND ' . ($2 eq 'r' ? 'RightObstacle = 0' : 'RightObstacle = 1');
      #          $cond .= " AND ObstacleCount >= $value" if $value;
      #          return $cond

      #New logic system for touch sensor
      #left touched
         } elsif ($condition =~ m/touch_wr/) {
               my $cond = 'LeftWhiskerObstacle = 1';
              $cond .= " AND LeftWhiskerObstacleCount >= $value" if $value;
               return $cond
         #right touched
         } elsif ($condition =~ m/touch_rw/) {
               my $cond = 'RightWhiskerObstacle = 1';
               $cond .= " AND RightWhiskerObstacleCount >= $value" if $value;
               return $cond
      # Old logic system
      #  } elsif ($condition =~ m/touch_([wr])([wr])/) {
      #          my $cond = $1 eq 'r' ? 'LeftWhiskerObstacle = 0' : 'LeftWhiskerObstacle = 1';
      #          $cond .= ' AND ' . ($2 eq 'r' ? 'RightWhiskerObstacle = 0' : 'RightWhiskerObstacle = 1');
      #          $cond .= " AND WhiskerObstacleCount >= $value" if $value;
      #          return $cond
        } elsif ($condition =~ m/light_([xld]{3}|min|max|avg)/) {
                my $lights = $1;
                my $cond;
                $value = $value || 1;
                my $value255 = $value + 255;
                if ($lights eq 'lxx') {
                        return "LeftLight >= $value"
                } elsif ($lights eq 'xxl') {
                        return "RightLight >= $value"
                } elsif ($lights eq 'ldd') {
                        return "LeftLight - RightLight + 255 >= $value255"
                } elsif ($lights eq 'ddl') {
                        return "RightLight - LeftLight + 255 >= $value255"
              #Removed 12/09/2010; not needed
              #  } elsif ($lights eq 'min') {
              #          return "LeftLight MAX RightLight >= $value"
              #  } elsif ($lights eq 'max') {
              #          return "LeftLight MIN RightLight >= $value"
                } elsif ($lights eq 'avg') {
                        return "(LeftLight + RightLight) / 2 >= $value"
                }
        } elsif ($condition eq 'coin_heads') {
                my $mask = $self->scribbler->random($value || 1);
                return "CoinFlip & $mask = 0"
        } elsif ($condition eq 'reset') {
                my $parent = $self->parent->parent;
                 if (ref($parent->parent) eq 'Scribbler::Subroutine' && $parent->subroutine->color eq $ROOT_COLOR && $parent->findMe == 1) {
                         $value-- if $value;
                        return "ResetCount = $value"
                } else {
                        return '0'
                }
        } else {
                return '<condition>'
        }
}

sub createImage {
        my $self = shift;
        $self->configure(@_) if @_;
         my $icon = $self->action('icon');
         my $text = $self->action('text');
         $text = '' unless defined $text;
         my $subclass = $self->subclass;
         my $offsets = $Offsets[($subclass =~ m/and/) || 0];
         if ($subclass =~ m/if_begin|unless_begin|andif|andunless/) {
                $self->SUPER::createImage(
                         tile => "cond_$subclass",
                         $icon ? (icon => [$icon, $XC + $offsets->[0], $YC + $offsets->[1]]) : (),
                        $text ne '' ? (text => [$text, $XC - 20, $Y1 - 16]) : (),
                         ghost => 'YELLOW'
                 )
        } else {
                $self->SUPER::createImage(tile => '');
        }
         $self->drawVectors;
}

sub redraw {
        my $self = shift;
        return unless $self->worksheet;
        $self->SUPER::redraw;
        $self->drawVectors;
        return $self->size
}

sub reactivate {
        my $self = shift;
        return 1 unless $self->worksheet;
        my $active = $self->SUPER::reactivate(@_);
        if (my $vectors = $self->image('vectors')) {
                if ($active == 1) {
                        $self->configureLines($vectors, 'raise', -fill => $ACTIVE_LINE_COLOR);
                } else {
                        $self->configureLines($vectors, 'lower', -fill => $INACTIVE_LINE_COLOR);
                }
        }
        return $active
}

sub drawVectors {
        my $self = shift;
        $self->worksheet and my $conditional = $self->enclosing('Scribbler::ConditionalArray') or return;
        my $subclass = $self->subclass;
        my $active = $self->reactivate;
        my $canvas = $self->canvas;
        my ($x, $y) = $self->location;
        my ($x0, $y0) = $conditional->location;
        my $height = ($conditional->size)[1];
        my @widths = map {$_->width} $conditional->children;
        my @heights = map {$_->height} $conditional->children;
        my $color;
        my $index = $self->parent->findMe;
        if (my $vectors = $self->image('vectors')) {
                $color = $canvas->itemcget($vectors->[0], '-fill');
                $canvas->delete(@$vectors)
        } else {
                $color = $INACTIVE_LINE_COLOR
        }
        if ($subclass =~ m/if_begin|unless_begin/) {
                $self->image->{vectors} = [$self->SUPER::drawVectors(
                        [$x + 1 + $TILE_XINDENT, $y + 0.5,
                        $x + $widths[$index] + $TILE_XINDENT, $y + 0.5],
                        -fill => $color
                )]
        } elsif ($subclass eq 'else_begin') {
                        $self->image->{vectors} = [$self->SUPER::drawVectors(
                                [$x + $TILE_XINDENT, $y + 0.5,
                                $x + 0.5, $y + 0.5,
                                $x + 0.5, $y + 1 + $TILE_YINDENT],
                                -fill => $color
                        )]
        } elsif ($subclass =~ m/if_end|else_end/) {
                $self->image->{vectors} = [$self->SUPER::drawVectors(
                        [$x + 0.5, $y + $TILE_YINDENT,
                        $x + 0.5, $self->parent ne $conditional->begin ? (
                                $y0 + $height - 0.5,
                                $x0 + 0.5, $y0 + $height - 0.5,
                                $x0 + 0.5
                        ) : (), $y0 + $height + $TILE_YINDENT],
                        -fill => $color
                )]
        } elsif ($subclass eq 'else_end') {
                $self->image->{vectors} = [$self->SUPER::drawVectors(
                        [$x + 0.5, $y + $TILE_YINDENT,
                        $x + 0.5, $y0 + $height - 0.5,
                        $x0 + 0.5, $y0 + $height - 0.5],
                        -fill => $color
                )]
        }
        $self->configureLines($self->image->{vectors}, 'lower') if $color eq $INACTIVE_LINE_COLOR
}

my ($Self, $EditWindow, $CanCond, $SelfEdit, %BtnCond, %Index, $Button, $Text, $Slider, $SliderValue, %SliderValues, $Sensor);
my $Columns = 2;

tie my %Sensors, 'Tie::IxHash', (
        flag => {
                icons => [map {"flag_$_"} @FLAG_COLORS],
                maxvalue => 0,
                text => sub{''},
                tip => 'Flag up',
                slidertip => '',
        },

        line => {
               # icons => [qw/line_ld line_ll line_dl line_dd/],
                icons => [qw//],
                maxvalue => 8,
                onselect => sub{_evtSelectReps('line')},
                onslider => \&_setReps,
                text => \&_defaultText,
               # tip => 'Line and barcode sensor',
                slidertip => 'Set required consecutive observations.',
        },
        #Icons commented out and bar_f is blank for now
        bar => {
               # icons => [qw/bar_fwd bar_rev bar_both/],
                icons => [qw/blank/],
        },

        obstacle => {
                icons => [qw/obstacle_wr obstacle_rw/],
                maxvalue => 8,
                onselect => sub{_evtSelectReps('obstacle')},
                onslider => \&_setRepsIcons,
                text => \&_defaultText,
                tip => 'Infrared and touch sensors',
                slidertip => 'Set required consecutive observations.',
        },

        touch => {
                icons => [qw/touch_wr touch_rw/],
                maxvalue => 8,
                onselect => sub{_evtSelectReps('obstacle')},
                onslider => \&_setRepsIcons,
                text => \&_defaultText,
                tip => 'Infrared and touch sensors',
                slidertip => 'Set required consecutive observations.',
        },

        #\x{2265} is the unicode value greater than or equal too
        light => {
                icons => [qw/light_lxx light_xxl light_ldd light_ddl light_avg/],
                maxvalue => 255,
                onselect => \&_evtSelectLight,
                onslider => \&_evtSlideLight,
                text => sub{"\x{2265}$SliderValue"},
                tip => 'Light sensors',
                slidertip => 'Set threshold brightness level.',
        },

        coin => {
                icons => [qw/coin_heads/],
                maxvalue => 8,
                onselect => sub{_evtSelectReps('coin_heads')},
                onslider => \&_setReps,
                text => \&_defaultText,
                tip => 'Coin flip came up "heads"',
                slidertip => 'Set required consecutive observations.',
        },

        reset => {
                icons => [qw/reset/],
                maxvalue => 8,
                onselect => sub{_evtSelectReps('coin_heads')},
                onslider => \&_setReps,
                text => sub{"=$SliderValue"},
                tip => 'Reset button was pressed',
                slidertip => 'Set required consecutive observations.',
        }

);
sub _defaultText {
        return $SliderValue > 1 ? "$SliderValue x" : ''
}

tie my %Buttons, 'Tie::IxHash', (
        flag => {sensors => [qw/flag/]},
        obstacle => {sensors => [qw/obstacle touch/]},
        light => {sensors => [qw/light/]},
        coin => {sensors => [qw/coin reset/]}
);

foreach my $btn (keys %Buttons) {
        $Buttons{$btn}->{icons} = [];
        foreach (@{$Buttons{$btn}->{sensors}}) {
                $Sensors{$_}->{button} = $btn;
                push @{$Buttons{$btn}->{icons}}, @{$Sensors{$_}->{icons}}
        }
}

sub editor {
        $Self = shift;
        $EditWindow = $Self->_createEditWindow() unless $EditWindow;
        $SelfEdit->subclass($Self->subclass);
        $SelfEdit->action(%{$Self->action});
        my $icon = $Self->action('icon') || 'flag_green';
        $SelfEdit->action(icon => $icon);
        my $sensor = $Self->sensor($icon);
        my $btn = $Sensors{$sensor}->{button};
        $Button = '';
        $Sensor = '';
        my @icons = @{$Buttons{$btn}->{icons}};
        %Index = map {$_ => 0} keys %Sensors;
        %SliderValues = map {$_ => 0} values %Sensors;
        $SliderValue = $SliderValues{$Sensors{$sensor}} = (($SelfEdit->action('text') || '0') =~ m/(\d+)/)[0] || 0;
        $Index{$btn} = (grep {$icon eq $icons[$_]} (0 .. @icons - 1))[0];
        _redrawButtons(map {[$_ => $Buttons{$_}->{icons}->[$Index{$_}]]} keys %Buttons);
        $BtnCond{$btn}->TurnOff;
        $BtnCond{$btn}->TurnOn;
        $SelfEdit->_updateWindow;
        $CanCond->itemconfigure('light', -state => 'hidden');
        return $EditWindow
}

sub _createEditWindow {
        my $self = shift;
        my $scribbler = $self->scribbler;
        my $mw = $scribbler->mainwindow->Toplevel(-background => $BG, -title => ucfirst($scribbler->translate('test a condition')));
        $scribbler->windowIcon($mw, 'if_else');
        $mw->withdraw;
        my $frame1 = $mw->Frame(-background => $BG)->pack(-side => 'top', -expand => 1, -fill => 'x');
        my $frame2 = $mw->Frame(-background => $BG)->pack(-side => 'bottom', -padx => 2, -pady => 2, -expand => 1, -fill => 'x');
        my $frame3 = $frame1->Frame(-background => $BG)->pack(-side => 'left', -padx => 2, -pady => 2, -expand => 1, -fill=> 'y');
        my $column = 0;
        my $fraHoriz;
        foreach (keys %Buttons) {
                $fraHoriz = $frame3->Frame(-background => $BG)->pack(-anchor => 'w') if $column++ % $Columns == 0;
                $Index{$_} = 0;
                my $icon = $Buttons{$_}->{icons}->[0];
                my $sensor = $Buttons{$_}->{sensors}->[0];
                $BtnCond{$_} = $fraHoriz->ToggleButton(
                        -width => $BTN_SZ,
                        -height => $BTN_SZ,
                        -ontrigger => 'release',
                        -offtrigger => 'press',
                        -latching => 1,
                        -togglegroup => \%BtnCond,
                        -onbackground => $BG,
                        -offbackground => $BG,
                        -onrelief => 'flat',
                        -offrelief => 'flat',
                        -pressrelief => 'flat',
                        -cursor => 'hand2',
                        -borderwidth => 0,
                        -index => $_,
                        -offimage => $scribbler->button("multi_$icon\_off"),
                        -pressimage => $scribbler->button("multi_$icon\_push"),
                        -pressonimage => $scribbler->button("multi_$icon\_pushon"),
                        -onimage => $scribbler->button("multi_$icon\_on"),
                        -command => \&_evtConditionSelect
                )->pack(-side => 'left', -anchor => 'w', -pady => 0, -padx => 0);
                $scribbler->tooltip($BtnCond{$_}, $Sensors{$sensor}->{tip})
        }
        $fraHoriz = $frame3->Frame(-background => $BG)->pack(-anchor => 'w') if $column++ % $Columns == 0;

        my $swap = $fraHoriz->ToggleButton(
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
                -cursor => 'hand2',
                -pressimage => $scribbler->button('swap_press'),
                -offimage => $scribbler->button('swap_release'),
                -command => \&_evtSwap
        )->pack(-side => 'right', -pady => 0, -padx => 0);
        $scribbler->tooltip($swap, 'Switch TRUE and FALSE directions');

        $CanCond = $frame1->Canvas(
                -height=> 140,
                -width => 175,
                -background => 'LIGHTBLUE',
        )->pack(-side => 'right', -expand => 1, -fill => 'y');

        #Left square
        $CanCond->createRectangle(
                37, 100, 77, 140,
                -fill => $DARK_SCRIBBLER_BLUE,
                -outline => $DARK_SCRIBBLER_BLUE,
                -width => 8,
                -state => 'hidden',
                -tags => 'light'
        );
        #Right square -separated by 40 pixel gap
         $CanCond->createRectangle(
                117, 100, 157, 140,
                -fill => $DARK_SCRIBBLER_BLUE,
                -outline => $DARK_SCRIBBLER_BLUE,
                -width => 8,
                -state => 'hidden',
                -tags => 'light'
        );
#LIGHT OVALS
        #Left Oval  "Oval 0"
        $CanCond->createOval(
                (0 - 1.5) * 40 + 97, 100, (0 - 0.5) * 40 + 97, 140,
                -fill => 'BLACK',
                -outline => $DARK_SCRIBBLER_BLUE,
                -width => 8,
                -state => 'hidden',
                -tags => ['light', "light_0"]
        );
        #Right Oval "Oval 2"
        $CanCond->createOval(
                (2 - 1.5) * 40 + 97, 100, (2 - 0.5) * 40 + 97, 140,
                -fill => 'BLACK',
                -outline => $DARK_SCRIBBLER_BLUE,
                -width => 8,
                -state => 'hidden',
                -tags => ['light', "light_2"]
        );

        foreach my $rep (1 .. 8) {
                $CanCond->createImage(
                        85 + 8 * $rep, 135 - 8 * $rep,
                        -image => $scribbler->icon('line_dl'),
                        -tags => [map {"reps_$_"} ($rep .. 8)],
                        -state => 'hidden'
                )
        };

        $CanCond -> createImage(
                         60, 120,
                         -image => $scribbler->icon('reps_1'),
                         -tags => ["reps_image_1"  , 'reps_image'],
                         -state => 'hidden'
        );
        $CanCond -> createImage(
                         60, 120,
                         -image => $scribbler->icon('reps_2'),
                         -tags => ["reps_image_2"  , 'reps_image'],
                         -state => 'hidden'
        );
        $CanCond -> createImage(
                         60, 120,
                         -image => $scribbler->icon('reps_3'),
                         -tags => ["reps_image_3"  , 'reps_image'],
                         -state => 'hidden'
        );
        $CanCond -> createImage(
                         60, 120,
                         -image => $scribbler->icon('reps_4'),
                         -tags => ["reps_image_4"  , 'reps_image'],
                         -state => 'hidden'
        );
        $CanCond -> createImage(
                         60, 120,
                         -image => $scribbler->icon('reps_5'),
                         -tags => ["reps_image_5"  , 'reps_image'],
                         -state => 'hidden'
        );
        $CanCond -> createImage(
                         60, 120,
                         -image => $scribbler->icon('reps_6'),
                         -tags => ["reps_image_6"  , 'reps_image'],
                         -state => 'hidden'
        );
        $CanCond -> createImage(
                         60, 120,
                         -image => $scribbler->icon('reps_7'),
                         -tags => ["reps_image_7"  , 'reps_image'],
                         -state => 'hidden'
        );
        $CanCond -> createImage(
                         60, 120,
                         -image => $scribbler->icon('reps_8'),
                         -tags => ["reps_image_8"  , 'reps_image'],
                         -state => 'hidden'
        );

        #Number three image
        $CanCond->createImage(
                  25, 122,
                  -image => $scribbler->icon('light_numberthree'),
                  -state => 'hidden',
                  -tags => ['light']
        );
        #Number four image
        $CanCond->createImage(
                  105, 122,
                  -image => $scribbler->icon('light_numberfour'),
                  -state => 'hidden',
                  -tags => ['light']
        );

        $SelfEdit = Scribbler::ConditionalTile->new('', subclass => 'if_begin', canvas => $CanCond, size => [1,1]);
        $SelfEdit->createImage;
        $SelfEdit->location(0, 0.05);
        $SelfEdit->SUPER::redraw;
        $SelfEdit->SUPER::reactivate(1);

        $Slider = $frame2->Scale(
                -background => '#556666',
                -activebackground => '#00EEEE',
                -highlightthickness => 0,
                -troughcolor => $BG,
                -command => \&_evtChangeSlider,
                -from => 1,
                -to => 99,
                -cursor => 'hand2',
                -orient => 'horizontal',
                -relief => 'sunken',
                -width => $SLIDER_WIDTH,
                -sliderlength => $SLIDER_LENGTH,
                -showvalue => 0,
                -variable => \$SliderValue
        )->pack(-side => 'left', -padx => 5, -pady => 2, -expand => 1, -fill => 'x');

        foreach (qw/no okay/) {
                $frame2->ToggleButton(
                        -width => $BTN_SZ,
                        -height => $BTN_SZ,
                        -ontrigger => 'release',
                        -latching => 0,
                        -onrelief => 'flat',
                        -offrelief => 'flat',
                        -pressrelief => 'flat',
                        -onbackground => $BG,
                        -offbackground => $BG,
                        -cursor => 'hand2',
                        -borderwidth => 0,
                        -pressimage => $scribbler->button($_ . '_press'),
                        -offimage => $scribbler->button($_ . '_release'),
                        -command => [\&_evtClickButton, $_]
                )->pack(-side => 'right', -pady => 0, -padx => 0)
        }

        return $mw
}

sub _evtConditionSelect {
        my ($on, $btn) = @_;
        return unless $on;
        my $scribbler = $Self->scribbler;
        my @icons = @{$Buttons{$btn}->{icons}};
        if ($btn eq $Button) {
                $Index{$btn} = ($Index{$btn} + 1) % @icons
        } else {
                $Button = $btn
        }
        my $icon = $SelfEdit->action(icon => $icons[$Index{$btn}]);
        _redrawButtons([$btn => $icon]);
        my $sensor = $Sensors{$Self->sensor($icon)};
        if ($sensor ne $Sensor) {
                &{$Sensor->{onselect}}(0) if $Sensor && $Sensor->{onselect};
                $SliderValues{$Sensor} = $SliderValue;
                $Sensor = $sensor;
                if ($Sensor->{maxvalue}) {
                        $Slider->configure(-to => $Sensor->{maxvalue}, -state => 'normal');
                        $SliderValue = $SliderValues{$Sensor} || 1;
                        $scribbler->tooltip($Slider, $Sensor->{slidertip})
                } else {
                        $SliderValue = 1;
                        $Slider->configure(-state => 'disabled');
                        $scribbler->tooltip($Slider, '')
                }
                &{$Sensor->{onselect}}(1) if $Sensor->{onselect}
        }
        _evtChangeSlider();
        $SelfEdit->_updateWindow
}

sub _redrawButtons {
        my $scribbler = $SelfEdit->scribbler;
        foreach (@_) {
                my ($btn, $icon) = @$_;
                my $multi = @{$Buttons{$btn}->{icons}} > 1 ? 'multi_' : '';
                $BtnCond{$btn}->configure(
                        -offimage => $scribbler->button("$multi$icon\_off"),
                        -pressimage => $scribbler->button("$multi$icon\_push"),
                        -pressonimage => $scribbler->button("$multi$icon\_pushon"),
                        -onimage => $scribbler->button("$multi$icon\_on")
                );
                $scribbler->tooltip($BtnCond{$btn}, $Sensors{$SelfEdit->sensor($icon)}->{tip})
        }
}

sub _evtSelectLight {
        my $on = shift;
        $CanCond->itemconfigure('light', -state => $on ? 'normal' : 'hidden');
        $CanCond->itemconfigure('reps_image', -state => 'hidden');
}

sub _evtSelectReps {
        my $on = shift;
        if ($on) {
                $CanCond->itemconfigure('reps_8', -image => $SelfEdit->scribbler->icon($SelfEdit->action('icon')));
                _killReps();
                _setReps();
        } else {
                $CanCond->itemconfigure('reps_8', -state => 'hidden')    ;
                $CanCond->itemconfigure('reps_image', -state => 'hidden') ;
        }
}
sub _evtChangeSlider {
        my $icon = $SelfEdit->action('icon');
        my $sensor = $SelfEdit->sensor($icon);
        $SelfEdit->action(text => &{$Sensors{$sensor}->{text}});
        _killReps();
        &{$Sensor->{onslider}} if $Sensor->{onslider};
        $SelfEdit->_updateWindow
}

sub _setReps {
        $CanCond->itemconfigure("reps_$SliderValue", -state => 'normal') if $SliderValue >= 2
}

sub _setRepsIcons {
        $CanCond -> itemconfigure("reps_image", -state => 'hidden');
        $CanCond -> itemconfigure("reps_image_$SliderValue", -state => 'normal');
}
sub _killReps {
        $CanCond->itemconfigure('reps_8', -state => 'hidden');
        $CanCond->itemconfigure('reps_image', -state => 'hidden');
}

sub _evtSlideLight {
        my $type = ($SelfEdit->action('icon') =~ m/_([ldx]{3}|min|max|avg)/)[0];
        $type = 'lll' if $type =~ m/min|max|avg/;
        my ($min, $max);
        if ($type =~ m/d/) {
                $min = sprintf('#%6.6X', int(128 - 127 * sqrt($SliderValue) / 16) * 0x010101);
                $max = sprintf('#%6.6X', int(128 + 127 * sqrt($SliderValue) / 16) * 0x010101);
        } else {
                $max = sprintf('#%6.6X', int(255 * sqrt($SliderValue) / 16) * 0x010101);
        }
        foreach (0 .. 2) {
                my $xld = substr($type, $_, 1);
                $CanCond->itemconfigure("light_$_", -fill =>        $xld eq 'd' ? $min : $xld eq 'x' ? $DARK_SCRIBBLER_BLUE : $max);
        }
}

sub _evtClickButton {
        my $btn = shift;
        my $okay = $btn eq 'okay';
        if ($okay || $btn eq 'no') {
                if ($okay) {
                        $Self->action(%{$SelfEdit->action});
                        $Self->subclass($SelfEdit->subclass);
                }
                $Self->{done} = $btn
        }
}

sub _evtSwap {
        my $subclass = $SelfEdit->subclass;
        $subclass =~ m/if/ ? $subclass =~ s/if/unless/ : $subclass =~ s/unless/if/;
        $SelfEdit->subclass($subclass);
        $SelfEdit->_updateWindow
}

sub _updateWindow {
        my $self = shift;
        $self->createImage;
        $self->SUPER::reactivate(1);
        $self->SUPER::redraw;
}

sub sensor {
        my $self = shift;
        my $icon = shift;
        return ($icon =~ m/([^_]*)/)[0]
}

1;