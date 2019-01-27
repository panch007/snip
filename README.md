# snip

распаковать
изменить настройки в snip.conf<br/>
Создать таблицы в бд с помощью snip.sql

Установить 

 Mojolicious::Lite;
 Mojolicious::Plugin::Human;
 Mojo::Pg;
 Mojo::Content::MultiPart;
 Mojo::Upload;
 Mojo::UserAgent;

из cpan 

запустить 

./snip.pl daemon -m production -l http://*:8080

Перейти на ссылку в браузере http://localhost:8080

С appach2 проверялся путем копирования каталога приложения в cgi-bin
или любой другой каталог разрешающий запуск скриптов

Тест запускается стандартно prove -lv t

Для получения другого списка языков программирования нужно скачать с сайта highlight.pack.js
с нужными параметрами.

