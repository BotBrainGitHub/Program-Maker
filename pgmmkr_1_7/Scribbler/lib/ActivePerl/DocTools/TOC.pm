package ActivePerl::DocTools::TOC;

use strict;
use warnings;

use Config qw(%Config);
use File::Basename qw(fileparse);
use File::Find qw(find);

our $dirbase = $Config{installhtmldir} || "$Config{installprefix}/html";

my @core_pods = qw(
*Overview
  perl  perlintro  perltoc
-
*Tutorials
  perlreftut  perldsc  perllol
-
  perlrequick  perlretut
-
  perlboot  perltoot  perltooc  perlbot  perlperf
-
  perlstyle
-
  perlcheat  perltrap  perldebtut
-
  perlfaq perlfaq1  perlfaq2  perlfaq3  perlfaq4  perlfaq5  perlfaq6
  perlfaq7  perlfaq8  perlfaq9
-
*Reference_Manual
  perlsyn  perldata  perlop  perlsub  perlfunc  perlopentut  perlpacktut
  perlpod  perlpodspec  perlrun  perldiag  perllexwarn  perldebug  perlvar
  perlre  perlrebackslash perlrecharclass perlreref  perlref  perlform  perlobj
  perltie  perldbmfilter
-
  perlipc  perlfork  perlnumber
-
  perlthrtut  perlothrtut
-
  perlport  perllocale  perluniintro  perlunicode  perlunifaq  perlunitut  perlebcdic
-
  perlsec
-
  perlmod  perlmodlib  perlmodstyle  perlmodinstall  perlnewmod perlpragma
-
  perlutil
-
  perlcompile
-
  perlfilter
-
  perlglossary
-
*Internals_and_C_Language_Interface
  perlembed  perldebguts  perlxstut  perlxs  perlclib  perlguts  perlcall
  perlmroapi  perlreapi  perlreguts
-
  perlapi  perlintern  perliol  perlapio
-
  perlhack  perlrepository
-
*Miscellaneous
  perlbook  perlcommunity  perltodo
-
  perldoc
-
  perlhist  perldelta
  perl5104delta  perl5103delta  perl5102delta perl5101delta  perl5100delta
  perl595delta  perl594delta  perl593delta  perl592delta
  perl591delta perl590delta
  perl589delta  perl588delta  perl587delta  perl586delta  perl585delta
  perl584delta  perl583delta  perl582delta  perl581delta  perl58delta
  perl573delta  perl572delta  perl571delta  perl570delta
  perl561delta  perl56delta  perl5005delta  perl5004delta
-
  perlartistic  perlgpl
-
*Language-Specific
  perlcn  perljp  perlko  perltw
-
*Platform-Specific
  perlaix  perlamiga  perlapollo  perlbeos  perlbs2000  perlce  perlcygwin
  perldgux  perldos  perlepoc  perlfreebsd  perlhaiku  perlhpux  perlhurd  perlirix  perllinux
  perlmachten  perlmacos  perlmacosx  perlmint  perlmpeix  perlnetware perlopenbsd
  perlos2  perlos390  perlos400  perlplan9  perlqnx  perlriscos  perlsolaris  perlsymbian
  perltru64  perluts  perlvmesa  perlvms  perlvos  perlwin32
);


# List of methods to override
for my $method (qw(
    header footer
    before_pods      pod      after_pods      pod_separator
    before_scripts   script   after_scripts
    before_pragmas   pragma   after_pragmas
    before_libraries library  after_libraries
    library_indent_open library_indent_close library_indent_same
    library_container))
{
    no strict "refs";
    *$method = sub {
	die "The subroutine $method() must be overriden by the child class"
    };
}


sub new {
    my($class, $options) = @_;
    my $self = $options ? $options : {};
    _BuildHashes($self);
    return bless($self, $class);
}


# generic structure for the website, HTML help, RDF
sub TOC {
    my($self) = @_;

    # generic header stuff
    my $output = $self->boilerplate;
    $output .= $self->header;

    # core pods
    $output .= $self->before_pods;

    my %unused_pods = %{$self->{pods}};
    foreach my $file (@core_pods) {
	next if $file =~ /^\*/;
	if ($file eq '-') {
	    $output .= $self->pod_separator;
	}
	elsif (delete $unused_pods{"Pod::$file"} || delete $unused_pods{"pods::$file"}) {
	    $output .= $self->pod($file);
	}
	else {
	    warn "Couldn't find pod for $file" if $self->{verbose};
	}
    }

    if ($self->{verbose}) {
	warn "Unused Pod: $_" for sort keys %unused_pods;
    }

    $output .= $self->after_pods;

    # scripts
    $output .= $self->before_scripts;
    $output .= $self->script($_) for sort {uc($a) cmp uc($b)} keys %{$self->{scripts}};
    $output .= $self->after_scripts;

    # pragmas
    $output .= $self->before_pragmas;
    $output .= $self->pragma($_) for sort keys %{$self->{pragmas}};
    $output .= $self->after_pragmas;

    # libraries
    $output .= $self->before_libraries;

    my $depth = 0;
    foreach my $file (sort {uc($a) cmp uc($b)} keys %{$self->{files}}) {
	my $showfile   = $file;
	my $file_depth = 0;
	my $depth_changed;

	# cuts $showfile down to its last part, i.e. Foo::Baz::Bar --> Bar
	# and counts the number of times, to get indent. --> 2
	$file_depth++ while $showfile =~ s/.*?::(.*)/$1/;

	while ($file_depth > $depth) {
	    $output .= $self->library_indent_open;
	    $depth++;
	    $depth_changed = 1;
	}
	while ($file_depth < $depth) {
	    $output .= $self->library_indent_close;
	    $depth--;
	    $depth_changed = 1;
	}

	$output .= $self->library_indent_same unless $depth_changed;

	if ($self->{files}->{$file}) {
	    $output .= $self->library($file, $showfile, $depth);
	}
	else {
	    # assume this is a containing item like a folder or something
	    $output .= $self->library_container($file, $showfile, $depth);
	}
    }

    $output .= $self->after_libraries;
    $output .= $self->footer;

    return $output;
}


