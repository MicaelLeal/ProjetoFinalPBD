create table if not exists Instituicao (
    cod_instituicao serial not null primary key,
    nome varchar(100) not null,
    cnpj varchar(18) not null
);

create table if not exists Nutricionista (
    cod_nutricionista serial not null primary key,
    nome varchar(60) not null,
    cpf varchar(14) not null,
    cod_instituicao int references Instituicao(cod_instituicao)
);

create table if not exists Forncedor (
    cod_fornecedor serial not null  primary key,
    nome varchar(100) not null,
    cnpj varchar(18) not null
);

create table if not exists Ingrediente (
    cod_ingredinte serial not null primary key,
    nome varchar(60) not null
);

create table if not exists Estoque (
    cod_instituicao int not null references Instituicao(cod_instituicao),
    cod_ingredinte int not null references Ingrediente(cod_ingredinte),
    quantidade int,
    constraint pk_estoque primary key (cod_instituicao, cod_ingredinte)
);

create table if not exists Precos (
    cod_fornecedor int not null,
    cod_ingredinte int not null,
    valor float not null,
    constraint pk_precos primary key (cod_fornecedor, cod_ingredinte)
);

create table if not exists Pedido (
    cod_pedido serial not null primary key,
    cod_nutricionista int not null references Nutricionista(cod_nutricionista),
    cod_fornecedor int not null references Instituicao(cod_instituicao)
);

create table if not exists Item_pedido (
    cod_pedido int not null references Pedido(cod_pedido),
    cod_ingredinte int not null references Ingrediente(cod_ingredinte),
    quantidade int not null,
    valor_total float,
    constraint pk_item_pedido primary key (cod_pedido, cod_ingredinte)
);

create table if not exists Prato (
    cod_prato serial not null primary key,
    cod_nutricionista int not null references Nutricionista(cod_nutricionista),
    data_criacao date
);

create table if not exists Receita (
    cod_receita serial primary key,
    cod_prato int not null references Prato(cod_prato),
    cod_ingredinte int not null references Ingrediente(cod_ingredinte),
    quantidade float
);

create table if not exists Cardapio (
    cod_cardapio int not null primary key,
    cod_prato int not null references Prato(cod_prato)
);

create table if not exists Tipo_cardapio (
    cod_tipo_cardapio serial not null primary key,
    cod_nutricionista int not null references Nutricionista(cod_nutricionista),
    descricao varchar(250)
);

create table if not exists Oferta (
    cod_oferta int not null primary key,
    cod_instituicao int not null references Instituicao(cod_instituicao),
    cod_tipo_cardapio int not null references Tipo_cardapio(cod_tipo_cardapio),
    qtd_pessoas int not null,
    data_oferta date not null
);
