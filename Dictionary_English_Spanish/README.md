# Diccionario Inglés-Español en Perl 5.x

Aplicación de escritorio en Perl con interfaz gráfica para:
- Guardar palabras en inglés y su significado en español
- Ver el listado de palabras
- Buscar una palabra

## Estructura

- `bin/app.pl` -> punto de entrada
- `lib/App/Dictionary.pm` -> lógica principal
- `lib/App/Storage.pm` -> persistencia en JSON
- `lib/App/UI.pm` -> interfaz gráfica con Tk

## Requisitos

- Perl 5.x
- Módulos:
  - `Tk`
  - `JSON::PP`
  - `File::Spec`
  - `File::Path`

En Strawberry Perl puedes instalar módulos con `cpan` o `cpanm`.

## Ejecutar

bash
perl bin/app.pl


## Generar .exe con PAR::Packer

Instala `PAR::Packer`:

bash
cpan PAR::Packer


Luego compila:

bash
pp -o Diccionario.exe -M Tk -M JSON::PP -M File::Spec -M File::Path bin/app.pl


Si tu app usa más módulos locales, asegúrate de incluir `-I lib`:

bash
pp -I lib -o Diccionario.exe -M Tk -M JSON::PP -M File::Spec -M File::Path bin/app.pl


## Notas sobre varios scripts Perl

Cuando una app está dividida en varios scripts o módulos:

1. Deja un único archivo de arranque, por ejemplo `bin/app.pl`.
2. Mueve la lógica reutilizable a módulos en `lib/`.
3. Usa `use lib 'lib';` en el script principal.
4. Empaqueta el script principal con `pp`, incluyendo la ruta `lib`.

Ejemplo:

bash
pp -I lib -o Diccionario.exe bin/app.pl


## Datos

La aplicación guarda la información en un archivo JSON local dentro de una carpeta de datos del usuario.
