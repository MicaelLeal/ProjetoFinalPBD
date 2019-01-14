
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
