CREATE OR REPLACE FUNCTION pedido_procedure() RETURNS TRIGGER AS
$$
DECLARE
  i               item_pedido;
  instituicao_cod INTEGER;
BEGIN
  IF (tg_op = 'INSERT') THEN
    IF new.data_pedido IS NOT NULL THEN
      RAISE EXCEPTION 'A data do pedido é inserida pelo sistema';
    END IF;

    IF new.finalizado IS TRUE THEN
      RAISE EXCEPTION 'Um pedido não pode ser criado finalizado';
    END IF;

    IF new.entregue IS TRUE THEN
      RAISE EXCEPTION 'Um pedido não pode ser criado entregue';
    END IF;

    IF new.data_entrega IS NOT NULL THEN
      RAISE EXCEPTION 'Um pedido não pode ser criado com data de entrega';
    END IF;

    new.data_pedido = now();
    RETURN new;

  ELSEIF (tg_op = 'UPDATE') THEN
    IF new.cod_nutricionista != old.cod_nutricionista
      OR new.cod_fornecedor != old.cod_fornecedor
    THEN
      RAISE EXCEPTION 'O codigos não podem ser alterados';
    END IF;

    IF new.data_pedido != old.data_pedido THEN
      RAISE EXCEPTION 'A data do pedido não pode ser alterada';
    END IF;

    IF new.data_entrega IS NOT NULL THEN
      RAISE EXCEPTION 'A data de entrega é inserida pelo sistema';
    END IF;

    IF old.finalizado IS TRUE AND new.finalizado IS NOT TRUE THEN
      RAISE EXCEPTION 'Esse pedido está finalizado';
    END IF;

    IF old.entregue IS TRUE THEN
      RAISE EXCEPTION 'Esse pedido está entregue';
    END IF;

    IF new.finalizado IS NOT TRUE THEN

      IF new.entregue IS TRUE THEN
        RAISE EXCEPTION 'Um pedido não finalizado não pode ter sido entregue';
      END IF;

    ELSE
      IF NOT EXISTS(
          SELECT cod_pedido FROM item_pedido WHERE cod_pedido = old.cod_pedido) THEN
        RAISE EXCEPTION 'Um pedido sem itens não pode ser finalizado';
      END IF;

      IF new.entregue IS TRUE THEN
        new.data_entrega = now();
        SELECT cod_instituicao INTO instituicao_cod
        FROM nutricionista
        WHERE cod_nutricionista = old.cod_nutricionista;

        FOR i IN (SELECT * FROM item_pedido WHERE cod_pedido = old.cod_pedido)
          LOOP
            IF EXISTS(SELECT *
                      FROM estoque
                      WHERE cod_ingredinte = i.cod_ingredinte
                        AND cod_instituicao = instituicao_cod) THEN
              IF (SELECT tipo_quantidade
                  FROM ingrediente
                  WHERE cod_ingredinte = i.cod_ingredinte) = 'kilograma' THEN
                UPDATE estoque
                SET quantidade = quantidade + (i.quantidade * 1000)
                WHERE cod_ingredinte = i.cod_ingredinte
                  AND cod_instituicao = instituicao_cod;

              ELSE
                UPDATE estoque
                SET quantidade = quantidade + i.quantidade
                WHERE cod_ingredinte = i.cod_ingredinte
                  AND cod_instituicao = instituicao_cod;
              END IF;

            ELSE
              IF (SELECT tipo_quantidade
                  FROM ingrediente
                  WHERE cod_ingredinte = i.cod_ingredinte) = 'kilograma' THEN
                INSERT INTO estoque VALUES (instituicao_cod, i.cod_ingredinte, i.quantidade * 1000);

              ELSE
                INSERT INTO estoque VALUES (instituicao_cod, i.cod_ingredinte, i.quantidade);

              END IF;

            END IF;
          END LOOP;
      END IF;
    END IF;

    RETURN new;

  ELSEIF (tg_op = 'DELETE') THEN
    RETURN old;

  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION item_pedido_procedure() RETURNS TRIGGER AS
$$
DECLARE
  preco             float;
  pedido_finalizado boolean;