sub _BuildHashes {
    my $self = shift;

    die "htmldir not found at: $dirbase" unless -d $dirbase;

    my @checkdirs = qw(bin lib site/lib);
    my (%files, %pragmas, %pods, %scripts);

    my $Process = sub {
	return if -d;
	my $parsefile = $_;

	my($filename,$dir,$suffix) = fileparse($parsefile,'\.html');

	if ($suffix !~ m#\.html#) { return; }

	my $TOCdir = $dir;

	$filename =~ s/(.*)\..*/$1/;

#    print "$TOCdir";
	my $ver = $Config{version};
	my $an = $Config{archname};
	if ($TOCdir =~ s#^.*?(bin/)(\Q$an\E/)?(.*)$#$3#) {
	    return if $filename eq "ppm3-bin";
	    return if $] >= 5.008 && $filename eq "ppm3";
	    return if $] < 5.008  && $filename eq "ppm";

	    $scripts{"$TOCdir$filename"} = "bin/$filename.html";
	    return 1;
	}
	$TOCdir =~ s#^.*?(lib/site_perl/\Q$ver\E/|lib/\Q$ver\E/|lib/)(\Q$an\E/)?(.*)$#$3#;
	$TOCdir =~ s#/#::#g;
	$TOCdir =~ s#^pod::#Pod::#; #Pod dir is uppercase in Win32
#    print " changed to: $TOCdir\n";
	$dir =~ s#.*?/((site/)?lib.*?)/$#$1#; #looks ugly to get around warning

	if ($files{"$TOCdir/$filename.html"}) {
	    warn "$parsefile: REPEATED!\n";
	}
	$files{"$TOCdir$filename"} = "$dir/$filename.html";
#    print "adding $parsefile as " . $files{"$TOCdir/$filename.html"} . "\n";
#    print "\%files{$TOCdir$filename.html}: " . $files{"$TOCdir$filename.html"} . "\n";

	return 1;
    };

    foreach my $dir (@checkdirs) {
	next unless -d "$dirbase/$dir";
	find({ wanted => $Process, no_chdir => 1 }, "$dirbase/$dir");
    }

    foreach my $file (keys %files) {
	if ($file =~ /^(Pod|pods)::perl/) {
	    $pods{$file} = delete $files{$file};
	}
	elsif ($file =~ /^(Pod|pods)::a2p$/ ||
	       $file eq "dmake"             ||
	       $file eq "MinGW"             ||
# perldoc.pod is installed into Perl/lib instead of Perl/bin
	       $file eq "perldoc")
	{
	    $scripts{a2p} = delete $files{$file};
	}
	elsif ($file eq 'Pod::PerlEz'          ||
	       $file =~ /^(Pod|pods)::active/  ||
# perlpod.pod and perlpodspec.pod are installed by Pod-Simple into Perl/lib
# We already have those files in pods/perlpod.pod etc from the core, so
# don't want to index the additional copies.
	       $file =~ /^perlpod(spec)?$/     ||
#	       $file =~ /^ActivePerl/          ||
#	       $file =~ /^ActiveState/         ||
	       $file =~ /^ASRemote/            ||
	       $file =~ /^PPM/)
        {
	    # these files are internal and support files
	    delete $files{$file};
	}
	elsif ($file =~ /^[a-z]/) {
	    if ($file ne 'perlfilter' &&
		$file ne 'lwpcook'    &&
		$file ne 'lwptut'     &&
                $file ne 'perl5db'    &&
		$file ne 'perllocal')
	    {
		$pragmas{$file} = delete $files{$file};
	    }
	}
    }

    foreach my $file (sort {uc($b) cmp uc($a)} keys %files) {
	my $prefix = $file;
	while ($prefix =~ s/(.*)?::(.*)/$1/) {
	    unless (defined ($files{$prefix})) {
		$files{$prefix} = '';
		warn "Added topic: $prefix\n" if $self->{verbose};
	    }
	    warn "$prefix from $file\n" if $self->{verbose};
	}
    }

    $self->{files}   = \%files;
    $self->{pods}    = \%pods;
    $self->{pragmas} = \%pragmas;
    $self->{scripts} = \%scripts;
}

1;
