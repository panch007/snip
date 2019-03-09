#!/usr/bin/env perl
####  Список тестов для функционального тестирования
use Mojo::Base ;
use Test::Mojo;
use Test::More;
use FindBin;
use Data::Dumper;
require './snip.pl';
##  тесты формы загрузки
my $t = Test::Mojo->new();
my @array_text_area_of_fragment = (' t=2; ' ,  '/bin/perl  p=1;  r=2;ddddyyyyyydd');
my @arr_url_of_fragment = ('https://mojolicious.org/perldoc/Mojo/UserAgent', 'https://hh.ru');
my @languages = ('perl','perl','perl','perl','perl','perl','perl','perl');
my $form_upload = {
  enctype => 'multipart/form-data',
  snippets_name => 'test1900',
  language1 => \@languages,
  language2 => \@languages,
  language3 => \@languages,
  text_area_of_fragment  => \@array_text_area_of_fragment ,
  url_of_fragment => \@arr_url_of_fragment,
  'upload[0]' => { file => 'public/test/test.cpp' }  , 'upload[1]' => {  file => 'public/test/test.pl'  }  , 'upload[2]' => {  file => 'public/test/test.pl' }
 };
## тест существования загруженных строк в textarea
$t->post_ok('/upload' => form => $form_upload)->status_is(200)->content_like(qr/ddddyyyyyydd/i)->content_like(qr/p=1/i);;
done_testing();
