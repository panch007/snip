#!/usr/bin/env perl
# snip
#
# demo for Mojolicious::Lite

use strict;
use utf8;
use Encode;
use Data::Dumper;
##
use Mojolicious::Lite;
use Mojo::Pg;
use Mojo::Pg::Transaction;
use Mojolicious::Plugin::Human;
use Mojo::Content::MultiPart;
use Mojo::Upload;
use Mojo::UserAgent;
use Mojo::Date;
use Mojolicious::Validator;
use Mojolicious::Validator::Validation;
use Mojo::JSON qw(decode_json encode_json);
##
use lib 'lib';
use Snip::Model::SnippetsFragments;
use Snip::Model::Uploader;
use Snip::Snip;
##
my $config = app->plugin('Config');
my $pg = Mojo::Pg->new;
my $bdurl = $config->{'bdurl'};
$pg->from_string($bdurl);
my $db = $pg->db;
my $validator = Mojolicious::Validator->new;
my $snippetsfragments = Snip::Model::SnippetsFragments->new($db);
if (my $secrets = app->config->{'secrets'}) {
  app->secrets($secrets);
}

plugin('Human', { date => '%d/%m/%Y' }); # Плугин используется для записи даты

sub init_ua {
## Создание объекта для работы с урлами
  my $ua = shift ;
  $ua = Mojo::UserAgent->new;
  my $connect_timeout = $config->{'connect_timeout'};
  my $max_file_size = $config->{'max_file_size'};
  my $request_timeout = $config->{'request_timeout'};
  $ua->connect_timeout($connect_timeout);
  $ua->max_response_size($max_file_size) ;
  $ua->request_timeout($request_timeout);
  $ua->inactivity_timeout($connect_timeout);
  return $ua;
}

sub get_ip {
##  проверки для урл
  my $url = shift;
  return "0" if(! $url);
  my $local_adresses = shift;
## проверка доступности
  my $ua = shift;
  my $tx =  $ua->head($url);
  return '0' if (!$tx);
  if( $tx->res->code ){
    return '0' if( $tx->res->code >= 400);
### локальный адрес ?
    my $ip = $tx->remote_address;
    return '0' if ( index($local_adresses, $ip) > -1 );
  } else  {  return '0';  }
  return '1';
}

get '/error' => sub {
## выдача ошибки
  my $c = shift;
  $c->render( error => '', title =>'Ошибка',  template => 'error');
};

get '/upload' => sub {
## создание сниппета
   my $c = shift;
   my $is_new = $c->req->param('new');
   my $err ||= '';
   my $snippets_name = '';
###  восстанавливаем форму из сессии
   if (!$is_new) {
     $snippets_name = $c->session->{'snippets_name'}||'';
     $err = $c->session->{'err'};
   }
   my $options_language = $db->query("SELECT id, name FROM language")->hashes;  
   $c->session(expires => 1) if ($is_new);
   $c->stash( err => $err
     ,title =>'Загрузка нового сниппета.'.$snippets_name
     ,content => $c->session
     ,options_language => $options_language );
   $c->render( template => 'upload');
};