BEGIN

  IF (tg_op = 'INSERT') THEN
    SELECT finalizado INTO pedido_finalizado FROM pedido WHERE cod_pedido = new.cod_pedido;

    IF pedido_finalizado IS NOT NULL THEN

      IF (pedido_finalizado) THEN
        RAISE EXCEPTION 'Um pedido finalizado não pode receber mais itens / codigo do pedido: %', new.cod_pedido;
      END IF;

    ELSE
      RAISE EXCEPTION 'O pedido não existe';
    END IF;


    SELECT valor INTO preco
    FROM precos
           NATURAL JOIN ingrediente
    WHERE cod_ingredinte = new.cod_ingredinte
      AND cod_fornecedor IN (
      SELECT cod_fornecedor FROM pedido WHERE cod_pedido = new.cod_pedido LIMIT 1
    )
    ORDER BY valor
    LIMIT 1;

    IF preco IS NULL THEN
      RAISE EXCEPTION 'O fornecedor não tem esse ingrediente';
    END IF;

    IF new.valor_total IS NOT NULL THEN
      RAISE EXCEPTION 'O valor total é calculado pelo sistema';
    END IF;

    new.valor_total = preco * new.quantidade;

    RETURN new;

  ELSEIF (tg_op = 'UPDATE') THEN
    IF (SELECT finalizado FROM pedido WHERE cod_pedido = new.cod_pedido) THEN
      RAISE EXCEPTION 'Um pedido finalizado não pode ter seus itens modificados / codigo do pedido: %', old.cod_pedido;
    END IF;

    IF new.cod_pedido != old.cod_pedido
      OR new.cod_ingredinte != old.cod_ingredinte THEN
      RAISE EXCEPTION 'Os codigos não podem ser alterados';
    END IF;

    SELECT valor INTO preco
    FROM precos
           NATURAL JOIN ingrediente
    WHERE cod_ingredinte = new.cod_ingredinte
      AND cod_fornecedor IN (
      SELECT cod_fornecedor FROM pedido WHERE cod_pedido = new.cod_pedido LIMIT 1
    );

    IF new.valor_total != old.valor_total THEN
      IF preco * old.quantidade != new.valor_total THEN
        RAISE EXCEPTION 'O valor total é calculado pelo sistema';
      END IF;
    END IF;

    IF new.quantidade != old.quantidade THEN
      new.valor_total = preco * new.quantidade;
    END IF;

    RETURN new;

  ELSEIF (tg_op = 'DELETE') THEN
    IF (SELECT finalizado FROM pedido WHERE cod_pedido = old.cod_pedido) THEN
      RAISE EXCEPTION 'Um pedido finalizado não pode ter seus itens deletados / codigo do pedido: %', old.cod_pedido;
    END IF;

    RETURN old;

  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION precos_procedure() RETURNS TRIGGER AS
$$
BEGIN

  IF (tg_op = 'INSERT') THEN

    RETURN new;

  ELSEIF (tg_op = 'UPDATE') THEN
    IF new.cod_ingredinte != old.cod_ingredinte
      OR new.cod_fornecedor != old.cod_fornecedor THEN
      RAISE EXCEPTION 'Os codigos de fornecedor e ingrediente não podem ser alterados';
    END IF;

    IF new.valor != old.valor THEN
      UPDATE item_pedido
      SET valor_total = new.valor * quantidade
      WHERE cod_ingredinte = old.cod_ingredinte
        AND cod_pedido IN (SELECT cod_pedido
                           FROM pedido
                           WHERE finalizado = FALSE
                             AND cod_fornecedor = old.cod_fornecedor);

    END IF;

    RETURN new;

  ELSEIF (tg_op = 'DELETE') THEN

    DELETE
    FROM item_pedido
    WHERE cod_ingredinte = old.cod_ingredinte
      AND cod_pedido IN (SELECT cod_pedido
                         FROM pedido
                         WHERE finalizado = FALSE
                           AND cod_fornecedor = old.cod_fornecedor);

    RETURN old;

  END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION estoque_procedure() RETURNS TRIGGER AS
