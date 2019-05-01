drop function if exists get_products_in_storage(date_to date);
drop function if exists get_fill_of_storage(date_to date);
drop function if exists get_fill_of_storage_p(date_to date);
drop function if exists get_sell_products(date_from date, date_to date);
drop function if exists get_sell_products_and_price(date_from date, date_to date);
drop function if exists get_buy_products(date_from date, date_to date);
drop function if exists get_buy_products_and_price(date_from date, date_to date);
drop function if exists get_value_of_products_a(date_from date, date_to date);
drop function if exists get_value_of_products_r(date_from date, date_to date);
drop function if exists get_buy_products_avg_price(date_from date, date_to date);
drop function if exists get_sell_products_avg_price(date_from date, date_to date);
drop function if exists get_demand_for_products(date_from date, date_to date);
drop function if exists get_products_avg_price_a(date_from date, date_to date);
drop function if exists get_products_avg_price_r(date_from date, date_to date);
drop function if exists get_value_of_shop(date_from date, date_to date);

create or replace function get_products_in_storage(date_to date)
returns TABLE(id_shop integer,
              id_product integer,
              quantity bigint)
as $$
  select s,
         p,
         sum(n)::bigint
  from (
      select id_shop s,
             id_product p,
             sum(quantity) n
      from supply join prod_in_supply pis on supply.id_supply = pis.id_supply
      where date <= date_to
      group by id_shop, id_product
      union ALL
      select id_shop,
             id_product,
             -sum(quantity) n
      from purchase join prod_in_purchase pip on purchase.id_purchase = pip.id_purchase
      where date <= date_to
      group by id_shop, id_product) X
  group by s, p;
$$ LANGUAGE sql;

create or replace function get_fill_of_storage(date_to date)
returns TABLE(id_shop integer,
              fill numeric(10, 3))
as $$
    select sh.id_shop,
       case when count(ps.id_shop) != 0
           then
            sum(ps.quantity * p.size)::numeric(10, 3)
           else
            0
        end
    from shop sh left join get_products_in_storage(date_to) ps
            on ps.id_shop = sh.id_shop
        left join product p
            on ps.id_product = p.id_product
    group by sh.id_shop;
$$ LANGUAGE sql;

create or replace function get_fill_of_storage_p(date_to date)
returns TABLE(id_shop integer,
              fill numeric(5, 3))
as $$
    select sh.id_shop,
           ((fs.fill / sh.storage_capacity) * 100)::numeric(5, 3)
    from shop sh left join get_fill_of_storage(date_to) fs
        on sh.id_shop = fs.id_shop
$$ LANGUAGE sql;

create or replace function get_sell_products(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_product integer,
              quantity bigint)
as $$
    select id_shop,
        id_product,
        sum(quantity)
    from purchase join prod_in_purchase pip on purchase.id_purchase = pip.id_purchase
    where date between date_from and date_to
    group by id_shop, id_product
$$ LANGUAGE sql;

create or replace function get_sell_products_and_price(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_product integer,
              quantity bigint,
              total_price numeric(10, 3))
as $$
    select pu.id_shop,
        pip.id_product,
        sum(pip.quantity),
        sum(pip.quantity * pis.price)
    from purchase pu
        join prod_in_purchase pip
            on pu.id_purchase = pip.id_purchase
        join prod_in_shop pis
            on pu.id_shop = pis.id_shop
                and pip.id_product = pis.id_product
                and pu.date between pis.valid_from and pis.valid_to
    where date between date_from and date_to
    group by pu.id_shop, pip.id_product
$$ LANGUAGE sql;

create or replace function get_buy_products(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_provider integer,
              id_product integer,
              quantity bigint)
as $$
    select id_shop,
        id_provider,
        id_product,
        sum(quantity)
    from supply
        join prod_in_supply pis
            on supply.id_supply = pis.id_supply
    where date between date_from and date_to
    group by id_shop, id_provider, id_product
$$ LANGUAGE sql;

create or replace function get_buy_products_and_price(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_provider integer,
              id_product integer,
              quantity bigint,
              total_price numeric(10, 3))
