package App::UI;
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Tk;
use App::OpenAI;
use App::Audio;

sub run {
    my ($class, $dict) = @_;

    # ---------------- Estado ----------------
    my $openai        = App::OpenAI->new();
    my $audio         = App::Audio->new();
    my $rows_per_page = 3;
    my $current_page  = 0;
    my $filtered      = [];

    # -------- Declaraciones adelantadas (TODAS antes de los closures) --------
    my ($apply_filter, $render_table, $refresh_all, $play_audio_for);
    my ($mw, $body, $form, $status);
    my ($english_entry, $save_button, $speak_button);
    my ($filter_entry, $filter_button, $clear_button);
    my ($prev_button, $page_label, $next_button);
    my ($table_frame, $font_base, $font_small, $font_cell, $font_head, $font_title);
    my (@headers, @widths);

    # ---------------- Ventana ----------------
    $mw = MainWindow->new;
    $mw->title('Diccionario Inglés-Español');
    $mw->geometry('1250x820');
    $mw->minsize(950, 600);
    $mw->configure(-background => '#f4f6f8');

    $font_title = ['Segoe UI', 16, 'bold'];
    $font_base  = ['Segoe UI', 10];
    $font_small = ['Segoe UI', 9];
    $font_cell  = ['Segoe UI', 12];
    $font_head  = ['Segoe UI', 13, 'bold'];

    # ---------------- Cabecera ----------------
    my $header = $mw->Frame(-background => '#2c3e50')->pack(-fill => 'x');
    $header->Label(
        -text       => 'Diccionario Inglés-Español',
        -font       => $font_title,
        -foreground => 'white',
        -background => '#2c3e50',
    )->pack(-anchor => 'w', -padx => 12, -pady => 8);

    # ---------------- Barra de estado ----------------
    $status = $mw->Label(
        -text       => 'Listo.',
        -anchor     => 'w',
        -background => '#ecf0f1',
        -foreground => '#2c3e50',
        -font       => $font_small,
    );
    $status->pack(-side => 'bottom', -fill => 'x');

    $body = $mw->Frame(-background => '#f4f6f8')
        ->pack(-fill => 'both', -expand => 1, -padx => 12, -pady => 8);

    # ---------------- Formulario de alta ----------------
    $form = $body->Frame(-background => '#f4f6f8')->pack(-fill => 'x');

    $form->Label(
        -text       => 'Palabra en inglés:',
        -font       => $font_base,
        -background => '#f4f6f8',
    )->pack(-side => 'left', -padx => 5);

    $english_entry = $form->Entry(-font => $font_base, -width => 26);
    $english_entry->pack(-side => 'left', -padx => 5);

    $save_button = $form->Button(
        -text             => 'Guardar',
        -background       => '#27ae60',
        -foreground       => 'white',
        -activebackground => '#2ecc71',
        -font             => $font_base,
        -width            => 16,
    );
    $save_button->pack(-side => 'left', -padx => 5);

    $speak_button = $form->Button(
        -text             => '🔊 Pronunciar',
        -background       => '#8e44ad',
        -foreground       => 'white',
        -activebackground => '#9b59b6',
        -font             => $font_base,
        -width            => 14,
    );
    $speak_button->pack(-side => 'left', -padx => 5);

    $form->Label(
        -text       => 'Se consultará la palabra + significados en inglés y español + 3 ejemplos.',
        -font       => ['Segoe UI', 9, 'italic'],
        -foreground => '#7f8c8d',
        -background => '#f4f6f8',
    )->pack(-side => 'left', -padx => 10);

    # ---------------- Filtro ----------------
    my $filter_frame = $body->Frame(-background => '#f4f6f8')->pack(-fill => 'x', -pady => 8);

    $filter_frame->Label(
        -text       => 'Filtrar por inglés:',
        -font       => $font_base,
        -background => '#f4f6f8',
    )->pack(-side => 'left', -padx => 5);

    $filter_entry = $filter_frame->Entry(-font => $font_base, -width => 26);
    $filter_entry->pack(-side => 'left', -padx => 5);

    $filter_button = $filter_frame->Button(
        -text             => 'Filtrar',
        -background       => '#2980b9',
        -foreground       => 'white',
        -activebackground => '#3498db',
        -font             => $font_base,
        -width            => 10,
    );
    $filter_button->pack(-side => 'left', -padx => 5);

    $clear_button = $filter_frame->Button(
        -text             => 'Limpiar',
        -background       => '#95a5a6',
        -foreground       => 'white',
        -activebackground => '#bdc3c7',
        -font             => $font_base,
        -width            => 10,
    );
    $clear_button->pack(-side => 'left', -padx => 5);

    # ---------------- Paginacion ----------------
    my $pagination_frame = $body->Frame(-background => '#f4f6f8')->pack(-fill => 'x');

    $prev_button = $pagination_frame->Button(
        -text             => '◀ Anterior',
        -background       => '#34495e',
        -foreground       => 'white',
        -activebackground => '#4a6178',
        -font             => $font_base,
        -width            => 12,
    );
    $prev_button->pack(-side => 'left', -padx => 5);

    $page_label = $pagination_frame->Label(
        -text       => 'Página 1 de 1',
        -font       => $font_base,
        -background => '#f4f6f8',
        -foreground => '#2c3e50',
    );
    $page_label->pack(-side => 'left', -padx => 15);

    $next_button = $pagination_frame->Button(
        -text             => 'Siguiente ▶',
        -background       => '#34495e',
        -foreground       => 'white',
        -activebackground => '#4a6178',
        -font             => $font_base,
        -width            => 12,
    );
    $next_button->pack(-side => 'left', -padx => 5);

    # ---------------- Tabla ----------------
    my $table_outer = $body->Frame(
        -background  => '#2c3e50',
        -borderwidth => 1,
        -relief      => 'solid',
    )->pack(-fill => 'both', -expand => 1, -pady => 6);

    $table_frame = $table_outer->Frame(-background => 'white')
        ->pack(-fill => 'both', -expand => 1, -padx => 1, -pady => 1);

    @headers = ('🔊', 'English', 'Significado (ES)', 'Meaning (EN)',
                'Ejemplos (EN)', 'Ejemplos (ES)');
    @widths  = (55, 140, 240, 260, 320, 320);

    for my $c (0 .. $#headers) {
        $table_frame->gridColumnconfigure($c, -minsize => $widths[$c], -weight => 1);
    }

    # =====================================================================
    #  Closures (ya con TODAS las variables inicializadas)
    # =====================================================================

    $apply_filter = sub {
        my $q = $filter_entry->get() // '';
        $q =~ s/^\s+|\s+$//g;
        $q = lc $q;

        my $items = $dict->list_words();
        $filtered = ($q eq '')
            ? $items
            : [ grep { index(lc($_->{english} // ''), $q) >= 0 } @$items ];
        $current_page = 0;
    };

    $render_table = sub {
        for my $w ($table_frame->children) { $w->destroy; }

        my $total       = @$filtered;
        my $total_pages = $total ? int(($total - 1) / $rows_per_page) + 1 : 1;

        $current_page = 0                if $current_page < 0;
        $current_page = $total_pages - 1 if $current_page > $total_pages - 1;

        # Encabezados
        for my $c (0 .. $#headers) {
            $table_frame->Label(
                -text       => $headers[$c],
                -font       => $font_head,
                -background => '#2c3e50',
                -foreground => 'white',
                -anchor     => 'w',
                -justify    => 'left',
                -wraplength => $widths[$c] - 12,
            )->grid(-row => 0, -column => $c, -sticky => 'nsew', -padx => 1, -pady => 1);
        }

        if ($total == 0) {
            $table_frame->Label(
                -text       => 'No hay palabras que coincidan.',
                -font       => $font_small,
                -background => 'white',
                -foreground => '#7f8c8d',
                -anchor     => 'w',
            )->grid(-row => 1, -column => 0, -columnspan => scalar(@headers),
                    -sticky => 'nsew', -padx => 6, -pady => 8);

            $page_label->configure(-text => 'Página 0 de 0  •  0 palabras');
            $prev_button->configure(-state => 'disabled');
            $next_button->configure(-state => 'disabled');
            return;
        }

        my $start = $current_page * $rows_per_page;
        my $end   = $start + $rows_per_page - 1;
        $end = $total - 1 if $end > $total - 1;

        for my $i ($start .. $end) {
            my $item = $filtered->[$i];
            my $r    = $i - $start + 1;
            my $word = $item->{english} // '';

            # ---- Boton de audio de la fila (declarado ANTES del closure) ----
            my $play_btn;
            $play_btn = $table_frame->Button(
                -text             => '🔊',
                -font             => $font_cell,
                -background       => '#8e44ad',
                -foreground       => 'white',
                -activebackground => '#9b59b6',
                -width            => 3,
                -cursor           => 'hand2',
                -command          => sub { $play_audio_for->($word, $play_btn) },
            );
            $play_btn->grid(-row => $r, -column => 0,
                            -sticky => 'nsew', -padx => 4, -pady => 4);

            my @meanings_es = @{ $item->{meanings_es} // [] };
            if (!@meanings_es && ref $item->{meanings} eq 'ARRAY') {
                @meanings_es = @{ $item->{meanings} };
            }
            if (!@meanings_es && $item->{spanish}) {
                @meanings_es = ($item->{spanish});
            }

            my @meanings_en = @{ $item->{meanings_en} // [] };
            my @examples    = @{ $item->{examples}    // [] };

            my $examples_en = @examples
                ? join("\n", map { '• ' . ($_->{en} // '') } @examples) : '—';
            my $examples_es = @examples
                ? join("\n", map { '• ' . ($_->{es} // '') } @examples) : '—';

            my @cells = (
                $item->{english} // '',
                (join("\n", map { "• $_" } @meanings_es) || '—'),
                (join("\n", map { "• $_" } @meanings_en) || '—'),
                $examples_en,
                $examples_es,
            );

            for my $c (0 .. $#cells) {
                $table_frame->Label(
                    -text       => $cells[$c],
                    -font       => $font_cell,
                    -background => 'white',
                    -foreground => '#2c3e50',
                    -anchor     => 'nw',
                    -justify    => 'left',
                    -wraplength => $widths[$c + 1] - 12,     # $c+1 por la columna 🔊
                )->grid(-row => $r, -column => $c + 1,
                        -sticky => 'nsew', -padx => 4, -pady => 4);
            }
        }

        # Rellenar filas sobrantes
        for my $r (($end - $start + 2) .. $rows_per_page) {
            for my $c (0 .. $#headers) {
                $table_frame->Label(
                    -text       => ' ',
                    -font       => $font_cell,
                    -background => 'white',
                )->grid(-row => $r, -column => $c,
                        -sticky => 'nsew', -padx => 4, -pady => 4);
            }
        }

        $page_label->configure(-text => sprintf(
            'Página %d de %d  •  %d palabra%s',
            $current_page + 1, $total_pages, $total, ($total == 1 ? '' : 's')
        ));
        $prev_button->configure(-state => $current_page > 0                ? 'normal' : 'disabled');
        $next_button->configure(-state => $current_page < $total_pages - 1 ? 'normal' : 'disabled');
    };

    $refresh_all = sub {
        $apply_filter->();
        $render_table->();
    };

    $play_audio_for = sub {
        my ($word, $btn) = @_;
        $word //= '';
        $word =~ s/^\s+|\s+$//g;
        if ($word eq '') {
            $status->configure(-text => 'Escribe o selecciona una palabra primero.');
            return;
        }

        # --- Cache hit: sin tocar la API ---
        if ($audio->has_cache($word)) {
            my $path = $audio->cache_path($word);
            if ($audio->play($path)) {
                $status->configure(-text => "▶ Reproduciendo \"$word\" (desde caché).");
            } else {
                $status->configure(-text => "Audio en caché: $path (no hay reproductor).");
            }
            return;
        }

        # --- Cache miss: pedimos a OpenAI y guardamos ---
        $status->configure(-text => "Generando audio para \"$word\"...");
        $btn->configure(-state => 'disabled') if $btn;
        $mw->update();

        $mw->after(50, sub {
            my ($path, $err) = $audio->ensure($word, $openai, voice => 'alloy');
            $btn->configure(-state => 'normal') if $btn;

            if ($err) {
                chomp(my $m = $err);
                $status->configure(-text => "Error TTS: $m");
                return;
            }

            if ($audio->play($path)) {
                $status->configure(-text => "▶ Reproduciendo \"$word\" (guardado en caché).");
            } else {
                $status->configure(-text =>
                    "Audio guardado en $path (no hay reproductor: instala pulseaudio-utils o ffmpeg).");
            }
        });
    };

    # =====================================================================
    #  Handlers de UI (ya podemos cablear los botones)
    # =====================================================================

    $speak_button->configure(-command => sub {
        $play_audio_for->($english_entry->get(), $speak_button);
    });

    $save_button->configure(-command => sub {
        my $english = $english_entry->get() // '';
        $english =~ s/^\s+|\s+$//g;
        if ($english eq '') {
            $status->configure(-text => 'Escribe una palabra en inglés.');
            return;
        }

        $status->configure(-text => "Consultando OpenAI para \"$english\"...");
        $save_button->configure(-state => 'disabled');
        $mw->update();

        $mw->after(100, sub {
            my $ok = eval {
                my $data = $openai->lookup_word($english);
                $dict->save_entry($data);
                1;
            };
            my $err = $@;

            $save_button->configure(-state => 'normal');

            if (!$ok) {
                chomp(my $msg = $err // 'Error desconocido');
                $status->configure(-text => "Error: $msg");
                return;
            }

            $status->configure(-text =>
                "Palabra \"$english\" guardada con significados (EN/ES) y ejemplos.");
            $english_entry->delete(0, 'end');
            $filter_entry->delete(0, 'end');
            $refresh_all->();
        });
    });

    $filter_button->configure(-command => sub { $refresh_all->(); });
    $filter_entry->bind('<Return>'     => sub { $refresh_all->(); });
    $filter_entry->bind('<KeyRelease>' => sub { $refresh_all->(); });

    $clear_button->configure(-command => sub {
        $english_entry->delete(0, 'end');   # ← nuevo
        $filter_entry->delete(0, 'end');
        $refresh_all->();                   # repinta la tabla sin filtro
        $english_entry->focus;              # ← opcional, pero comodo
        $status->configure(-text => 'Campos limpiados.');
    });

    $prev_button->configure(-command => sub {
        return if $current_page <= 0;
        $current_page--;
        $render_table->();
    });
    $next_button->configure(-command => sub {
        $current_page++;
        $render_table->();
    });

    $refresh_all->();
    MainLoop();
}

1;
