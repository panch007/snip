-- создание сктруктур для программы snip
--
--  
CREATE SEQUENCE public.fragments_id_seq
  INCREMENT 1
  START 1
  MINVALUE 1
  NO MAXVALUE
  CACHE 1;
ALTER TABLE public.fragments_id_seq
  OWNER TO mojo;
CREATE SEQUENCE public.snippets_id_seq
  INCREMENT 1
  START 1
  MINVALUE 1
  NO MAXVALUE
  CACHE 1;
ALTER TABLE public.snippets_id_seq  OWNER TO mojo;
-- таблица фрагментов
CREATE TABLE public.fragments
(
  id integer NOT NULL DEFAULT nextval('fragments_id_seq'::regclass),
  text_of_fragment text, -- тест фрагмента кода
  idsnippet integer, -- код сниппета
  CONSTRAINT pk_fragments PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.fragments
  OWNER TO postgres;
COMMENT ON TABLE public.fragments
  IS 'фрагменты сниппетов';
COMMENT ON COLUMN public.fragments.text_of_fragment IS 'тест фрагмента кода';
COMMENT ON COLUMN public.fragments.idsnippet IS 'код сниппета';
CREATE TABLE public.snippets
(
  id integer NOT NULL DEFAULT nextval('snippets_id_seq'::regclass),
  add_date timestamp without time zone DEFAULT now(), -- дата и время добавлнеия
  name text, -- наименование
  language text, -- язык программирования
  tiket text, -- секретный код
  CONSTRAINT pk_snippets PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
-- таблицасниппетов
ALTER TABLE public.snippets
  OWNER TO mojo;
COMMENT ON TABLE public.snippets
  IS 'сниппеты';
COMMENT ON COLUMN public.snippets.add_date IS 'дата и время добавлнеия';
COMMENT ON COLUMN public.snippets.name IS 'наименование';
COMMENT ON COLUMN public.snippets.language IS 'язык программирования';
COMMENT ON COLUMN public.snippets.tiket IS 'секретный код	
';
ALTER TABLE public.fragments
  ADD CONSTRAINT fk_fragment_to_snippet FOREIGN KEY (idsnippet)
      REFERENCES public.snippets (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;
CREATE INDEX sn_date
  ON public.snippets
  USING btree
  (add_date);
CREATE INDEX fki_fragment_to_snippet
  ON public.fragments
  USING btree
  (idsnippet);

