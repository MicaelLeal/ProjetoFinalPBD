
DROP TRIGGER IF EXISTS pedido_trigger ON pedido;
CREATE TRIGGER pedido_trigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON pedido
  FOR EACH ROW
  EXECUTE PROCEDURE pedido_procedure();

DROP TRIGGER IF EXISTS item_pedido_trigger ON item_pedido;
CREATE TRIGGER item_pedido_trigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON item_pedido
  FOR EACH ROW
  EXECUTE PROCEDURE item_pedido_procedure();

DROP TRIGGER IF EXISTS precos_trigger ON precos;
CREATE TRIGGER precos_trigger
  AFTER INSERT OR UPDATE OR DELETE
  ON precos
  FOR EACH ROW
  EXECUTE PROCEDURE precos_procedure();

DROP TRIGGER IF EXISTS estoque_trigger ON estoque;
CREATE TRIGGER estoque_trigger
  AFTER UPDATE
  ON estoque
  FOR EACH ROW
  EXECUTE PROCEDURE estoque_procedure();

DROP TRIGGER IF EXISTS oferta_trigger ON oferta;
CREATE TRIGGER oferta_trigger
  AFTER INSERT OR UPDATE OR DELETE
  ON oferta
  FOR EACH ROW
  EXECUTE PROCEDURE oferta_procedure();