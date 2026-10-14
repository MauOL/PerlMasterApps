package App::Storage;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use JSON::PP;
use File::Spec;
use File::Path qw(make_path);

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

sub _data_dir {
    my $home = $ENV{APPDATA} || $ENV{HOME} || '.';
    return File::Spec->catdir($home, 'PerlDictionaryApp');
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