$$
BEGIN

  IF tg_op = 'UPDATE' THEN
    IF new.cod_ingredinte != old.cod_ingredinte OR
       new.cod_instituicao != old.cod_instituicao THEN
      RAISE EXCEPTION 'Os codigos de ingrediente e instituição não podem ser alterados';
    END IF;

    RETURN new;
  END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION oferta_procedure() RETURNS TRIGGER AS
$$
DECLARE
  i receita;
BEGIN

  IF (tg_op = 'INSERT') THEN
    IF NOT EXISTS(SELECT *
                  FROM cardapio
                         INNER JOIN nutricionista
                                    ON cardapio.cod_nutricionista = nutricionista.cod_nutricionista
                  WHERE cod_cardapio = new.cod_cardapio
                    AND cod_instituicao = new.cod_instituicao) THEN
      RAISE EXCEPTION 'Esse cardapio não existe';
    END IF;

    IF new.data_oferta <= now() THEN
      RAISE EXCEPTION 'A data da oferta deve ser maior que a data atual';
    END IF;
    RETURN new;

  ELSEIF (tg_op = 'UPDATE') THEN

    IF old.finalizada THEN
      RAISE EXCEPTION 'Uma oferta finalizada não pode ser alterada';
    END IF;

    IF new.cod_instituicao != old.cod_instituicao
      OR new.cod_cardapio != old.cod_cardapio THEN
      RAISE EXCEPTION 'Os codigos de instituição e cardapio não podem ser alterados';
    END IF;

    IF new.data_oferta <= now() THEN
      RAISE EXCEPTION 'A data da oferta deve ser maior que a data atual';
    END IF;

    IF new.finalizada THEN

      IF EXISTS(SELECT *
                FROM cardapio
                       LEFT JOIN prato_cardapio
                                 ON cardapio.cod_cardapio = prato_cardapio.cod_cardapio
                       LEFT JOIN receita
                                 ON prato_cardapio.cod_prato = receita.cod_prato
                WHERE cardapio.cod_cardapio = old.cod_cardapio
                  AND (receita.cod_prato IS NULL OR prato_cardapio.cod_cardapio IS NULL)) THEN
        RAISE EXCEPTION 'O cardapio da oferta não contem pratos ou um dos pratos não contem a receita';
      ELSE

        FOR i IN SELECT *
                 FROM receita
                 WHERE cod_prato IN (SELECT cod_prato FROM prato_cardapio WHERE cod_cardapio = old.cod_cardapio)
          LOOP
            BEGIN

              IF EXISTS(SELECT *
                        FROM estoque
                        WHERE cod_instituicao = old.cod_instituicao
                          AND cod_ingredinte = i.cod_ingredinte) THEN
                IF i.tipo_quantidade = 'kilograma' THEN
                  UPDATE estoque
                  SET quantidade = quantidade - (i.quantidade * 1000 * old.quantidade_pessoas)
                  WHERE cod_instituicao = new.cod_instituicao
                    AND cod_ingredinte = i.cod_ingredinte;

                ELSE
                  UPDATE estoque
                  SET quantidade = quantidade - (i.quantidade * old.quantidade_pessoas)
                  WHERE cod_instituicao = new.cod_instituicao
                    AND cod_ingredinte = i.cod_ingredinte;

                END IF;

              ELSE
                RAISE EXCEPTION 'A instuição não tem esse ingrediente em estoque (%)',
                    (SELECT nome FROM ingrediente WHERE cod_ingredinte = i.cod_ingredinte);
              END IF;
            EXCEPTION
              WHEN check_violation THEN
                RAISE EXCEPTION 'Quantidade em estoque insuficiente (%)',
                    (SELECT nome FROM ingrediente WHERE cod_ingredinte = i.cod_ingredinte);

            END;
          END LOOP;

      END IF;

    END IF;

    RETURN new;

  ELSEIF (tg_op = 'DELETE') THEN

    IF old.finalizada THEN
      RAISE EXCEPTION 'Uma oferta finalizada não pode ser deletada';
    END IF;

    RETURN old;

  END IF;

END;
$$ LANGUAGE plpgsql;
