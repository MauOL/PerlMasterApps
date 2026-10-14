package App::OpenAI;
use strict;
use warnings;
use utf8;
use Encode qw(encode);
use JSON::PP;
use HTTP::Tiny;
use File::Temp qw(tempfile);
use File::Spec;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        api_key  => $args{api_key}  // $ENV{OPENAI_API_KEY} // '',
        model    => $args{model}    // 'gpt-4o-mini',
        endpoint => $args{endpoint} // 'https://api.openai.com/v1/chat/completions',
        http     => HTTP::Tiny->new(
            timeout => $args{timeout} // 60,
            agent   => 'PerlDictionaryApp/1.0',
        ),
    }, $class;
    return $self;
}

sub lookup_word {
    my ($self, $english) = @_;
    $english //= '';
    $english =~ s/^\s+|\s+$//g;
    die "La palabra está vacía.\n"             if $english eq '';
    die "Falta la variable OPENAI_API_KEY.\n"  unless $self->{api_key};

    my $payload = {
        model    => $self->{model},
        messages => [
            { role => 'system',
              content => 'Eres un diccionario inglés-español. Responde SIEMPRE en JSON válido, sin markdown ni texto adicional.' },
            { role => 'user', content => $self->_build_prompt($english) },
        ],
        temperature     => 0.2,
        response_format => { type => 'json_object' },
    };

    my $res = $self->{http}->post(
        $self->{endpoint},
        {
            headers => {
                'Authorization' => 'Bearer ' . $self->{api_key},
                'Content-Type'  => 'application/json',
            },
            content => encode_json($payload),
        }
    );

    unless ($res->{success}) {
        my $detail = $res->{content} // '';
        $detail =~ s/\s+/ /g;
        die sprintf("Error de OpenAI (%s %s): %s\n",
            $res->{status}, $res->{reason}, $detail);
    }

    my $body = eval { decode_json($res->{content}) };
    die "Respuesta JSON inválida de OpenAI.\n" unless $body;

    if (my $err = $body->{error}) {
        die "OpenAI: " . ($err->{message} // 'error desconocido') . "\n";
    }

    my $choice  = $body->{choices}[0] or die "OpenAI no devolvió 'choices'.\n";
    my $message = $choice->{message} // {};

    if (my $refusal = $message->{refusal}) {
        die "El modelo rechazó la petición: $refusal\n";
    }

    my $content = $message->{content};
    die "OpenAI devolvió contenido vacío (finish_reason="
        . ($choice->{finish_reason} // '?') . ").\n"
        unless defined $content && length $content;

    # $content ya viene decodificado; re-encodeamos para parsear el JSON interno
    my $data = eval { decode_json(encode('UTF-8', $content)) };
    die "El modelo no devolvió JSON válido: $content\n" unless $data;

    $data->{english}     = $english;
    $data->{meanings_en} = [] unless ref $data->{meanings_en} eq 'ARRAY';
    $data->{meanings_es} = [] unless ref $data->{meanings_es} eq 'ARRAY';
    $data->{examples}    = [] unless ref $data->{examples}    eq 'ARRAY';
    return $data;
}

sub speak_word {
    my ($self, $text, %opt) = @_;
    my $bytes = $self->synthesize($text, %opt);

    my ($fh, $filename) = tempfile(
        'pron_' . _slug($text) . '_XXXX',
        SUFFIX => '.mp3',
        DIR    => File::Spec->tmpdir,
        UNLINK => 0,
    );
    binmode $fh;
    print {$fh} $bytes;
    close $fh;
    return $filename;
}

sub _slug {
    my $s = shift // '';
    $s =~ s/[^A-Za-z0-9]+/_/g;
    return substr($s, 0, 30) || 'word';
}

# Devuelve los BYTES crudos del MP3 (para que Audio.pm los cachee).
sub synthesize {
    my ($self, $text, %opt) = @_;
    $text //= '';
    $text =~ s/^\s+|\s+$//g;
    die "Texto vacío para TTS.\n"             if $text eq '';
    die "Falta la variable OPENAI_API_KEY.\n" unless $self->{api_key};

    my $payload = {
        model => $opt{model} // 'gpt-4o-mini-tts',
        input => $text,
        voice => $opt{voice} // 'alloy',
        response_format => $opt{format} // 'mp3',
    };

    my $res = $self->{http}->post(
        'https://api.openai.com/v1/audio/speech',
        {
            headers => {
                'Authorization' => 'Bearer ' . $self->{api_key},
                'Content-Type'  => 'application/json',
            },
            content => encode_json($payload),
        }
    );

    unless ($res->{success}) {
        my $detail = $res->{content} // '';
        $detail =~ s/\s+/ /g;
        die sprintf("Error de TTS (%s %s): %s\n",
            $res->{status}, $res->{reason}, $detail);
    }

    return $res->{content};
}

sub _build_prompt {
    my ($self, $english) = @_;
    return <<"PROMPT";
Eres un diccionario inglés-español. Investiga la palabra inglesa "$english".

Devuelve EXCLUSIVAMENTE un objeto JSON con esta estructura exacta:
{
  "english": "$english",
  "meanings_en": ["breve definición en inglés 1", "breve definición en inglés 2"],
  "meanings_es": ["significado en español 1", "significado en español 2"],
  "examples": [
    { "en": "oración de ejemplo 1 en inglés", "es": "traducción al español" },
    { "en": "oración de ejemplo 2 en inglés", "es": "traducción al español" },
    { "en": "oración de ejemplo 3 en inglés", "es": "traducción al español" }
  ]
}

Reglas:
- Máximo 5 significados; meanings_en y meanings_es en el MISMO orden y con la MISMA longitud.
- Exactamente 3 ejemplos de uso.
- Sin markdown, sin texto adicional, sólo el JSON.
PROMPT
}

1;
