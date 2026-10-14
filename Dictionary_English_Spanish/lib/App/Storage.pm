package App::Storage;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use JSON::PP;
use File::Spec;
use File::Path qw(make_path);
use File::Basename qw(dirname);

sub new {
    my ($class) = @_;
    my $self = bless {
        dir  => _data_dir(),
        file => undef,
    }, $class;

    make_path($self->{dir}) unless -d $self->{dir};
    $self->{file} = File::Spec->catfile($self->{dir}, 'words.json');
    return $self;
}

# Sube desde el directorio del modulo hasta hallar app.pl (o bin/app.pl).
# Asi los datos quedan junto al proyecto, no en $HOME.
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
    return $dir;   # fallback: junto al propio modulo
}

sub _data_dir {
    return $ENV{DICT_DATA_DIR} if $ENV{DICT_DATA_DIR};
    return File::Spec->catdir(_project_root(), 'data');
}

sub load_words {
    my ($self) = @_;
    return [] unless -e $self->{file};

    open my $fh, '<:encoding(UTF-8)', $self->{file} or return [];
    local $/;
    my $json = <$fh> // '[]';
    close $fh;

    my $data = eval { decode_json($json) };
    return ref($data) eq 'ARRAY' ? $data : [];
}

sub save_words {
    my ($self, $words) = @_;
    open my $fh, '>:encoding(UTF-8)', $self->{file} or die "No se pudo guardar: $!";
    print {$fh} encode_json($words);
    close $fh;
    return 1;
}

1;
