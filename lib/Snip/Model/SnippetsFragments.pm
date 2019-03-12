package Snip::Model::SnippetsFragments;

use Mojo::Base 'MojoX::Model';

sub new {
  my $class = shift;
  my $self = {};
  bless ($self, $class);
  $self->{db} = shift;
  return $self;
}

sub get_prev_date_hash {
  my ($self,  $sdate, $limit_snippets_on_page) = @_;
  my $db= $self->{db};
  my $prev_date_hash = $db->query("
    SELECT to_char(add_date, 'dd-mm-yyyy HH24:MI:SS')
    FROM snippets_common
    WHERE add_date <= ?::timestamp with time zone
    ORDER BY add_date DESC
    OFFSET ? LIMIT 1
    ", $sdate, $limit_snippets_on_page)->hash;
  return  $prev_date_hash;
}

sub get_next_date_hash {
  my ($self,  $sdate, $limit_snippets_on_page) = @_;
  my $db= $self->{db};
  my $next_date_hash  = $db->query("
    SELECT to_char(add_date, 'dd-mm-yyyy HH24:MI:SS') m1
    FROM snippets_common
    WHERE add_date >= ?::timestamp with time zone
    ORDER BY add_date
    OFFSET ? LIMIT 1", $sdate, $limit_snippets_on_page)->hash;
  return $next_date_hash;
}

sub get_fragments_by_languges {
  my $self = shift;
  my $db= $self->{db};
  my $fragments_by_languges = $db->query("
    SELECT count(f.id) amount, f.language
    FROM fragments f GROUP BY f.language")->hashes->to_array;
  return $fragments_by_languges;
}

sub get_list_of_snippets {
  my ($self,  $sdate, $limit_snippets_on_page) = @_;
  my $db= $self->{db};
  my $results = $db->query("
   SELECT to_char(s.add_date, 'dd-mm-yyyy HH24:MI:SS') add_date, s.name, f.idsnippet, f.language, f.text_of_fragment
    FROM snippets_common s
    LEFT JOIN (
      SELECT min(id) idmin, idsnippet from fragments
      GROUP BY idsnippet) d
    ON s.id = d.idsnippet
    LEFT JOIN fragments f
    ON s.id = f.idsnippet AND f.id=d.idmin
    WHERE s.add_date >= ?::timestamp with time zone
    ORDER BY s.add_date
    LIMIT ?", $sdate, $limit_snippets_on_page)->hashes->to_array;
  return  $results;
}

sub get_fragments {
  my ($self,  $snip) = @_;
  my $db= $self->{db};
  my $results = $db->query("
    SELECT to_char(s.add_date, 'dd-mm-yyyy HH24:MI:SS') add_date, s.name, f.idsnippet, f.language, f.text_of_fragment
    FROM snippets_common s
    JOIN fragments f
    ON s.id = f.idsnippet
    WHERE s.id = ? AND NOT f.text_of_fragment = '' ", $snip)->hashes->to_array||[];
  return $results;
}

sub test_tiket_access {
  my ($self, $snip, $tiket) = @_;
  my $db= $self->{db};
  my $acsess = $db->query("
    SELECT count(1) as c
    FROM snippets s
    WHERE s.id = ? AND ( tiket = ? OR tiket = '' OR tiket is null) "
   ,$snip, $tiket)->hash->{c}||0;
  return $acsess;
}

sub get_last_snippetid {
  my ($self, $snip) = @_;
  my $db= $self->{db};
  $snip = $db->query("
    SELECT s.id as c
    FROM snippets_common s
    ORDER BY s.add_date desc LIMIT 1")->hash->{c};
  return $snip;
}

sub write_fragments {
  my ($self,  $fragment, $snipid, $laguage) = @_;
  my $db= $self->{db};
  $db->query('INSERT INTO fragments (text_of_fragment, idsnippet, language)
                  VALUES (?, ?, ?)'
                 ,$fragment, $snipid, $laguage);
  return 1;
}

sub create_new_snippet {
  my ($self,  $snippets_name, $tiket ) = @_;
    my $db= $self->{db};
  return my $new_snippets_id = $db->query("INSERT INTO snippets (name, tiket) VALUES (?,?) RETURNING id",$snippets_name, $tiket)->hash->{id};
}

1;
