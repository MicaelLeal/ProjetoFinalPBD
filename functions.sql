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
          insert_string := insert_string || i;
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

CREATE OR REPLACE FUNCTION
  add_ingrediente(_nome_prato varchar(50), _nome_ingrediente varchar(60), _quantidade int)
  RETURNS table
          (
            nome_ingrediente varchar,
            status_operacao  text
          ) AS
$$

DECLARE
  --     messages    --
  _sucesso                    text := 'Sucesso!';
  _atualizado                 text := 'Quantidade foi atualizada.';
  _existente                  text := 'Este ingrediente já havia sido adicionado.';
  _prato_nao_cadastrado       text := 'Prato não encontrado. Se liga nas dicas na aba de menssagens!';
  _ingred_nao_cadastrado      text := 'Ingrediente não encontrado. Se liga nas dicas na aba de menssagens!';
  _quantidade_invalida        text := 'Quantidade inválida. Corrija para um valor maior que 0.';

  --   dicas   --
  _prato_nao_cadastrado_dica  text :=
      E'\nDicas:\n'
      || E'Para cadastrar um prato use o comando:\n'
      || ' >> SELECT inserir(' || '''' || 'prato' || '''' || ', VARIADIC ' || ''''
      || '{DEFAULT, passe nome do prato aqui}' || '''' || ').'
      || E'\n Ou cadastre já com os ingredientes de preparo:\n'
      || ' >> SELECT * from criar_receita(' || '''' || 'nome do prato aqui' || '''' || ', ARRAY [' || ''''
      || 'ingrediente1' || '''' || ', ... , ' || '''' || 'ingredienteN' || '''' || '], ARRAY [' || ''''
      || 'qtd_ingrediente1' || '''' || ', ... , ' || '''' || 'qtd_ingredienteN' || '''' || '])';
  _ingred_nao_cadastrado_dica text :=
      E'\nDica:\n'
      || E'Para cadastrar o ingrediente use o comando:\n'
      || ' >> SELECT inserir(' || '''' || 'ingrediente' || '''' || ', VARIADIC ' || '''' || '{DEFAULT, ' || ''''
      || 'nome do ingrediente aqui' || '''' || ', ' || '''' || 'tipo_quantidade aqui' || '''' || '). '
      || E'\nVerifique os tipo_quantidade aceitos com:\n'
      || ' >> SELECT unnest (enum_range(NULL::tipo_qtd))';

  --   variaveis --
  _cod_prato                  int;
  _cod_ingrediente            int;
  _tipo_quantidade            tipo_qtd;

BEGIN
  SELECT cod_prato INTO _cod_prato FROM prato WHERE nome ILIKE _nome_prato;
  SELECT cod_ingredinte INTO _cod_ingrediente FROM ingrediente WHERE nome ILIKE _nome_ingrediente;

  IF _cod_prato ISNULL THEN
    RAISE NOTICE '%', _prato_nao_cadastrado_dica;
    RETURN QUERY SELECT _nome_ingrediente, _prato_nao_cadastrado;
    RETURN;
  END IF;

  IF _cod_ingrediente ISNULL THEN
    RAISE NOTICE '%', _ingred_nao_cadastrado_dica;
    RETURN QUERY SELECT _nome_ingrediente, _ingred_nao_cadastrado;
    RETURN;
  END IF;

  SELECT tipo_quantidade INTO _tipo_quantidade FROM ingrediente WHERE cod_ingredinte = _cod_ingrediente;

  INSERT INTO receita VALUES (_cod_prato, _cod_ingrediente, _quantidade, _tipo_quantidade);

  RETURN QUERY SELECT _nome_ingrediente, _sucesso;
  RETURN;

EXCEPTION
  WHEN CHECK_VIOLATION THEN
    RETURN QUERY SELECT _nome_ingrediente, _quantidade_invalida;
    RETURN;
  WHEN UNIQUE_VIOLATION THEN
    IF _quantidade <> (SELECT quantidade
                       FROM receita
                       WHERE cod_prato = _cod_prato
                         AND cod_ingredinte = _cod_ingrediente) THEN
      UPDATE receita
      SET quantidade = _quantidade
      WHERE cod_prato = _cod_prato
        AND cod_ingredinte = _cod_ingrediente;
      RETURN QUERY SELECT _nome_ingrediente, _atualizado;
      RETURN;

    END IF;
    RETURN QUERY SELECT _nome_ingrediente, _existente;
    RETURN;

END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
  criar_receita(_nome_prato varchar(50), _ingredientes text[], _quantidade int[])
  RETURNS table
          (
            nome_ingrediente varchar,
            status_operacao  text
          ) AS
$$

DECLARE

  --   messagens   --
  _lista_vazia           text    := 'Você não passou os ingredientes. Pelamor de Deux.';
  _diferentes_lengths    text    := 'A lista de quantidades não confere com a de inguredientes.';
  _prato_nao_cadastrado  text    := 'Prato não econtrado. Um novo prato com o nome passado foi criado.';
  _ingred_nao_cadastrado text    := 'Ingrediente não encontrado. Se liga nas dicas na aba de menssagens!';

  --   variaveis   --
  _i                     int;
  _cod_prato             int;
  _nome_ingrediente      varchar;
  _is_dica_enviada       boolean := FALSE;

BEGIN
  SELECT array_upper(_ingredientes, 1) INTO _i;

  IF (_i <> array_upper(_quantidade, 1)) THEN
    RAISE EXCEPTION '%', _diferentes_lengths;
  END IF;

  IF (_i ISNULL) OR (_i <= 0) THEN
    RAISE EXCEPTION '%', _lista_vazia;
  END IF;

  SELECT cod_prato INTO _cod_prato FROM prato WHERE nome ILIKE _nome_prato;

  IF _cod_prato ISNULL THEN
    INSERT INTO prato VALUES (DEFAULT, _nome_prato) RETURNING cod_prato INTO _cod_prato;
    RAISE NOTICE '%', _prato_nao_cadastrado;
  END IF;

  FOR i IN 1.._i
    LOOP
      _nome_ingrediente := _ingredientes [ i];

      IF exists(SELECT * FROM ingrediente WHERE nome ILIKE _nome_ingrediente) THEN
        RETURN QUERY SELECT * FROM add_ingrediente(_nome_prato, _ingredientes [ i], _quantidade [ i]);
      ELSIF NOT _is_dica_enviada THEN
        _is_dica_enviada := TRUE;
        RETURN QUERY SELECT * FROM add_ingrediente(_nome_prato, _ingredientes [ i], _quantidade [ i]);
      ELSE
        RETURN QUERY SELECT _nome_ingrediente, _ingred_nao_cadastrado;
      END IF;

    END LOOP;
  RETURN;

END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION novo_pedido(nome_nutricionista varchar,
                                       nomes_ingredientes varchar[],
                                       qtds_ingredientes float[])
  RETURNS VOID AS
$$
DECLARE
  nome_ingrediente   varchar;
  qtd_ingrediente    int;
  _cod_ingrediente   int;
  _cod_nutricionista int;
  _cod_fornecedor    int;
  _cod_pedido        int;
  i                  int;
BEGIN
  IF array_length(nomes_ingredientes, 1) != array_length(qtds_ingredientes, 1)
  THEN
    RAISE EXCEPTION 'A quantidade de ingrediente e quantidades devem ser iguais';
  END IF;

  SELECT cod_nutricionista INTO _cod_nutricionista FROM nutricionista WHERE nome ILIKE nome_nutricionista;

  IF _cod_nutricionista IS NULL
  THEN
    RAISE NOTICE 'O nutricionista %s não existe', nome_nutricionista;
  END IF;

  FOR i IN 1..array_length(nomes_ingredientes, 1)
    LOOP
      nome_ingrediente := nomes_ingredientes [ i];
      qtd_ingrediente := qtds_ingredientes [ i];

      SELECT cod_ingredinte INTO _cod_ingrediente
      FROM ingrediente
      WHERE nome ILIKE nome_ingrediente;

      IF _cod_ingrediente IS NOT NULL
      THEN
        SELECT cod_fornecedor INTO _cod_fornecedor
        FROM precos
        WHERE cod_ingredinte = _cod_ingrediente
        ORDER BY valor
        LIMIT 1;

        IF _cod_fornecedor IS NOT NULL
        THEN
          SELECT cod_pedido INTO _cod_pedido
          FROM pedido
          WHERE finalizado = FALSE
            AND cod_fornecedor = _cod_fornecedor
          ORDER BY data_pedido DESC
          LIMIT 1;

          IF _cod_pedido IS NOT NULL
          THEN

            IF exists(SELECT *
                      FROM item_pedido
                      WHERE cod_pedido = _cod_pedido
                        AND cod_ingredinte = _cod_ingrediente)
            THEN
              UPDATE item_pedido
              SET quantidade = quantidade + qtd_ingrediente
              WHERE cod_pedido = _cod_pedido
                AND cod_ingredinte = _cod_ingrediente;

              RAISE NOTICE 'Quantidade do ingrediente (%) incrementada em um pedido em aberto (%)',
                nome_ingrediente, _cod_pedido;

            ELSE
              INSERT INTO item_pedido
              VALUES (_cod_pedido, _cod_ingrediente, qtd_ingrediente);

              RAISE NOTICE 'Ingrediente (%) adicionado a um pedido em aberto (%)',
                nome_ingrediente, _cod_pedido;

            END IF;

          ELSE

            INSERT INTO pedido
            VALUES (DEFAULT, _cod_nutricionista, _cod_fornecedor);

            SELECT cod_pedido INTO _cod_pedido
            FROM pedido
            WHERE finalizado = FALSE
              AND cod_fornecedor = _cod_fornecedor
            ORDER BY data_pedido DESC
            LIMIT 1;

            INSERT INTO item_pedido
            VALUES (_cod_pedido, _cod_ingrediente, qtd_ingrediente);

            RAISE NOTICE 'Novo pedido criado (%)', _cod_pedido;
            RAISE NOTICE 'Ingrediente (%) adicionado ao pedido criado', nome_ingrediente;

          END IF;

        ELSE
          RAISE NOTICE 'O ingrediente % não tem nenhum fornecedor', nome_ingrediente;
        END IF;

      ELSE
        RAISE NOTICE 'O ingrediente % não existe', nome_ingrediente;
      END IF;

    END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  add_prato_in_cardapio(_desc_cardapio varchar, _nome_nutricionista varchar, _nome_prato varchar)
  RETURNS table
          (
            nome_prato varchar,
            status_operacao text
          ) AS
$$
DECLARE
--   messages  --
  _status_ok text := 'Prato inserido ao cardápio com sucesso!';
  _status_inexistente text := 'Prato passado não existe. Corrija o valor ou crie o prato.';
  _status_ja_adicionado text := 'Este prato já havia sido adicionado a este cardápio';

  _cod_cardapio      int;
  _cod_nutricionista int;
  _cod_prato         int;

BEGIN

  SELECT cod_cardapio INTO _cod_cardapio FROM cardapio WHERE descricao ILIKE _desc_cardapio;
  IF _cod_cardapio ISNULL THEN
    RAISE EXCEPTION 'Cardapio não existe. Corrija o valor ou cadastre o cardapio';
  END IF;

  SELECT cod_nutricionista INTO _cod_nutricionista FROM nutricionista WHERE nome ILIKE _nome_nutricionista;
  IF _cod_nutricionista ISNULL THEN
    RAISE EXCEPTION 'Nutricionista *%* não existe. corrija o valor', _nome_nutricionista;
  END IF;

  IF NOT exists(
      SELECT * FROM cardapio WHERE cod_cardapio = _cod_cardapio AND cod_nutricionista = _cod_nutricionista)
  THEN
    RAISE EXCEPTION 'Esta nutricionista não tem permissão para alterar este cardápio.';
  END IF;

  SELECT cod_prato INTO _cod_prato FROM prato WHERE nome ILIKE _nome_prato;
  IF _cod_prato ISNULL THEN
    RETURN QUERY SELECT _nome_prato, _status_inexistente;
    RETURN;
  END IF;

  INSERT INTO prato_cardapio VALUES (_cod_cardapio, _cod_prato);
  RETURN QUERY SELECT _nome_prato, _status_ok;
  RETURN;

EXCEPTION
  WHEN UNIQUE_VIOLATION THEN
    RETURN QUERY SELECT _nome_prato, _status_ja_adicionado;
    RETURN;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  criar_cardapio(_desc_cardapio varchar, _nome_nutricionista varchar, _pratos text[])
  RETURNS table
          (
            nome_prato varchar,
            status_operacao text
          ) AS
$$
DECLARE
  _nome_prato varchar;

  _cod_cardapio int;
  _cod_nutricionista int;
  _cod_prato int;

BEGIN
  SELECT cod_nutricionista into _cod_nutricionista FROM nutricionista where nome ILIKE _nome_nutricionista;
  if _cod_nutricionista ISNULL THEN
    RAISE EXCEPTION 'Nutricionista *%* não existe.', _nome_nutricionista;
  END IF;

  if (array_length(_pratos, 1) <= 0) or (array_length(_pratos, 1) ISNULL) THEN
    RAISE NOTICE '% ', array_length(_pratos, 1);
    RAISE EXCEPTION 'Lista de pratos vazia, corija o parametro';
  END IF;

  if not exists(SELECT * from cardapio WHERE descricao = _desc_cardapio) THEN
    INSERT INTO cardapio VALUES (DEFAULT, _cod_nutricionista, _desc_cardapio);
    RAISE NOTICE 'Cardapio de descricao *%* não encontrado. Criamos ele para você.', _desc_cardapio;
  END IF;

  FOREACH _nome_prato IN ARRAY _pratos LOOP
    RETURN QUERY SELECT * FROM add_prato_in_cardapio(_desc_cardapio, _nome_nutricionista, _nome_prato);
  END LOOP;

  RETURN ;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  ofertar(_instituicao varchar, _desc_cardapio varchar, _data_oferta date, _qtd_pessoas int)
  RETURNS void AS
$$
DECLARE
  _cod_instituicao int;
  _cod_cardapio int;

BEGIN

  SELECT cod_instituicao into _cod_instituicao from instituicao WHERE nome ILIKE _instituicao;

  if _cod_instituicao ISNULL THEN
    raise EXCEPTION 'Instituição *%* não encontrada, corrija o valor.', _instituicao;
  END IF;

  SELECT cod_cardapio INTO _cod_cardapio from cardapio where descricao ilike _desc_cardapio;
  if _cod_cardapio ISNULL THEN
    RAISE EXCEPTION 'Cardápio de descrição *%* não encontrado. Corrija o valor ou crie o cardápio', _desc_cardapio;
  END IF;

  INSERT INTO oferta VALUES (_cod_instituicao, _cod_cardapio, _data_oferta, _qtd_pessoas, DEFAULT);
  RAISE NOTICE 'SUCESSO!';

EXCEPTION
  WHEN UNIQUE_VIOLATION THEN
    UPDATE oferta
    SET cod_cardapio = _cod_cardapio
    WHERE cod_instituicao = _cod_instituicao
      AND data_oferta = _data_oferta;
    RAISE NOTICE 'Oferta para essa data já foi cadastrada.';

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
  finalizar_oferta(_instituicao varchar, _data_oferta date)
  RETURNS void AS
$$
DECLARE
  _cod_instituicao int;

BEGIN
  SELECT cod_instituicao INTO _cod_instituicao FROM instituicao WHERE nome ILIKE _instituicao;
  IF _cod_instituicao ISNULL THEN
    RAISE EXCEPTION 'Isntituição *%* não encontrada.', _instituicao;
  END IF;

  IF NOT exists(SELECT * FROM oferta WHERE cod_instituicao = _cod_instituicao AND data_oferta = _data_oferta)
  THEN
    RAISE EXCEPTION 'Não foi encontrada uma oferta com essa data para essa instituicao.';
  END IF;

  UPDATE oferta SET finalizada = TRUE WHERE cod_instituicao = _cod_instituicao AND data_oferta = _data_oferta;
  RAISE NOTICE 'SUCESSO!';

END;
$$ LANGUAGE plpgsql;

