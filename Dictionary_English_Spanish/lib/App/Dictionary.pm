package App::Dictionary;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use App::Storage;

sub new {
    my ($class) = @_;
    my $self = bless {
        storage => App::Storage->new(),
        words   => [],
    }, $class;
    $self->{words} = $self->{storage}->load_words();
    return $self;
}

sub save_entry {
    my ($self, $entry) = @_;
    return 0 unless ref $entry eq 'HASH';

    my $english = _trim($entry->{english} // '');
    return 0 if $english eq '';

    my @meanings_en = grep { length } map { _trim($_) }
        @{ ref $entry->{meanings_en} eq 'ARRAY' ? $entry->{meanings_en} : [] };
    my @meanings_es = grep { length } map { _trim($_) }
        @{ ref $entry->{meanings_es} eq 'ARRAY' ? $entry->{meanings_es} : [] };

    # Compatibilidad con formatos anteriores
    if (!@meanings_es && ref $entry->{meanings} eq 'ARRAY') {
        @meanings_es = grep { length } map { _trim($_) } @{ $entry->{meanings} };
    }
    if (!@meanings_es && length($entry->{spanish} // '')) {
        @meanings_es = (_trim($entry->{spanish}));
    }

    my @examples;
    for my $ex (grep { ref $_ eq 'HASH' }
                @{ ref $entry->{examples} eq 'ARRAY' ? $entry->{examples} : [] }) {
        my $en = _trim($ex->{en} // '');
        my $es = _trim($ex->{es} // '');
        next if $en eq '' && $es eq '';
        push @examples, { en => $en, es => $es };
    }

    my %clean = (
        english     => $english,
        meanings_en => \@meanings_en,
        meanings_es => \@meanings_es,
        examples    => \@examples,
        # Compatibilidad con el formato previo
        meanings    => \@meanings_es,
        spanish     => $meanings_es[0] // '',
    );

    for my $item (@{ $self->{words} }) {
        if (lc($item->{english} // '') eq lc($english)) {
            %$item = %clean;
            $self->{storage}->save_words($self->{words});
            return 1;
        }
    }

    push @{ $self->{words} }, \%clean;
    $self->{storage}->save_words($self->{words});
    return 1;
}

sub add_word {
    my ($self, $english, $spanish) = @_;
    return $self->save_entry({
        english     => $english,
        meanings_es => [$spanish // ''],
    });
}

sub list_words {
    my ($self) = @_;
    return [ sort { lc($a->{english}) cmp lc($b->{english}) } @{ $self->{words} } ];
}

sub search_word {
    my ($self, $query) = @_;
    $query = _trim($query);
    return undef if $query eq '';
    for my $item (@{ $self->{words} }) {
        return $item if lc($item->{english} // '') eq lc($query);
    }
    return undef;
}

sub _trim {
    my $s = shift // '';
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

1;
