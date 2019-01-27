#!/usr/bin/env perl
####  Список тестов для функционального тестирования 
####  в разработке

use Mojo::Base ;
use Test::Mojo;
use Test::More;
use FindBin;

 require './snip.pl';

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200)->content_like(qr/upload/i);

done_testing();
