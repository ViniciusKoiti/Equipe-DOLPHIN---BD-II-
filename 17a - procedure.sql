01- Escreva quarto procedures de sintaxe - não precisa ter funcionalidade, basta não dar erro de sintaxe. Use variável global para testar.
- Faça uma declarando variáveis e com select into; 

DELIMITER // 
CREATE PROCEDURE VENDA_INATIVO(ID_CLIENTE INT)
BEGIN
	DECLARE CLIENTEATIVO CHAR(1);
    SELECT cliente.STATUS INTO CLIENTEATIVO FROM cliente WHERE cliente.ID = ID_CLIENTE;
	IF CLIENTEATIVO = "I" THEN
		SIGNAL sqlstate '45000' SET message_text = "CLINTE INATIVO";
    END IF;
END;
//
DELIMITER ;

CALL VENDA_INATIVO(2)


- Faça a segunda com uma estrutura de decisão; 
CREATE PROCEDURE VENDA_INATIVO(ID_CLIENTE INT)
BEGIN
	DECLARE CLIENTEATIVO CHAR(1);
    SELECT cliente.STATUS INTO CLIENTEATIVO FROM cliente WHERE cliente.ID = ID_CLIENTE;
	IF CLIENTEATIVO = "I" THEN
		SIGNAL sqlstate '45000' SET message_text = "CLINTE INATIVO";
    
    END IF;
END;
//
DELIMITER ;

- Faça a terceira que gere erro, impedindo a ação;
- Faça a quarta com if e else. 

CREATE PROCEDURE VENDA_INATIVO(ID_CLIENTE INT)
BEGIN
	DECLARE CLIENTEATIVO CHAR(1);
    SELECT cliente.STATUS INTO CLIENTEATIVO FROM cliente WHERE cliente.ID = ID_CLIENTE;
	IF CLIENTEATIVO = "I" THEN
		SIGNAL sqlstate '45000' SET message_text = "CLINTE INATIVO";
	ELSE
		SIGNAL sqlstate '45000' SET message_text = "CLINTE ATIVO";
    END IF;
END;
//
DELIMITER ;


CALL VENDA_INATIVO(1)


02 - Escreva uma procedure que registre a baixa de um produto e já atualize devidamente o estoque do produto. Antes das ações, verifique se o produto é ativo.


