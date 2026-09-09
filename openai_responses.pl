#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP qw(encode_json decode_json);
use LWP::UserAgent;
use HTTP::Request;

# Requiere la variable de entorno OPENAI_API_KEY
my $api_key = $ENV{OPENAI_API_KEY} or die "Debes definir OPENAI_API_KEY\n";

my $prompt = join(' ', @ARGV);
$prompt = 'Hola, ¿cómo estás?' unless defined $prompt && length $prompt;

my $url = 'https://api.openai.com/v1/responses';

my $payload = {
    model => 'gpt-4.1-mini',
    input => $prompt,
};

my $ua = LWP::UserAgent->new;
$ua->timeout(60);

my $req = HTTP::Request->new(POST => $url);
$req->header('Content-Type' => 'application/json');
$req->header('Authorization' => "Bearer $api_key");
$req->content(encode_json($payload));

my $res = $ua->request($req);

if (!$res->is_success) {
    die "Error HTTP ".$res->code.": ".$res->message."\n".$res->decoded_content."\n";
}

my $data = decode_json($res->decoded_content);

# La API Responses puede devolver el texto en diferentes estructuras.
# Intentamos extraer el contenido de forma robusta.
my $output_text = '';

if (exists $data->{output_text} && defined $data->{output_text}) {
    $output_text = $data->{output_text};
} elsif (exists $data->{output} && ref $data->{output} eq 'ARRAY') {
    for my $item (@{$data->{output}}) {
        next unless ref $item eq 'HASH';
        if (exists $item->{content} && ref $item->{content} eq 'ARRAY') {
            for my $c (@{$item->{content}}) {
                next unless ref $c eq 'HASH';
                $output_text .= $c->{text} if exists $c->{text};
            }
        }
    }
}

if (length $output_text) {
    print "$output_text\n";
} else {
    # Fallback: imprime la respuesta completa si no se pudo extraer texto
    print encode_json($data), "\n";
}
