#!/usr/bin/env perl

use strict;
use warnings;
# use Wx::Event qw(EVT_BUTTON);

package MiApp;
use base 'Wx::App';

sub OnInit {
    my $self = shift;

    my $frame = MiFrame->new();
    $frame->Show(1);

    return 1;
}

package MiFrame;
use Wx qw(:everything);
use Wx::Event qw(EVT_BUTTON);
use base 'Wx::Frame';

sub new {
    my $class = shift;

    # fix: se corrige expresion
    # my $style = wxDEFAULT_FRAME_STYLE & ~(wxRESIZE_BORDER | wxMAXIMIZE_BOX);
    my $style = wxDEFAULT_FRAME_STYLE() & ~(wxRESIZE_BORDER() | wxMAXIMIZE_BOX());

    my $self = $class->SUPER::new(
        undef,
        -1,
        'Interfaz gráfica en Perl',
        wxDefaultPosition,
        Wx::Size->new(470, 500),
        $style
    );

    my $panel = Wx::Panel->new($self, -1);

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);

    # Título
    my $titulo = Wx::StaticText->new(
        $panel,
        -1,
        'Hola desde Perl/Wx'
    );
    $titulo->SetFont(Wx::Font->new(
        18,
        wxFONTFAMILY_SWISS,
        wxFONTSTYLE_NORMAL,
        wxFONTWEIGHT_BOLD,
        0,
        'Arial'
    ));
    $titulo->SetForegroundColour(Wx::Colour->new(44, 62, 80));

    $sizer->Add($titulo, 0, wxALIGN_CENTER | wxTOP | wxBOTTOM, 15);

    # Texto descriptivo
    my $descripcion = Wx::StaticText->new(
        $panel,
        -1,
        'Escribe tu nombre y presiona el botón.'
    );
    $descripcion->SetFont(Wx::Font->new(
        11,
        wxFONTFAMILY_SWISS,
        wxFONTSTYLE_NORMAL,
        wxFONTWEIGHT_NORMAL,
        0,
        'Arial'
    ));

    $sizer->Add($descripcion, 0, wxALIGN_CENTER | wxBOTTOM, 5);

    # Campo de entrada
    my $entrada = Wx::TextCtrl->new(
        $panel,
        -1,
        '',
        wxDefaultPosition,
        Wx::Size->new(250, -1)
    );
    $entrada->SetFont(Wx::Font->new(
        12,
        wxFONTFAMILY_SWISS,
        wxFONTSTYLE_NORMAL,
        wxFONTWEIGHT_NORMAL,
        0,
        'Arial'
    ));

    $sizer->Add($entrada, 0, wxALIGN_CENTER | wxTOP | wxBOTTOM, 10);

    # Etiqueta para mostrar resultado
    my $resultado = Wx::StaticText->new(
        $panel,
        -1,
        ''
    );
    $resultado->SetFont(Wx::Font->new(
        12,
        wxFONTFAMILY_SWISS,
        wxFONTSTYLE_NORMAL,
        wxFONTWEIGHT_NORMAL,
        0,
        'Arial'
    ));
    $resultado->SetForegroundColour(Wx::Colour->new(22, 160, 133));

    $sizer->Add($resultado, 0, wxALIGN_CENTER | wxTOP | wxBOTTOM, 10);

    # Botón para saludar
    my $boton_saludar = Wx::Button->new(
        $panel,
        -1,
        'Saludar',
        wxDefaultPosition,
        Wx::Size->new(150, -1)
    );
    $boton_saludar->SetFont(Wx::Font->new(
        11,
        wxFONTFAMILY_SWISS,
        wxFONTSTYLE_NORMAL,
        wxFONTWEIGHT_NORMAL,
        0,
        'Arial'
    ));

    $sizer->Add($boton_saludar, 0, wxALIGN_CENTER | wxBOTTOM, 5);

    EVT_BUTTON($self, $boton_saludar, sub {
        my $nombre = $entrada->GetValue();

        if ($nombre =~ /^\s*$/) {
            $resultado->SetLabel('Por favor escribe tu nombre.');
        } else {
            $resultado->SetLabel("¡Hola, $nombre! Bienvenido a Perl/Wx.");
        }

        $panel->Layout();
    });

    # Botón para limpiar
    my $boton_limpiar = Wx::Button->new(
        $panel,
        -1,
        'Limpiar',
        wxDefaultPosition,
        Wx::Size->new(150, -1)
    );
    $boton_limpiar->SetFont(Wx::Font->new(
        11,
        wxFONTFAMILY_SWISS,
        wxFONTSTYLE_NORMAL,
        wxFONTWEIGHT_NORMAL,
        0,
        'Arial'
    ));

    $sizer->Add($boton_limpiar, 0, wxALIGN_CENTER | wxBOTTOM, 5);

    EVT_BUTTON($self, $boton_limpiar, sub {
        $entrada->SetValue('');
        $resultado->SetLabel('');
        $panel->Layout();
    });

    # Botón para salir
    my $boton_salir = Wx::Button->new(
        $panel,
        -1,
        'Salir',
        wxDefaultPosition,
        Wx::Size->new(150, -1)
    );
    $boton_salir->SetFont(Wx::Font->new(
        11,
        wxFONTFAMILY_SWISS,
        wxFONTSTYLE_NORMAL,
        wxFONTWEIGHT_NORMAL,
        0,
        'Arial'
    ));

    $sizer->Add($boton_salir, 0, wxALIGN_CENTER | wxBOTTOM, 5);

    EVT_BUTTON($self, $boton_salir, sub {
        $self->Close(1);
    });

    $panel->SetSizer($sizer);
    $self->Centre();

    return $self;
}

package main;

my $app = MiApp->new();
$app->MainLoop();
