-- создание таблиц 
-- ----------------------------------
CREATE TABLE public.language (
    id SERIAL PRIMARY KEY NOT NULL,
    name text NOT NULL,    
    CONSTRAINT uk_laguage UNIQUE (name)
);

COMMENT ON TABLE public.language IS 'список языков программирования';
COMMENT ON COLUMN public.language.id IS 'код языка';
COMMENT ON COLUMN public.language.name IS 'наименование языка';
INSERT INTO language (name) VALUES ('perl'),('java'),('python'),('cpp'), ('shell'), ('croc');
-- ----------------------------------
CREATE TABLE public.snippets (
    id SERIAL PRIMARY KEY NOT NULL,
    name text NOT NULL,
    language text,
    tiket text,
    add_date timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE public.snippets IS 'сниппеты';
COMMENT ON COLUMN public.snippets.name IS 'наименование';
COMMENT ON COLUMN public.snippets.language IS 'язык программирования';
COMMENT ON COLUMN public.snippets.tiket IS 'секретный код';
CREATE VIEW public.snippets_common AS
 SELECT snippets.id,
    snippets.add_date,
    snippets.name,
    snippets.tiket
   FROM public.snippets
  WHERE ((snippets.tiket = ''::text) OR (snippets.tiket IS NULL));
COMMENT ON VIEW public.snippets_common IS 'доступные сниппеты';
-- ----------------------------------
CREATE TABLE public.fragments (
    id SERIAL PRIMARY KEY NOT NULL,
    text_of_fragment text NOT NULL,
    idsnippet integer NOT NULL,
    language text,
    CONSTRAINT fk_fragment_to_snippet FOREIGN KEY (idsnippet)
      REFERENCES public.snippets (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT fk_fragments_laguage FOREIGN KEY (language)
      REFERENCES public.language (name) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);
COMMENT ON TABLE public.fragments IS 'фрагменты сниппетов';
COMMENT ON COLUMN public.fragments.text_of_fragment IS 'тест фрагмента кода';
COMMENT ON COLUMN public.fragments.idsnippet IS 'код сниппета';
COMMENT ON COLUMN public.fragments.language IS 'язык программирования';


