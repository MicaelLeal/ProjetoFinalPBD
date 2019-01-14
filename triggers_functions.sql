CREATE OR REPLACE FUNCTION pedido_procedure() RETURNS TRIGGER AS
$$
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
    IF new.cod_pedido != old.cod_pedido
      OR new.cod_nutricionista != old.cod_nutricionista
      OR new.cod_fornecedor != old.cod_fornecedor
    THEN
      RAISE EXCEPTION 'O codigos não podem ser alterados';
    end if;

    IF new.data_pedido != old.data_pedido THEN
      RAISE EXCEPTION 'A data do pedido não pode ser alterada';
    end if;

    IF old.finalizado IS TRUE AND new.finalizado IS NOT TRUE THEN
      RAISE EXCEPTION 'Esse pedido está finalizado';
    END IF;

    IF old.entregue IS TRUE THEN
      RAISE EXCEPTION 'Esse pedido está entregue';
    END IF;

    IF new.finalizado IS NOT TRUE THEN

      IF new.entregue IS TRUE OR new.data_entrega IS NOT NULL THEN
        RAISE EXCEPTION 'Um pedido não finalizado não pode ter sido entregue';
      END IF;

    ELSE
      IF NOT EXISTS(
          SELECT cod_pedido FROM item_pedido WHERE cod_pedido = old.cod_pedido) THEN
        RAISE EXCEPTION 'Um pedido sem itens não pode ser finalizado';
      END IF;

      IF new.entregue IS TRUE THEN
        IF new.data_entrega IS NULL THEN
          RAISE EXCEPTION 'A data de entrega é necessaria';
        END IF;
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
  preco float;
BEGIN

  IF (tg_op = 'INSERT') THEN
    IF (SELECT finalizado FROM pedido WHERE cod_pedido = new.cod_pedido) THEN
      RAISE EXCEPTION 'Um pedido finalizado não pode receber mais itens / codigo do pedido: %', new.cod_pedido;
    END IF;

    SELECT valor INTO preco
    FROM precos NATURAL JOIN ingrediente
    WHERE cod_ingredinte = new.cod_ingredinte
      AND cod_fornecedor IN (
      SELECT cod_fornecedor FROM pedido WHERE cod_pedido = new.cod_pedido LIMIT 1
    )
    ORDER BY valor
    LIMIT 1;

    IF preco IS NULL THEN
      RAISE EXCEPTION 'O pedido não existe ou o fornecedor não tem esse ingrediente';
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

    IF new.quantidade != old.quantidade THEN
      SELECT valor INTO preco
      FROM precos NATURAL JOIN ingrediente
      WHERE cod_ingredinte = new.cod_ingredinte
        AND cod_fornecedor IN (
        SELECT cod_fornecedor FROM pedido WHERE cod_pedido = new.cod_pedido LIMIT 1
      );
      new.valor_total = preco * new.quantidade;
    END IF;

    IF new.valor_total != old.valor_total THEN
      SELECT valor INTO preco
      FROM precos NATURAL JOIN ingrediente
      WHERE cod_ingredinte = new.cod_ingredinte
        AND cod_fornecedor IN (
        SELECT cod_fornecedor FROM pedido WHERE cod_pedido = new.cod_pedido LIMIT 1
      );
      IF NOT new.valor_total = preco * new.quantidade THEN
        RAISE EXCEPTION 'Valor total invalido';
      END IF;
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
