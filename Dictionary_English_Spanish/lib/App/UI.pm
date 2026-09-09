package App::UI;
use strict;
use warnings;

use Tk;
use Tk::ROText;

sub run {
    my ($class, $dict) = @_;

    my $mw = MainWindow->new;
    $mw->title('Diccionario Inglés-Español');
    $mw->geometry('720x520');
    $mw->configure(-background => '#f4f6f8');

    my $font_title = ['Segoe UI', 16, 'bold'];
    my $font_base  = ['Segoe UI', 10];

    my $header = $mw->Frame(-background => '#2c3e50')->pack(-fill => 'x');
    $header->Label(
        -text       => 'Diccionario Inglés-Español',
        -font       => $font_title,
        -foreground => 'white',
        -background => '#2c3e50',
        #-padding    => 12,
    )->pack(-anchor => 'w');

    my $body = $mw->Frame(-background => '#f4f6f8')->pack(-fill => 'both', -expand => 1, -padx => 15, -pady => 15);

    my $form = $body->Frame(-background => '#f4f6f8')->pack(-fill => 'x');

    $form->Label(-text => 'Palabra en inglés:', -font => $font_base, -background => '#f4f6f8')->grid(-row => 0, -column => 0, -sticky => 'w', -padx => 5, -pady => 5);
    my $english = $form->Entry(-font => $font_base, -width => 35)->grid(-row => 0, -column => 1, -sticky => 'we', -padx => 5, -pady => 5);

    $form->Label(-text => 'Significado en español:', -font => $font_base, -background => '#f4f6f8')->grid(-row => 1, -column => 0, -sticky => 'w', -padx => 5, -pady => 5);
    my $spanish = $form->Entry(-font => $font_base, -width => 35)->grid(-row => 1, -column => 1, -sticky => 'we', -padx => 5, -pady => 5);

    my $buttons = $body->Frame(-background => '#f4f6f8')->pack(-fill => 'x', -pady => 10);

    my $status = $body->Label(
        -text       => 'Listo.',
        -anchor     => 'w',
        -background => '#f4f6f8',
        -foreground => '#34495e',
        -font       => $font_base,
    )->pack(-fill => 'x', -pady => 5);

    my $list = $body->Scrolled('ROText',
        -scrollbars => 'e',
        -height     => 16,
        -font       => $font_base,
        -background => 'white',
        -wrap       => 'none',
    )->pack(-fill => 'both', -expand => 1);

    my $refresh_list = sub {
        $list->delete('1.0', 'end');
        my $items = $dict->list_words();
        if (!@$items) {
            $list->insert('end', "No hay palabras guardadas.\n");
            return;
        }
        for my $item (@$items) {
            $list->insert('end', sprintf("%s = %s\n", $item->{english}, $item->{spanish}));
        }
    };

    my $save_action = sub {
        my $ok = $dict->add_word($english->get(), $spanish->get());
        if ($ok) {
            $status->configure(-text => 'Palabra guardada correctamente.');
            $english->delete(0, 'end');
            $spanish->delete(0, 'end');
            $refresh_list->();
        } else {
            $status->configure(-text => 'Debes completar ambos campos.');
        }
    };

    my $search_action = sub {
        my $query = $english->get();
        my $found = $dict->search_word($query);
        $list->delete('1.0', 'end');
        if ($found) {
            $list->insert('end', "Resultado:\n");
            $list->insert('end', sprintf("%s = %s\n", $found->{english}, $found->{spanish}));
            $status->configure(-text => 'Palabra encontrada.');
        } else {
            $list->insert('end', "No se encontró la palabra buscada.\n");
            $status->configure(-text => 'Sin resultados.');
        }
    };

    $buttons->Button(
        -text    => 'Guardar',
        -command => $save_action,
        -background => '#27ae60',
        -foreground => 'white',
        -activebackground => '#2ecc71',
        -font    => $font_base,
        -width   => 12,
    )->pack(-side => 'left', -padx => 5);

    $buttons->Button(
        -text    => 'Buscar',
        -command => $search_action,
        -background => '#2980b9',
        -foreground => 'white',
        -activebackground => '#3498db',
        -font    => $font_base,
        -width   => 12,
    )->pack(-side => 'left', -padx => 5);

    $buttons->Button(
        -text    => 'Listar todo',
        -command => $refresh_list,
        -background => '#8e44ad',
        -foreground => 'white',
        -activebackground => '#9b59b6',
        -font    => $font_base,
        -width   => 12,
    )->pack(-side => 'left', -padx => 5);

    $buttons->Button(
        -text    => 'Salir',
        -command => sub { exit 0 },
        -background => '#c0392b',
        -foreground => 'white',
        -activebackground => '#e74c3c',
        -font    => $font_base,
        -width   => 12,
    )->pack(-side => 'right', -padx => 5);

    $refresh_list->();
    MainLoop();
}

1;
