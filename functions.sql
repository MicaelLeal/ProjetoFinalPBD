CREATE OR REPLACE FUNCTION
  inserir(nome_tabela REGCLASS, VARIADIC args character varying[]) RETURNS VOID AS
$$

DECLARE
  insert_string character varying;
  i             character varying;
  passou        boolean;
BEGIN
  insert_string = 'INSERT INTO ' || nome_tabela || ' VALUES ( ';
  passou = FALSE;

  FOREACH i IN ARRAY args
    LOOP
      IF NOT passou THEN
        IF i ILIKE 'default' THEN
          insert_string := insert_string || i ;
          passou = TRUE;
        ELSE
          insert_string := insert_string || '''' || i || '''';
          passou = TRUE;
        END IF;
      ELSE
        IF i ILIKE 'default' THEN
          insert_string := insert_string || ' , ' || i || '' ;
        ELSE
          insert_string := insert_string || ' , ''' || i || '''' ;
        END IF;
      END IF;
    END LOOP;

  insert_string := insert_string || ' )';
  EXECUTE insert_string;
END;

$$ LANGUAGE plpgsql;