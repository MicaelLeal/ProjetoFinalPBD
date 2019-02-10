CREATE TYPE tipo_qtd AS ENUM ('unidade', 'kilograma', 'grama');

create table if not exists Instituicao (
    cod_instituicao serial not null primary key,
    nome varchar(100) not null,
    cnpj varchar(18) not null
);

create table if not exists Nutricionista (
    cod_nutricionista serial not null primary key,
    nome varchar(60) not null,
    cpf varchar(14) not null,
    cod_instituicao int not null references Instituicao(cod_instituicao)
);

create table if not exists Fornecedor (
    cod_fornecedor serial not null primary key,
    nome varchar(100) not null,
    cnpj varchar(18) not null
);

create table if not exists Ingrediente (
    cod_ingredinte serial not null primary key,
    nome varchar(60) not null,
    tipo_quantidade tipo_qtd not null
);

create table if not exists Estoque (
    cod_instituicao int not null references Instituicao(cod_instituicao),
    cod_ingredinte int not null references Ingrediente(cod_ingredinte),
    quantidade int not null check ( quantidade >= 0 ),
    constraint pk_estoque primary key (cod_instituicao, cod_ingredinte)
);

create table if not exists Preco (
    cod_fornecedor int not null references Fornecedor(cod_fornecedor),
    cod_ingredinte int not null references Ingrediente(cod_ingredinte),
    valor float not null check ( valor >= 0 ),
    constraint pk_precos primary key (cod_fornecedor, cod_ingredinte)
);

create table if not exists Pedido (
    cod_pedido serial not null primary key,
    cod_nutricionista int not null references Nutricionista(cod_nutricionista),
    cod_fornecedor int references Fornecedor(cod_fornecedor),
    data_pedido date,
    data_entrega date CONSTRAINT data_entrega_maior CHECK ( data_entrega >= data_pedido ),
    entregue boolean default false,
    finalizado boolean default false
);

create table if not exists Item_pedido (
    cod_pedido int not null references Pedido(cod_pedido),
    cod_ingredinte int not null references Ingrediente(cod_ingredinte),
    quantidade int not null check ( quantidade > 0 ),
    valor_total float check ( valor_total >= 0 ),
    constraint pk_item_pedido primary key (cod_pedido, cod_ingredinte)
);

create table if not exists Prato (
    cod_prato serial not null primary key,
    nome varchar(50) not null
);

create table if not exists Receita (
    cod_prato int not null references Prato(cod_prato),
    cod_ingredinte int not null references Ingrediente(cod_ingredinte),
    quantidade int not null check ( quantidade >= 0 ),
    tipo_quantidade tipo_qtd not null,
    constraint pk_receita primary key (cod_prato, cod_ingredinte)
);

create table if not exists Cardapio (
    cod_cardapio serial not null primary key,
    cod_nutricionista int not null references Nutricionista(cod_nutricionista),
    descricao varchar(250)
);

create table if not exists Prato_cardapio (
    cod_cardapio int not null references Cardapio(cod_cardapio),
    cod_prato int not null references Prato(cod_prato),
    constraint pk_cardapio primary key (cod_cardapio, cod_prato)
);

create table if not exists Oferta (
    cod_oferta serial not null primary key,
    cod_instituicao int not null references Instituicao(cod_instituicao),
    cod_cardapio int not null references Cardapio(cod_cardapio),
    data_oferta date not null,
    quantidade_pessoas int not null check ( quantidade_pessoas >= 0 ),
    finalizada boolean default false
);
