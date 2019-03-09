/*  snip
*/

$(document).on('click', '#test_form_upload', function(e) {
   if ($("#snippets_name").val().length == 0){
      alert('Введите наименование сниппета');
      e.preventDefault();
   }
});

$( document ).ready(function() {
  $( "#addupload" ).click(function() {
   jQuery("div[id=elemid]") 
    var inner_html = $('div[name="upload"]').first.html();
    $('#upload_wrap').append(inner_html);
    return false;
  });
  $( "#addurl" ).click(function() {
    var inner_html = $('#url').html();
    $('#url_wrap').append( inner_html);
    return false;
  });
  $( "#addtext" ).click(function() {
    var inner_html = $('#text_area').html();
    $('#text_area_wrap').append( inner_html);
    return false;
  });

  $("#language option:first").attr('selected','selected');
//  Проверка поддерживаемости языков
//  не поддерживается - выбор пункта не активен
  var lang_installed = '' + hljs.listLanguages();
  var lang_array = lang_installed.split(/,/);
// сделать активным те элементы массива которые встречаются в списке который возвратила библиотека
  $('#language option').each(function() {
    var name_option = $(this).val();
    if (! lang_array.includes(name_option)){
      $(this).prop('disabled', 'disabled');
    }
  });
});



