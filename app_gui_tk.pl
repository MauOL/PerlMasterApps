#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use Tk;

# Crear ventana principal
my $ventana = MainWindow->new;
$ventana->title('Interfaz gráfica en Perl');
$ventana->geometry('420x320');
$ventana->resizable(0, 0);

# Título
my $titulo = $ventana->Label(
    -text => 'Hola desde Perl/Tk',
    -font => ['Arial', 18, 'bold'],
    -foreground => '#2c3e50'
)->pack(
    -pady => 15
);

# Texto descriptivo
my $descripcion = $ventana->Label(
    -text => 'Escribe tu nombre y presiona el botón.',
    -font => ['Arial', 11]
)->pack(
    -pady => 5
);

# Campo de entrada
my $entrada = $ventana->Entry(
    -width => 30,
    -font => ['Arial', 12]
)->pack(
    -pady => 10
);

# Etiqueta para mostrar resultado
my $resultado = $ventana->Label(
    -text => '',
    -font => ['Arial', 12],
    -foreground => '#16a085'
)->pack(
    -pady => 10
);

# Botón para saludar
my $boton_saludar = $ventana->Button(
    -text => 'Saludar',
    -font => ['Arial', 11],
    -width => 15,
    -command => sub {
        my $nombre = $entrada->get();

        if ($nombre =~ /^\s*$/) {
            $resultado->configure(-text => 'Por favor escribe tu nombre.');
        } else {
            $resultado->configure(-text => "¡Hola, $nombre! Bienvenido a Perl/Tk.");
        }
    }
)->pack(
    -pady => 5
);

# Botón para limpiar
my $boton_limpiar = $ventana->Button(
    -text => 'Limpiar',
    -font => ['Arial', 11],
    -width => 15,
    -command => sub {
        $entrada->delete(0, 'end');
        $resultado->configure(-text => '');
    }
)->pack(
    -pady => 5
);

# Botón para salir
my $boton_salir = $ventana->Button(
    -text => 'Salir',
    -font => ['Arial', 11],
    -width => 15,
    -command => sub {
        exit;
    }
)->pack(
    -pady => 5
);

# Iniciar loop gráfico
MainLoop;
