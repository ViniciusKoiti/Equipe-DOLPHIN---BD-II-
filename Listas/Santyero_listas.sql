
-- LISTA 1

/* 
01- Escreva quatro triggers de sintaxe - a trigger não precisa ter funcionalidade, basta não dar erro de sintaxe. Use variável global para testar.
- Faça uma declarando variáveis e com select into; 
- Faça a segunda com uma estrutura de decisão; 
- Faça a terceira que gere erro, impedindo a ação;
- Faça a quarta que utilize a variável new e old - tente diferenciar. 
*/

    DELIMITER //
    CREATE TRIGGER trigger1 BEFORE INSERT ON `tabela1` FOR EACH ROW
    BEGIN
        DECLARE variavel1 INT;
        SELECT * INTO variavel1 FROM tabela2 WHERE id = NEW.id;
    END
    //
    DELIMITER ;

-- ========================================================================
    DELIMITER //
    CREATE TRIGGER venda_cliente_ativo BEFORE UPDATE ON venda FOR EACH ROW
        BEGIN
            DECLARE cliente_ativo CHAR(1);
            SELECT cliente.ativo INTO cliente_ativo FROM cliente WHERE cliente.id = NEW.cliente_id;
            IF cliente_ativo = "N" THEN
                SIGNAL sqlstate '45000' SET message_text = "Cliente inativo";
            END IF;
        END;
    //
    DELIMITER;

-- ========================================================================

    DELIMITER //
    CREATE TRIGGER venda_cliente_ativo AFTER INSERT ON venda FOR EACH ROW
        BEGIN
            DECLARE MSG VARCHAR(10);
            SET msg = "DEU RUIM";
            SIGNAL SQLSTATE '45000' set MESSAGE_TEXT = msg;
        END;
    //
    DELIMITER ;


-- =========================================================================

    DELIMITER //
    CREATE TRIGGER verificaID AFTER UPDATE ON venda FOR EACH ROW
        BEGIN    
            IF NEW.cliente_id <> OLD.cliente_id THEN
                SIGNAL SQLSTATE '45000' set MESSAGE_TEXT = "Cliente não pode ser alterado";
            END IF;
        END;
    //
    DELIMITER ;

/*
02- Uma trigger que tem a função adicionar a entrada de produtos no estoque deve ser associado para qual:
•	Tabela?
•	Tempo?
•	Evento?
•	Precisa de variáveis? Quais?
•	Implemente a trigger. 
*/

-- Temos diversas possibilidades de uso para adicinar estoque ao produto, entendi estoque == entrada
    -- Uma das opções é
    -- Tabela: item_venda
    -- Tempo: na exclusão do item_venda
    -- Evento: DELETE
    -- Variaveis: produto_id, quantidade

    DELIMITER //
    CREATE TRIGGER item_venda_delete AFTER DELETE ON item_venda FOR EACH ROW
        BEGIN
            UPDATE produto SET estoque = estoque + OLD.quantidade WHERE produto.id = OLD.produto_id;
        END;
    //
    DELIMITER ;


/* 
03- Uma trigger que tem a função criar um registro de auditoria quando um pagamento e recebimento for alterada deve ser associado para qual(is):
•	Tabela(s)?
•	Tempo?
•	Evento?
•	Implemente a trigger (pode criar a tabela de auditoria)
*/


-- Visto que não temos nenhuma tabela de pagamento e recebimento torna-se dificil criar uma trigger para isso
-- Uma das opções é
-- Toda vez que alterar o valor do produto, toda vez que alterar o valor da venda OBS: Não existe atualmente, deve optar por acionar a função de auditoria
-- Tabela: produto e item_venda

CREATE TABLE auditoria(
    id INT NOT NULL AUTO_INCREMENT
    ,data_auditoria DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ,descricao VARCHAR(100) NOT NULL
    ,CONSTRAINT pk_auditoria PRIMARY KEY (id)
);


DELIMITER //
CREATE TRIGGER auditoria_produto_update AFTER UPDATE ON produto FOR EACH ROW
    BEGIN
        DECLARE descricaoCompleta VARCHAR(100);
        SET descricaoCompleta = CONCAT("Produto ", OLD.nome, " teve o valor alterado de ", OLD.preco_venda, " para ", NEW.preco_venda);
        INSERT INTO auditoria (descricao) VALUES (descricaoCompleta);
    END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER auditoria_item_venda_update AFTER UPDATE ON item_venda FOR EACH ROW
    BEGIN
        DECLARE descricaoCompleta VARCHAR(100);
        SET descricaoCompleta = CONCAT("Ite mvenda ", OLD.id, " teve o valor alterado de ", OLD.preco_unidade, " para ", NEW.preco_unidade);
        INSERT INTO auditoria (descricao) VALUES (descricaoCompleta);
    END;
//
DELIMITER ;


/*
04- Uma trigger que tem a função impedir a venda de um produto inferior a 50% do preço de venda deve ser associado para qual:
•	Tabela?
•	Tempo?
•	Evento?
•	Implemente a trigger
*/