get '/' => sub {
##  показ списка сниппетов
  my $c = shift;

  my $limit_snippets_on_page = $config->{'limit_snippets_on_page'}; ## количество сниппетов на странице
  my $limit_line = $config->{'limit_line'}; ##  количество строк первого фрагмента которые показываем 

## валидация параметра
  my $validator = Mojolicious::Validator->new;
  my $v = Mojolicious::Validator::Validation->new(validator => $validator);
  my $sdate = $c->req->param('sdate');
  $sdate =~ s/^([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{4}).*/$1/g if($sdate);
  $v->input({'sdate' => $sdate});
  $v->required('sdate')->like(qr/^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{4}/);
  $sdate = '01-01-2001' if ($v->has_error('sdate')); ## минимальная дата
  my $err = '';
  my $next_date = $sdate;
  my $prev_date = $sdate;

##  дата начало предыдущей страницы сниппетов
  my $prev_date_hash = $snippetsfragments->get_prev_date_hash($sdate, $limit_snippets_on_page );
  $prev_date = $prev_date_hash->{m1} if ($prev_date_hash) ;

## дата начала следущей страницы сниппетов
  my $next_date_hash  = $snippetsfragments->get_next_date_hash($sdate, $limit_snippets_on_page);
  $next_date = $next_date_hash->{m1} if ($next_date_hash) ;

## количество сниппетов всего
  my $all_amount_of_snippets = $db->query("SELECT count(id) co FROM snippets")->hash->{co};

## количество фрагментов всего
  my $all_amount_of_fragments = $db->query("SELECT count(id) co FROM fragments")->hash->{co};

## количество фрагментов по языкам
  my $fragments_by_languges = $snippetsfragments->get_fragments_by_languges();

## хеш для страницы
  my $results = $snippetsfragments->get_list_of_snippets($sdate, $limit_snippets_on_page);
  $c->stash( limit_line => $limit_line, fragments_by_languges => $fragments_by_languges
            ,all_amount_of_snippets => $all_amount_of_snippets
            ,all_amount_of_fragments => $all_amount_of_fragments
            ,content => $results
            ,next_date => $next_date, prev_date => $prev_date, sdate => $sdate, title =>'Список сниппетов'
            );
  $c->render( template => 'index');
};

post '/upload' => sub {
##  загрузка нового сниппета
  my $c = shift;

  my $ua; ##  UserAgent
  $ua = &init_ua($ua);
  my $err = "";
  my $local_adresses = $config->{'local_adresses'}; ##  список локальных адресов для обхода
  my $max_file_size = $config->{'max_file_size'};
  my $tx = $db->begin; ## открытие транзакции
  my $validator = Mojolicious::Validator->new;
  my $v = Mojolicious::Validator::Validation->new(validator => $validator);
  $validator = $validator->add_filter(url_validation => sub {
    my ($v, $name, $value) = @_;
    my $ret = &get_ip($value, $local_adresses, $ua);
    return $ret;
  });
  $validator = $validator->add_filter(file_size_validaiton => sub {
    my ($v, $name, $value) = @_;
    my $ret = ($max_file_size >= $value );
    return $ret;
  });
  my $uploader = Snip::Model::Uploader->new($c, $v);
## сохраняем формув сессии
  $uploader->test;   
  test_snip_name($c, $v, $uploader->{'snippets_name'}); ## проверка snippets_name
  test_snip_tiket($c, $v, $uploader->{'tiket'}); ## проверка тикета
  my $new_snippets_id = $snippetsfragments->create_new_snippet($uploader->{'snippets_name'}, $uploader->{'ticket'});

## Запись сниппета  
  my $i = 0;
  foreach my $fil (@{$uploader->{'file'}}) {
    my $asset = $fil->asset;
    my $fragment_body = $asset->slurp;
    $fragment_body = decode('UTF-8', $fragment_body);
    $snippetsfragments->write_fragments($fragment_body, $new_snippets_id, $uploader->{'languages1'}->[$i] ) if (length($fragment_body) > 0);
    ++$i;
  }

## очищаем обект
  $ua = &init_ua($ua);
  $i = 0;
  foreach my $url (@{$uploader->{'url_of_fragment'}}) {
    if (length($url)>0) {
      my $body = '';
      $err = "ошибка сети $url";
      my $ts = {};
      $ts = $ua->get($url);
      $err = $ts->error->{'message'}. " ".$url if ($ts->error);
      if($ts->res->is_success) {
        $body = $ts->res->body;
        $body = decode('UTF-8', $body);
        $err = "ок";
      }
      $snippetsfragments->write_fragments($body, $new_snippets_id, $uploader->{'languages2'}->[$i] ) if ($body ne '');
    }
    ++$i;
  }

  $i = 0;
  foreach my $text_area (@{$uploader->{'text_area_of_fragment'}}){
    $snippetsfragments->write_fragments($text_area, $new_snippets_id, $uploader->{'languages3'}->[$i]) if ($text_area);
    ++$i;
  }

# коммиттим транзакцию
  $tx->commit;
  my $results = $snippetsfragments->get_fragments($new_snippets_id);
  $c->stash(content => $results, title =>'Список фрагментов', err => $err);
  $c->render(  template => 'snip');
};

get '/snip' => sub {
# показ сниппета по id
  my $c = shift;
  my $err = '';
  my $v = Mojolicious::Validator::Validation->new(validator => $validator);
  my $snip = $c->req->param('snip');
  my $tiket = $c->req->param('tiket')||0;

  $v->input({snip => $snip});
  $v->required('snip')->like(qr/^(\d+)$/,'g');
  $c->redirect_to('/error') and return 0 if ($v->has_error('snip'));
  $v->input({tiket => $tiket});
  $v->required('tiket')->like(qr/^(\d*)$/,'g');
  $c->redirect_to('/error') and return 0 if ($v->has_error('tiket'));

## последний добавленный сниппет
  if ($snip eq 'last'){  $snip = $snippetsfragments->get_last_snippetid;  }

# проверка доступа по тикету
  $tiket = '' if (!$tiket);
  my $acsess = $snippetsfragments->test_tiket_access($snip, $tiket);

# все фрагменты сниппета
  my $results = $snippetsfragments->get_fragments($snip);
  if ($acsess == 0) { ##  доступа нет
    $c->stash( content => [], title =>'Нет доступа '.$tiket, err => $err);
    $c->render( template => 'snip');
  } else { ##  доступа есть
    $c->stash(  content => $results, title =>'Список фрагментов', err => $err);
    $c->render(  template => 'snip');
  }
};

app->start;
    
