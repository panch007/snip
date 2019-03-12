###  Пакет подпрограмм для Snip
###

package Snip::Snip;
use base qw(Exporter);
our @EXPORT = qw(
  test_snip_name
  test_snip_tiket
);

##  Проверка имени
sub test_snip_name {
  my $c = shift;
  my $v = shift;
  my $snippets_name = shift;

  $v->input({snippets_name => $snippets_name});
  $v->required('snippets_name')->check('size', 2, 115);
  $c->redirect_to('/upload') and return 0 if ($v->has_error('snippets_name'));
  return 0;
}

##  Проверка ключа
sub test_snip_tiket {
  my $c = shift;
  my $v = shift;
  my $tiket = shift;

  $v->input({tiket => $tiket});
  $v->required('tiket')->like(qr/\d*/);
  $c->redirect_to('/upload') and return 0 if ($v->has_error('snippets_name'));
  return 0;
}

1;
