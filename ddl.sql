drop table if exists address, shop, provider, product, purchase,
    supply, prod_in_purchase, prod_in_shop, prod_in_supply cascade;

create table address(
	id_address integer,
	town varchar(30),
	district varchar(30),
	street varchar(30),
	house integer,
	primary key (id_address)
);

create table shop(
    id_shop integer,
    id_address integer,
    name varchar(50),
    storage_capacity NUMERIC(10, 3) not null check ( storage_capacity > 0 ),
    primary key (id_shop),
    foreign key (id_address) references address (id_address) on delete set null on update cascade
);

create table provider(
    id_provider integer,
    company_name varchar(50),
    first_name varchar(30),
    middle_name varchar(30),
    last_name varchar(30),
    phone varchar(50) constraint check_phone check ( phone similar to
        '($+7|8)(| )( |-|$(|)[0-9]{3}(-|$)|)( |)[0-9]{3}(-| |)[0-9]{2}(-| |)[0-9]{2}' escape '$'),
    primary key (id_provider)
);

create table product(
	id_product integer,
	title varchar(30),
	type varchar(30),
	size NUMERIC(10, 3) not null check ( size > 0 ),
	primary key (id_product)
);

create table purchase(
    id_purchase integer,
    id_shop integer not null,
    date date not null,
    primary key (id_purchase),
    foreign key (id_shop) references shop(id_shop) on delete cascade on update cascade
);

create table supply(
    id_supply integer,
    id_shop integer not null,
    id_provider integer,
    date date not null,
    primary key (id_supply),
    foreign key (id_shop) references shop(id_shop) on delete cascade on update cascade,
    foreign key (id_provider) references provider(id_provider) on delete set null on update cascade
);

create table prod_in_purchase(
    id_purchase integer not null,
    id_product integer not null,
    quantity integer not null check ( quantity >= 1 ),
    primary key (id_purchase, id_product),
    foreign key (id_purchase) references purchase(id_purchase) on delete cascade on update cascade,
    foreign key (id_product) references product(id_product) on delete restrict on update cascade
);

create table prod_in_shop(
	id_shop integer not null,
	id_product integer not null,
    price NUMERIC(10, 2) not null check ( price > 0 ),
	valid_from date,
	valid_to date,
	check ( valid_from < valid_to ),
	primary key (id_product, id_shop, valid_from),
    foreign key (id_shop) references shop(id_shop) on delete cascade on update cascade,
    foreign key (id_product) references product(id_product) on delete restrict on update cascade
);

create table prod_in_supply(
    id_supply integer not null,
    id_product integer not null,
    quantity integer not null check ( quantity >= 1 ),
    price NUMERIC(10, 2) not null check ( price > 0 ),
    primary key (id_supply, id_product),
    foreign key (id_supply) references supply(id_supply) on delete cascade on update cascade,
    foreign key (id_product) references product(id_product) on delete restrict on update cascade
);

