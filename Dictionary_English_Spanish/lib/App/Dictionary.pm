package App::Dictionary;
use strict;
use warnings;

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

sub add_word {
    my ($self, $english, $spanish) = @_;
    $english //= '';
    $spanish //= '';

    $english =~ s/^\s+|\s+$//g;
    $spanish =~ s/^\s+|\s+$//g;

    return 0 if $english eq '' || $spanish eq '';

    for my $item (@{ $self->{words} }) {
        if (lc($item->{english}) eq lc($english)) {
            $item->{spanish} = $spanish;
            $self->{storage}->save_words($self->{words});
            return 1;
        }
    }

    push @{ $self->{words} }, {
        english => $english,
        spanish => $spanish,
    };

    $self->{storage}->save_words($self->{words});
    return 1;
}

sub list_words {
    my ($self) = @_;
    return [ sort { lc($a->{english}) cmp lc($b->{english}) } @{ $self->{words} } ];
}

sub search_word {
    my ($self, $query) = @_;
    $query //= '';
    $query =~ s/^\s+|\s+$//g;
    return undef if $query eq '';

    for my $item (@{ $self->{words} }) {
        return $item if lc($item->{english}) eq lc($query);
    }

    return undef;
}

1;