as $$
    select id_shop,
           id_provider,
           id_product,
           sum(quantity),
           sum(quantity * price)
    from supply su
        join prod_in_supply pis
            on su.id_supply = pis.id_supply
    where date between date_from and date_to
    group by id_shop, id_provider, id_product
$$ LANGUAGE sql;

create or replace function get_buy_products_avg_price(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_provider integer,
              id_product integer,
              avg_price numeric(10, 3))
as $$
    select id_shop,
           id_provider,
           id_product,
           (total_price / quantity)::numeric(10, 3)
    from get_buy_products_and_price(date_from, date_to)
$$ LANGUAGE sql;

create or replace function get_sell_products_avg_price(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_product integer,
              avg_price numeric(10, 3))
as $$
    select id_shop,
           id_product,
           (total_price / quantity)::numeric(10, 3)
    from get_sell_products_and_price(date_from, date_to)
$$ LANGUAGE sql;

create or replace function get_products_avg_price_a(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_product integer,
              price numeric(10, 3))
as $$
    select sp.id_shop,
           sp.id_product,
           (sp.avg_price - avg(bp.avg_price))::numeric(10, 3)
    from get_sell_products_avg_price(date_from, date_to) sp
        join get_buy_products_avg_price(date_from, date_to) bp
            on sp.id_shop = bp.id_shop
    group by sp.id_shop, sp.id_product, sp.avg_price;
$$ LANGUAGE sql;

create or replace function get_products_avg_price_r(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_product integer,
              price numeric(10, 3))
as $$
    select sp.id_shop,
           sp.id_product,
           (sp.avg_price / avg(bp.avg_price) * 100)::numeric(10, 3)
    from get_sell_products_avg_price(date_from, date_to) sp
        join get_buy_products_avg_price(date_from, date_to) bp
            on sp.id_shop = bp.id_shop
    group by sp.id_shop, sp.id_product, sp.avg_price;
$$ LANGUAGE sql;

create or replace function get_demand_for_products(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_product integer,
              demand numeric(10, 3))
as $$
    select sp.id_shop,
           sp.id_product,
           (sp.quantity / sum(sp.quantity) over (partition by sp.id_shop))::numeric(10, 3)
    from get_sell_products(date_from, date_to) sp;
$$ LANGUAGE sql;

create or replace function get_value_of_products_a(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_product integer,
              value numeric(10, 3))
as $$
    select ap.id_shop,
           ap.id_product,
           ap.price / p.size
    from get_products_avg_price_a(date_from, date_to) ap
        join product p
            on ap.id_product = p.id_product
$$ LANGUAGE sql;

create or replace function get_value_of_products_r(date_from date, date_to date)
returns TABLE(id_shop integer,
              id_product integer,
              value numeric(10, 3))
as $$
    select rp.id_shop,
           rp.id_product,
           (rp.price * dp.demand)::numeric(10, 3)
    from get_products_avg_price_r(date_from, date_to) rp
        join get_demand_for_products(date_from, date_to) dp
            on rp.id_shop = dp.id_shop
                and rp.id_product = dp.id_product
$$ LANGUAGE sql;

create or replace function get_value_of_shop(date_from date, date_to date)
returns TABLE(id_shop integer,
              value numeric(20, 3))
as $$
    select distinct sh.id_shop,
    (case when count(sp.id_shop) over (partition by sh.id_shop) != 0
        then
            sum(sp.total_price) over (partition by sh.id_shop)
        else
            0
    end -
    case when count(bp.id_shop) over (partition by sh.id_shop) != 0
        then
            sum(bp.total_price) over (partition by sh.id_shop)
        else
            0
    end)::numeric(20, 3)
    from shop sh
        left join get_sell_products_and_price(date_from, date_to) sp
            on sh.id_shop = sp.id_shop
        left join get_buy_products_and_price(date_from, date_to) bp
            on sh.id_shop = bp.id_shop
$$ LANGUAGE sql;

select *
from get_value_of_products_r('2017-02-01'::date, '2018-02-10'::date);

--13
select p.type, avg(value) as v
from get_value_of_products_r('2017-03-01'::date, '2019-04-01'::date) g
    join product p
        on g.id_product = p.id_product
group by p.type
order by v desc;