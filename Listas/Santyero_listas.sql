
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



-- LISTA 2

/*
01- Escreva quarto procedures de sintaxe - não precisa ter funcionalidade, basta não dar erro de sintaxe. Use variável global para testar.
- Faça uma declarando variáveis e com select into; 
- Faça a segunda com uma estrutura de decisão; 
- Faça a terceira que gere erro, impedindo a ação;
- Faça a quarta com if e else. 
*/

DELIMITER //
CREATE PROCEDURE procedure_basicas()
BEGIN
DECLARE var1 INT;
SELECT COUNT(*) INTO var1 FROM CLIENTE;
// DELIMITER ;

DELIMITER //
CREATE PROCEDURE procedure_decisao(valor1 INT, prod_id INT)
BEGIN
    DECLARE var2 INT;
    SELECT prod.valor_unidade INTO var2 FROM produto prod WHERE prod.id = prod_id;
    IF valor1 > var2 THEN
    BEGIN
        UPDATE produto SET valor_unidade = valor1 WHERE produto.id = prod_id;
    END;
END;
// DELIMITER ;

DELIMITER //
CREATE PROCEDURE procedure_erro()
BEGIN
    DECLARE qnt_cliente_inativo INT;
    SELECT COUNT(*) INTO qnt_cliente_inativo FROM CLIENTE WHERE ativo = 'N';
    IF qnt_cliente_inativo > 0 THEN
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NÃO EXISTE CLIENTE INATIVO';
    END;
    END IF;
END;
// DELIMITER ;

DELIMITER //
DELIMITER //
CREATE PROCEDURE procedure_erro()
BEGIN
    DECLARE qnt_cliente_inativo INT;
    SELECT COUNT(*) INTO qnt_cliente_inativo FROM CLIENTE WHERE ativo = 'N';
    IF qnt_cliente_inativo > 0 THEN
    BEGIN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'NÃO EXISTE CLIENTE INATIVO';
    END;
    ELSE
    BEGIN
        SIGNAL SQLSTATE '00000' SET MESSAGE_TEXT = 'EXISTE CLIENTE INATIVO';
    END;
    END IF;
END;
// DELIMITER ;




/*
02 - Escreva uma procedure que registre a baixa de um produto e já atualize devidamente o estoque do produto. Antes das ações, verifique se o produto é ativo.
*/

DELIMITER //
CREATE PROCEDURE baixa_produto(id_produto INT, quantidade_prod INT, id_funcionario INT)
BEGIN
    DECLARE ativo CHAR;
    SELECT produto.STATUS INTO ativo FROM produto WHERE produto.id = id_produto;
    IF estoque >= quantidade_prod and ativo = 'S' THEN
		BEGIN
        INSERT INTO BAIXA_PRODUTO SET 
            quantidade = quantidade_prod, 
            FUNCIONARIO_ID = id_funcionario, 
            PRODUTO_ID = id_produto, 
            DATA_VENCIMENTO = now();
        UPDATE produto SET estoque = (estoque - quantidade_prod) WHERE produto.id = id_produto;
        END;
    END IF;
END; //
DELIMITER ;

/*
03 - Escreva uma procedure que altere o preço de um produto vendido (venda já realizada - necessário verificar a existência da venda). Não permita altearções abusivas - preço de venda abaixo do preço de custo. É possível implementar esta funcionalidade sem a procedure? Se sim, indique como, bem como as vantagens e desvantagens.
*/
DELIMITER //
CREATE PROCEDURE alterar_preco_venda(id_produto INT, preco_venda DECIMAL(8,2))
BEGIN
    DECLARE preco_custo DECIMAL(8,2);
    SELECT produto.preco_custo INTO preco_custo FROM produto WHERE produto.id = id_produto;
    IF preco_venda > preco_custo THEN
    BEGIN
        UPDATE produto SET preco_venda = preco_venda WHERE produto.id = id_produto;
    END;
    END IF;
END; //
DELIMITER ;


/* Com a utilização de uma procedure, vai gerar uma maior seguraça dos dados, pois todos terao de passar por validações antes de serem inseridos no banco de dados.
Podemos usar um simples insert que no fim das contas gerara o mesmo impacto nas alterações, mas dará uma melhor liberdade de imoplementações
*/

/*
04 - Escreva uma procedure que registre vendas de produtos e já defina o total da venda. É possível implementar a mesma funcionalidade por meio da trigger? Qual seria a diferença?
*/

DELIMITER //
CREATE PROCEDURE insercao_item_venda(id_venda INT, id_produto INT, quantidade INT, preco_venda DECIMAL(8,2))
BEGIN
    DECLARE ativo CHAR;
    DECLARE estoque INT;
    SELECT produto.STATUS INTO ativo FROM produto WHERE produto.id = id_produto;
    SELECT produto.estoque INTO estoque FROM produto WHERE produto.id = id_produto;
    IF estoque >= quantidade and ativo = 'S' THEN
        BEGIN
        INSERT INTO ITEM_VENDA SET 
            quantidade = quantidade, 
            preco_venda = preco_venda, 
            VENDA_ID = id_venda, 
            PRODUTO_ID = id_produto;
        UPDATE produto SET estoque = (estoque - quantidade) WHERE produto.id = id_produto;
        UPDATE VENDA SET total = (total + (preco_venda * quantidade)) WHERE VENDA.id = id_venda;
        END;
    END IF;
