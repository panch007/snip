#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::Pg;
use Mojolicious::Plugin::Human;
use Mojo::Content::MultiPart;
use Mojo::Upload;
use Mojo::UserAgent;
use Encode;

my $config = app->plugin('Config');
plugin('Human', { date => '%d/%m/%Y' }); # Плугин используется для чтения даты

helper pg => sub {
  my $bdpassword = $config->{'bdpassword'}; 
  my $bdhost = $config->{'bdhost'};
  my $bdname = $config->{'bdname'};  
  my $bduser = $config->{'bduser'};  
  state $pg = Mojo::Pg->new;
  $pg->from_string('postgresql://'.$bduser.':'.$bdpassword.'@'.$bdhost.'/'.$bdname);
};

get '/' => sub {
  my $c = shift;
##  показ списка сниппетов
  my $limit_line = $config->{'limit_line'};
  my $limit_snippets_on_page = $config->{'limit_snippets_on_page'};
  my $sdate = $c->req->param('sdate');
  my $db = $c->pg->db;
  my $prev_date = $db->query("
    SELECT max(m.add_date) as mdate
    FROM (
      SELECT add_date
      FROM snippets
      WHERE add_date <= coalesce(?,now() - '100 year'::interval) AND (tiket is null OR tiket = '')
      ORDER BY add_date DESC
      OFFSET ?
      ) m", $sdate, $limit_snippets_on_page)->hash->{mdate};
  my $next_date = $db->query("
    SELECT min(m.add_date) AS mdate
    FROM(
      SELECT add_date
      FROM snippets
      WHERE  add_date >= coalesce(?,now() - '100 year'::interval) AND (tiket is null  OR  tiket = '')
      ORDER BY add_date
      OFFSET ? 
      ) m ", $sdate, $limit_snippets_on_page)->hash->{mdate};
  my $all_amount_of_snippets = $db->query("SELECT count(id) co FROM snippets")->hash->{co};
  my $snippets_by_languges = $db->query("SELECT count(id) amount, language FROM snippets GROUP BY language")->hashes->to_array;
## первый фрагмент только от каждого сниппета
  my $results = $db->query("
    SELECT s.add_date, s.name, f.idsnippet, s.language, f.text_of_fragment
    FROM snippets s
    JOIN (
      SELECT min(id) idmin  , idsnippet from fragments
      GROUP BY idsnippet) d
    ON s.id = d.idsnippet
    JOIN fragments f
    ON s.id = f.idsnippet AND f.id=d.idmin
    WHERE not  f.text_of_fragment =''
      AND s.add_date >= coalesce(?,now() - '1 year'::interval)
      AND (s.tiket is null or  s.tiket = '')
    ORDER BY s.add_date
    LIMIT ?", $sdate, $limit_snippets_on_page)->hashes->to_array;
  $c->stash( 'limit_line' => $limit_line, snippets_by_languges => $snippets_by_languges, all_amount_of_snippets => $all_amount_of_snippets, content => $results, next_date => $next_date, prev_date => $prev_date, title =>'Список сниппетов' );
  $c->render(   template => 'index');
};

get '/upload' => sub {
  my $c = shift;
  $c->render(  title =>'', content =>  '', template => 'upload');
};

post '/upload' => sub {
  my $c = shift;
## создание описание сниппета
  my $snippets_name = $c->req->param('snippets_name');
  my $language = $c->req->param('language');
  my $tiket = $c->req->param('tiket');
  my $db = $c->pg->db;
  my $new_snippets_id = $db->query("INSERT INTO snippets (name, language, tiket) VALUES (?,?,?) RETURNING id", $snippets_name, $language, $tiket)->hash->{id};
  my $file = $c->req->uploads('upload');
  my $i = 0;
  foreach  my $fil (@$file){
    my $asset = $fil->asset;
    my $fragment_body = $asset->slurp;
    $fragment_body = decode('UTF-8', $fragment_body);
    if (length($fragment_body) > 0){
      $db->query('INSERT INTO fragments (text_of_fragment , idsnippet) VALUES (?,?)', $fragment_body, $new_snippets_id );
    }
  }
  my $url_of_fragment =    $c->req->every_param('url_of_fragment');
  my $ua  = Mojo::UserAgent->new;
  foreach  my $url (@$url_of_fragment){
    my $body = '';
    eval{ # ошибки не перехватываем
      my $res = $ua->get($url)->result;
      if($res->is_success){ $body = $res->body;}
        $body = decode('UTF-8', $body);
        if (length($body) > 0){
          $db->query('INSERT into fragments (text_of_fragment, idsnippet) values (?, ?)', $body, $new_snippets_id );
      }
      $body = '';
      $url = '';
    };
  }
  my $text_area_of_fragment =    $c->req->every_param('text_area_of_fragment');
  foreach my $text_area (@$text_area_of_fragment){
    $db->query('INSERT INTO fragments (text_of_fragment, idsnippet) VALUES (?, ?)', $text_area,  $new_snippets_id );
  }
  $c->render(  title =>$snippets_name,  content =>  '', template => 'upload');
};

get '/snip' => sub {
  my $c = shift;
# показ сниппета по id
  my $snip  = $c->req->param('snip');
  my $tiket = $c->req->param('tiket');
  my $db = $c->pg->db;
# проверка доступа
  my $acsess = $db->query("SELECT count(1) as c FROM snippets s WHERE s.id=? AND (tiket = ? or tiket  = '' or tiket is null) ", $snip, $tiket)->hash->{'c'};
# все фрагменты сниппета
  my $results = $db->query("
    SELECT s.add_date, s.name, f.idsnippet, s.language, f.text_of_fragment
    FROM snippets s 
    JOIN fragments f
    ON s.id = f.idsnippet 
    WHERE s.id = ? and not f.text_of_fragment ='' ", $snip)->hashes->to_array;
  if ($acsess == 0) {
    $c->render(content => [], title =>'Нет доступа '.$tiket,  template => 'snip');
  } else {
    $c->render(  content => $results,  title =>'Список сниппетов',  template => 'snip');
  }
};

app->start;

