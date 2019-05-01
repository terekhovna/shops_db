truncate address, shop, provider, product, purchase,
    prod_in_purchase, supply, prod_in_supply, prod_in_shop cascade;
copy address from 'D:\Documents\Programs\Postgres\Shops\address.txt' delimiter '|' null '!';
copy shop from 'D:\Documents\Programs\Postgres\Shops\shop.txt' delimiter '|' null '!';
copy provider from 'D:\Documents\Programs\Postgres\Shops\provider.txt' delimiter '|' null '!';
copy product from 'D:\Documents\Programs\Postgres\Shops\product.txt' delimiter '|' null '!';
copy purchase from 'D:\Documents\Programs\Postgres\Shops\purchase.txt' delimiter '|' null '!';
copy prod_in_purchase from 'D:\Documents\Programs\Postgres\Shops\prod_in_purchase.txt' delimiter '|' null '!';
copy supply from 'D:\Documents\Programs\Postgres\Shops\supply.txt' delimiter '|' null '!';
copy prod_in_supply from 'D:\Documents\Programs\Postgres\Shops\prod_in_supply.txt' delimiter '|' null '!';
copy prod_in_shop from 'D:\Documents\Programs\Postgres\Shops\prod_in_shop.txt' delimiter '|' null '!';