END; 
// DELIMITER ;

/* 
É sim possivel implementar a mesma funcionalidade por meio de uma trigger, mas a diferença é que a procedure é executada quando chamada, enquanto
 a trigger é executada quando ocorre um evento especifico, como por exemplo, quando um dado é inserido em uma tabela, entretanto nesse caso teriamos de cirar o insert e 
 a partir dele chamar a trigguer para o update de estoque e venda total com new e old, o que tornaria o codigo mais complexo.
*/

/*
05- Para o controle de salário de funcionários de uma empresa e os respectivos adiantamentos (vales):
 - quais tabelas são necessárias?
*/

-- POR FAVOR ESPECIFIQUE MAIS SUAS ATIVIDADES, POIS NÃO CONSEGUI ENTENDER O QUE DEVE SER FEITO
/* 
    a diversas formas de calcular salarios, depende de muitas coisas, contrato, cargo, tempo de empresa, etc.
    entendendo que não devo alterar a base de dados e sendo o mais basico possivel podemos avaliar que com as tabelas existentes não sejá possivel o calculo, ao
    menos que o calculo sejá baseado em porcentagem da venda, mas não foi encontrado nada que especificace isso.
    se o objetivo fossem listar uma possiveis tabelas para um tipo:
    recomendaria inserir uma tabela de salarios com o id do funcionario, o valor do salario, o valor do vale, e o valor do adiantamento. 
*/


/*
06- De acordo com o seu projeto de banco de dados, pense em pelo menos 3 procedures úteis. Discuta com os seus colegas em relação a relevância e implemente-as.
*/

-- SETA O USUARIO PELA PRIMEIRA VEZ
DELIMITER / / 
CREATE PROCEDURE first_user_created(
    pName VARCHAR(255),
    pEmail VARCHAR(255),
    pPassword VARCHAR(255),
    pGender CHAR(1),
    pBirthdate DATE,
    pHeight INT(11),
    pWeight INT(11),
    pObjective VARCHAR(255)
) BEGIN
INSERT INTO
    user (
        name,
        email,
        password,
        gender,
        birthdate,
        height,
        weight,
        objective
    )
VALUES
    (
        pName,
        pEmail,
        pPassword,
        pGender,
        pBirthdate,
        pHeight,
        pWeight,
        pObjective
    );

INSERT INTO Notification (user_id, message)   VALUES (LAST_INSERT_ID(), 'Bem vindo ao Fytnez!');
END;

// DELIMITER;

-- SETA A METRICA E ADICIONA O ITEM NA TABELA DE METRICAS
DELIMITER // 
CREATE PROCEDURE insert_food_consumition_item(pFoodConsumptionId INT, pFoodId INT, pQtdConsumption INT,pUserId INT) 
BEGIN
    INSERT INTO food_consumption_item (food_consumption_id, food_id, qtd_consumption ) VALUES (pFoodConsumptionId, pFoodId, pQtdConsumption);
    INSERT INTO user_metric (user_id, user_metric_type_id, date_ref, metric ) VALUES (pUserId, 5, now(), pQtdConsumption);
END;
// DELIMITER;

-- PROCEDURE QUE SETA O TREINO E SE CASO OS SENTIMENTO DO USUARIO ESTIVEREM RUIM, ENVIA NOTIFICACAO DE MELHORAS
DELIMITER //
CREATE PROCEDURE insert_training(pUserId INT, pTrainingId INT, pTrainingTypeId INT, pTrainingLevelId INT)
BEGIN
    DECLARE felling INT;
    DECLARE msg VARCHAR(255);
    INSERT INTO training (user_id, training_id, training_type_id, training_level_id) VALUES (pUserId, pTrainingId, pTrainingTypeId, pTrainingLevelId);
    INSERT INTO user_metric (user_id, user_metric_type_id, date_ref, metric ) VALUES (pUserId, 6, pTrainingDate, pTrainingTime);
    SELECT felling INTO felling
    FROM user_felling
    WHERE user_id = pUserId
    ORDER BY created_at DESC
    LIMIT 1;
    IF felling = 1 THEN
        SELECT complete_message INTO msg FROM message WHERE training_type_id = pTrainingTypeId;
        INSERT INTO notification (user_id, message, created_at, updated_at) VALUES (pUserId, msg, NOW(), NOW());
    END IF;
END;



/*
07- Explique as diferenças entre trigger, função e procedure. Indique as vantagens e desvantagens em utilizar a procedure.
*/

/*
    TRIGGUER - É um evento que é disparado quando uma ação é executada no banco de dados, como por exemplo, quando um registro é inserido, atualizado ou excluído.
    PROCEDURE - É um conjunto de instruções que podem ser executadas em um banco de dados. Uma procedure não pode retornar valores e além de funções basicas, tem permisão para alterar a estrura, fazer commits e rollBacks.
    FUNÇÃO - É um conjunto de instruções que podem ser executadas em um banco de dados. Uma função pode receber parâmetros e retornar valores, entretanto não possui possibilidade de alteração no banco.
*/