-- Mais uma vez não temos nenhuma tabela de pagamento e recebimento que altere os valor dos produtos, mas no item_venda temos a opção de toda vez que adicionar o valor ser possivel adicior um valor diferente
-- desta forma temos a opção:
-- Tabela: item_venda
-- Tempo: AFTER da inserção do item_venda
-- Evento: INSERT
-- Variaveis: preco_minimo, preco_produto_base


DELIMITER //
CREATE TRIGGER item_venda_insert AFTER INSERT ON item_venda FOR EACH ROW
    BEGIN
        DECLARE preco_minimo DECIMAL(10,2);
        DECLARE preco_produto_base DECIMAL(10,2);
        SELECT preco_venda INTO preco_produto_base FROM produto WHERE produto.id = NEW.produto_id; 
        SET preco_minimo = preco_produto_base * 0.5;
        IF NEW.preco_unidade < preco_minimo THEN
            SIGNAL SQLSTATE '45000' set MESSAGE_TEXT = "Preço inferior a 50% do valor de venda";
        END IF;
    END;
//
DELIMITER;



/* 
05- Este é para testar a sintaxe - tente implementar sem o script
Uma trigger que tem a função de gerar o RA automático na tabela ALUNO deve ser associada para qual
•	Tabela?
•	Tempo?
•	Evento?
•	Precisa de variáveis? Quais?
•	Implemente a trigger - RA igual a concatenção do ano corrente, código do curso e o id do cadastro do aluno. 
*/

-- Tabela: aluno
-- Tempo: BEFORE da inserção do aluno
-- Evento: INSERT
-- Variaveis: ano_corrente, codigo_curso, id_aluno, novo_ra

DELIMITER //
CREATE TRIGGER aluno_insert BEFORE INSERT ON aluno FOR EACH ROW
    BEGIN
        DECLARE ano_corrente INT;
        DECLARE codigo_curso INT;
        DECLARE id_aluno INT;
        DECLARE novo_ra VARCHAR(255);
        SET ano_corrente = YEAR(CURRENT_TIMESTAMP);
        SET codigo_curso = NEW.curso_id;
        SET id_aluno = NEW.id;
        SET novo_ra = CONCAT(ano_corrente, codigo_curso, id_aluno);
        UPDATE aluno SET ra = novo_ra WHERE aluno.id = NEW.id;
    END;
//
DELIMITER ;


06- De acordo com o seu projeto de banco de dados, pense em pelo menos 3 trigger úteis. Discuta com os seus colegas em relação a relevância e implemente-as.


-- Verifica se já bebeu de mais
DELIMITER //
CREATE TRIGGER check_max_hydration AFTER INSERT ON hydric_consumption FOR EACH ROW
BEGIN
    DECLARE metric INT DEFAULT 0;
    select (um.metric * 35) INTO metric
    from user_metric um 
    where um.user_id = NEW.user_id 
        and um.metric_type = 10 
        and DATE_FORMAT(um.date_ref, '%Y-%m-%d') = DATE_FORMAT(NEW.created_at, '%Y-%m-%d');
    DECLARE complet_hydric INT(1);
    SELECT SUM(qtd_consumption) > metric INTO complet_hydric
    FROM hydric_consumption hc
    WHERE hc.user_id = NEW.user_id
        AND DATE_FORMAT(hc.created_at, '%Y-%m-%d') = DATE_FORMAT(NEW.created_at, '%Y-%m-%d');
    IF complet_hydric THEN
        INSERT INTO notification (user_id, message, created_at, updated_at) VALUES (NEW.user_id, 'Você já consumiu a quantidade máxima de água para hoje', NOW(), NOW());
    END IF;
END;
// DELIMITER ;

-- Verifica se não praticou a mais de 3 dias
DELIMITER //
CREATE TRIGGER check_access_log AFTER INSERT ON access_log FOR EACH ROW
BEGIN
    DECLARE last_access DATETIME;
    DECLARE last_practice DATETIME;
    DECLARE diff INT;
    SELECT MAX(al.created_at) INTO last_access
    FROM access_log al
    WHERE al.user_id = NEW.user_id;
    SELECT MAX(tra.created_at) INTO last_practice
    FROM training tra
    WHERE tra.user_id = NEW.user_id;
    SELECT DATEDIFF(last_access, last_practice) INTO diff;
    IF diff > 3 THEN
        INSERT INTO notification (user_id, message, created_at, updated_at) VALUES (NEW.user_id, 'Você não praticou exercícios há mais de 3 dias', NOW(), NOW());
    END IF;
END;
// DELIMITER ;


-- Verifica caso o usuario não tenha feito setado seu estado de espirito a mais de 3 dias
DELIMITER //
CREATE TRIGGER check_felling AFTER INSERT ON access_log FOR EACH ROW
BEGIN
    DECLARE last_felling DATETIME;
    DECLARE diff INT;
    SELECT MAX(uf.created_at) INTO last_felling
    FROM user_felling uf
    WHERE uf.user_id = NEW.user_id;
    SELECT DATEDIFF(NOW(), last_felling) INTO diff;
    IF diff > 3 THEN
        INSERT INTO notification (user_id, message, created_at, updated_at) VALUES (NEW.user_id, 'Você não alterou seu estado de espírito há mais de 3 dias, isso nos ajuda a gerar seus graficos para facilitar suas praticas', NOW(), NOW());
    END IF;
END;
// DELIMITER ;
