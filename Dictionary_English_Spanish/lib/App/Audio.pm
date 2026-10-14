package App::Audio;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use File::Spec;
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Digest::MD5 qw(md5_hex);

our $VERSION = '1.00';

# new(%args)
#   dir    => carpeta de cache (por defecto $HOME/PerlDictionaryApp/audio)
#   player => arrayref con el comando (se autodetecta si no se indica)
sub new {
    my ($class, %args) = @_;
    my $self = bless {
        dir    => $args{dir} // _cache_dir(),
        player => $args{player},
    }, $class;

    make_path($self->{dir}) unless -d $self->{dir};
    $self->{player} //= _detect_player();
    return $self;
}

sub _project_root {
    my $dir = File::Spec->rel2abs(dirname(__FILE__));
    my $cur = $dir;
    for (1 .. 6) {
        return $cur if -e File::Spec->catfile($cur, 'app.pl');
        return $cur if -e File::Spec->catfile($cur, 'bin', 'app.pl');
        my $up = File::Spec->rel2abs(File::Spec->catdir($cur, '..'));
        last if $up eq $cur;
        $cur = $up;
    }
    return $dir;
}

sub _cache_dir {
    return $ENV{DICT_AUDIO_DIR} if $ENV{DICT_AUDIO_DIR};
    return File::Spec->catdir(_project_root(), 'data', 'audio');
}

sub dir { $_[0]->{dir} }

sub _which {
    my $cmd = shift // '';
    return 0 if $cmd eq '';
    return system("command -v $cmd >/dev/null 2>&1") == 0;
}

sub _detect_player {
    for my $c (
        ['paplay'],
        ['ffplay', '-nodisp', '-autoexit', '-loglevel', 'quiet'],
        ['mpv',    '--really-quiet'],
        ['aplay',  '-q'],
    ) {
        return $c if _which($c->[0]);
    }
    return undef;
}

sub can_play { defined $_[0]->{player} ? 1 : 0 }

sub cache_path {
    my ($self, $text) = @_;
    return File::Spec->catfile($self->{dir}, md5_hex($text) . '.mp3');
}

sub has_cache {
    my ($self, $text) = @_;
    return -e $self->cache_path($text) ? 1 : 0;
}

sub store {
    my ($self, $text, $bytes) = @_;
    my $path = $self->cache_path($text);
    open my $fh, '>:raw', $path
        or die "No se pudo guardar el audio en $path: $!\n";
    print {$fh} $bytes;
    close $fh;
    return $path;
}

# Reproduce sin bloquear Tk: fork + exec y nos olvidamos del hijo.
sub play {
    my ($self, $path) = @_;
    return 0 unless defined $path && -e $path;
    return 0 unless $self->{player};

    my $pid = fork;
    return 0 unless defined $pid;
    if ($pid == 0) {
        # Bloque propio: evita el warning "Statement unlikely to be reached"
        # (perldiag: 'To suppress this warning, put the exec() in a block by itself.')
        { exec @{ $self->{player} }, $path; }
        exit 1;   # solo se alcanza si exec() fallo
    }
    return 1;
}

# ensure($text, $openai, %opt) → ($path, $err, $from_cache)
#   • Si ya esta en cache, la devuelve sin llamar a OpenAI.
#   • Si no, sintetiza, guarda en cache y devuelve la ruta.
sub ensure {
    my ($self, $text, $openai, %opt) = @_;

    my $cached = $self->cache_path($text);
    return ($cached, undef, 1) if -e $cached;

    my $bytes = eval { $openai->synthesize($text, %opt) };
    return (undef, $@, 0) if $@;
    return (undef, "TTS devolvió contenido vacío.\n", 0)
        unless defined $bytes && length $bytes;

    my $path = eval { $self->store($text, $bytes) };
    return (undef, $@, 0) if $@;

    return ($path, undef, 0);
}

# Vaciar la cache (por si alguna vez quieres "regenerar" un audio)
sub clear_cache {
    my ($self) = @_;
    my $n = 0;
    opendir(my $dh, $self->{dir}) or return 0;
    while (my $f = readdir $dh) {
        next unless $f =~ /\.mp3$/;
        unlink File::Spec->catfile($self->{dir}, $f) and $n++;
    }
    closedir $dh;
    return $n;
}

1;
