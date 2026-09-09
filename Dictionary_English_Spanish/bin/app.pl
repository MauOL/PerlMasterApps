#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use App::Dictionary;
use App::UI;

my $dict = App::Dictionary->new();
App::UI->run($dict);
