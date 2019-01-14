
CREATE TRIGGER pedido_trigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON pedido
  FOR EACH ROW
  EXECUTE PROCEDURE pedido_procedure();

CREATE TRIGGER item_pedido_trigger
  BEFORE INSERT OR UPDATE OR DELETE
  ON item_pedido
  FOR EACH ROW
  EXECUTE PROCEDURE item_pedido_procedure();