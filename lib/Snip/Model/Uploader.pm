package Snip::Model::Uploader;

use Mojo::Base 'MojoX::Model';
use Snip::Snip;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper;

sub new {
  my $class = shift;
  my $self = {};
  bless ($self, $class);
  my $c = $self->{'c'} = shift;
  my $v = $self->{'v'} = shift;
  $self->{'snippets_name'} = $c->req->param('snippets_name');
  $self->{'tiket'} =  $c->req->param('tiket');
  $self->{'file'} = [];
  foreach my $f (@{$c->req->uploads('upload')}){
    push  @{$self->{'file'}} , $f;    
  }
  $self->{'url_of_fragment'} = $c->req->every_param('url_of_fragment');
  $self->{'text_area_of_fragment'} = $c->req->every_param('text_area_of_fragment');
  $self->{'languages1'} = $c->req->every_param('language1');
  $self->{'languages2'} = $c->req->every_param('language2');
  $self->{'languages3'} = $c->req->every_param('language3');  
  $c->session( {'tiket' => $self->{'tiket'},
    'snippets_name' => $self->{'snippets_name'},
    'file' => $self->{'file'},
    'url_of_fragment' => $self->{'url_of_fragment'},
    'text_area_of_fragment' => $self->{'text_area_of_fragment'},
    'languages1' => $self->{'languages1'},
    'languages2' => $self->{'languages2'},
    'languages3' => $self->{'languages3'}
  } ) ;
  return $self;
}

sub test {
  my $self = shift;
  my $c = $self->{'c'};
  my $v = $self->{'v'};
  my $rnd = '';
  my $i = 0;
 ## проверка фраментов
  foreach my $fil (@{$self->{'file'}}) {
    if ($fil->filename){
      $v->input({file_size => $fil->size });
      $v->required('file_size','file_size_validaiton');      
      $c->redirect_to('/upload?p=$rnd&i='.$i) and return 0 if ($v->has_error('file_size'));
    }
  }
  $i = 0;
  my $url_last = "";
##  защита от частого считывания заголовка при нескольких одинаковых урлах подряд
  foreach my $url (@{$self->{'url_of_fragment'}}) {
    if ($url &&  ($url_last ne $url) ){
      $v->input({url_of_fragment => $url});
      $v->required('url_of_fragment','url_validation')->like(qr/1/);
      $c->redirect_to('/upload?p=$rnd&i='.$i) and return 0 if ($v->has_error('url_of_fragment'));
      $url_last = $url;
    }
    ++$i;
  }
  foreach my $text_area (@{$self->{'text_area_of_fragment'}}){
     if ($text_area){
      $v->input({text_area_of_fragment => $text_area});
      $v->required('text_area_of_fragment')->check('size', 2, 115);
      $c->redirect_to('/upload?p=$rnd&i='.$i) and return 0 if ($v->has_error('text_area_of_fragment'));
    }
  }  
}


1;
