#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use utf8;
use open ':std', ':encoding(UTF-8)';
use App::Dictionary;
use App::UI;

my $dict = App::Dictionary->new();
App::UI->run($dict);
