-- Inserts --

insert into Instituicao (nome, cnpj) values
    ('IFPI - Teresina Central', '99.999.999/9999-99'),
    ('IFPI - Teresina Zona Sul', '88.888.888/8888-88');

insert into Nutricionista (nome, cpf, cod_instituicao) values
    ('Mariana', '111.111.111-11', 3),
    ('Alberto', '222.222.222-22', 1),
    ('Rafaela', '333.333.333-33', 2);

insert into Fornecedor (nome, cnpj) values
    ('Carvalho Atacadista', '11.111.111/1111-11'),
    ('Mateus Supermercado', '22.222.222/2222-22');

insert into Ingrediente (nome, tipo_quantidade) values
    ('Arroz integral', 'kilograma'),
    ('Arroz parboilizado', 'kilograma'),
    ('Macarrao', 'kilograma'),
    ('Feijao verde', 'kilograma'),
    ('Feijao carioca', 'kilograma'),
    ('Feijao preto', 'kilograma'),
    ('Carne de gado', 'kilograma'),
    ('Carde caprina', 'kilograma'),
    ('Carde ovina', 'kilograma'),
    ('Frango', 'kilograma'),
    ('Peixe', 'kilograma'),
    ('Tomate', 'kilograma'),
    ('Cebola', 'kilograma'),
    ('Pimentao', 'unidade'),
    ('Abobora', 'unidade'),
    ('Banana', 'unidade'),
    ('Laranja', 'unidade'),
    ('Mamao', 'unidade'),
    ('Melancia', 'unidade'),
    ('Melao', 'unidade');

insert into Estoque values
    (1, 1, 500),
    (1, 3, 100),
    (1, 4, 300),
    (1, 10, 80),
    (1, 11, 50),
    (1, 12, 50),
    (1, 13, 50),
    (1, 15, 20),
    (1, 19, 15),
    (1, 21, 900),
    (2, 2, 400),
    (2, 3, 100),
    (2, 5, 200),
    (2, 8, 80),
    (2, 10, 50),
    (2, 12, 50),
    (2, 13, 50),
    (2, 15, 20),

insert into Precos values 
    (1, 1, 5.0),
    (2, 1, 5.5),
    (1, 3, 2.0),
    (2, 3, 1.9),
    (1, 5, 6.0),
    (2, 5, 5.5),
    (1, 7, 20.0),
    (2, 9, 22.0),
    (1, 10, 10.0),
    (2, 10, 10.0),
    (1, 11, 30.0),
    (2, 11, 33.0),
    (1, 12, 4),
    (2, 12, 4),
    (1, 13, 3),
    (2, 13, 4),
    (1, 14, 0.5),
    (2, 14, 0.75),
    (1, 17, 1.0),
    (2, 17, 0.9),
    (2, 19, 10);
