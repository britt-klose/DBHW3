/* 
DB Assignment #3
Brittany Klose
9/29/24
*/

use HW3;

-- ----------------------------------
-- Tables
-- -----------------------------------
create table if not exists merchants(
    mid int primary key,
    
    name varchar(100) not null,
    city varchar(100) not null,
    state varchar(100) not null
);



create table if not exists products(
    pid int primary key,
    
    name varchar(100) not null,
    category varchar(100) not null,
    description varchar(100) not null
    
    constraint name_constraint check (
		name in 
        ('Printer', 'Ethernet Adapter','Desktop','Hard Drive', 'Laptop',
        'Router', 'Network Card', 'Super Drive', 'Monitor')),
        
	constraint category_constraint check (category in 
		('Peripheral', 'Networking', 'Computer'))
		
); 


create table if not exists sell(
    mid int, -- FK
    pid int, -- FK
    
    price decimal(20,2),
    quantity_available int,
    
    foreign key (mid) references merchants(mid),
	foreign key (pid) references products(pid),
    
    constraint price_constraint check (price between 0.00 and 100000.00),
        
	constraint quantity_available_constraint check 
		(quantity_available between 0 and 1000)
);


create table if not exists orders(
    oid int primary key,
    
    shipping_method varchar(100) not null,
    shipping_cost decimal(6,2) not null
    
    constraint shipping_method_constraint check (shipping_method in
		('UPS', 'FedEx', 'USPS')),
        
	constraint shipping_cost_constraint check 
		(shipping_cost between 0.00 and 500.00)
);


create table if not exists contain(
    oid int, -- FK
    pid int, -- FK
    
    foreign key (oid) references orders(oid),
	foreign key (pid) references products(pid)
);


create table if not exists customers(
    cid int primary key,
    
    fullname varchar(100) not null,
    city varchar(100) not null,
    state varchar(100) not null
);



create table if not exists place(
    oid int, -- FK
    cid int, -- FK
    
    order_date date not null,
    
    foreign key (oid) references orders(oid),
	foreign key (cid) references customers(cid)
    
);



-- -----------------------------------
-- Query 1: List names and sellers of products that are 
-- no longer available (quantity=0)
-- -----------------------------------
select p.name as product, m.name as merchant, quantity_available
from products p
	inner join sell s on p.pid = s.pid
    inner join merchants m on s.mid = m.mid
where s.quantity_available = 0;

-- -----------------------------------
-- Query 2: List names and descriptions of products that are not sold.
-- -----------------------------------
select p.pid, p.name, p.description, count(c.pid)
from products p
	left outer join contain c on p.pid = c.pid
group by p.pid
having count(c.pid) = 0;



-- -----------------------------------
-- Query 3: How many customers bought SATA drives but not any routers?
-- -----------------------------------
-- Version 1 with except 

select count(distinct cus.cid)
from customers cus 
	join place pl on cus.cid = pl.cid
    join orders o on pl.oid = o.oid
    join contain c on o.oid = c.oid
    join products p on c.pid = p.pid
where p.name = 'Super Drive' 

except

select count(distinct cus.cid) 
from customers cus 
	join place pl on cus.cid = pl.cid
    join orders o on pl.oid = o.oid
    join contain c on o.oid = c.oid
    join products p on c.pid = p.pid
where p.name = 'Router';


select count(distinct cus.cid) as cus_count
from customers cus 
	join place pl on cus.cid = pl.cid
    join orders o on pl.oid = o.oid
    join contain c on o.oid = c.oid
    join products pr_a on ct_a.pid = pr_a.pid and pr_a.name ='Router'
    left join contain ct_b on o.oid=ct_b.oid
    left join products pr_b on ct_b.pid=pr_b.pid and pr_b.name= 'Super Drive'
    where pr_b.pid is null; 



-- -----------------------------------
-- Query 4: HP has a 20% sale on all its Networking products.
-- -----------------------------------
select p.pid, p.name as Product, s.price as original_price, s.price-(s.price*0.20) as sale_price
from products p
	inner join sell s on p.pid = s.pid
    inner join merchants m on s.mid = m.mid
where m.name = 'HP'
order by p.pid;



-- -----------------------------------
-- Query 5: What did Uriel Whitney order from Acer? (
-- make sure to at least retrieve product names and prices).
-- -----------------------------------
select distinct p.pid, p.name, s.price
from products p
	inner join sell s on p.pid=s.pid
    inner join merchants m on s.mid=m.mid
	inner join contain con on p.pid=con.pid
    inner join orders o on con.oid=o.oid
    inner join place pl on o.oid=pl.oid
    inner join customers cus on pl.cid=cus.cid
where cus.fullname = 'Uriel Whitney' AND m.name = 'Acer' 
order by p.pid;

-- -----------------------------------
-- Query 6: List the annual total sales for each company 
-- (sort the results along the company and the year attributes).
-- -----------------------------------
select m.mid, m.name, count(p.pid*s.price) as total_sales
from merchants m
	inner join sell s on m.mid = s.mid
    inner join products p on s.pid=p.pid
    inner join contain con on p.pid =con.pid
    inner join orders o on con.oid=o.oid
    inner join place pl on o.oid=pl.oid;



-- -----------------------------------
-- Query 7: Which company had the highest annual revenue and in what year?
-- -----------------------------------
select m.name as merchant, year(pl.order_date) as yr, sum(s.price * count(c.pid)) as annual_rev
from merchants m
	inner join sell s on m.mid=s.mid
    inner join contain c on s.pid=c.pid
    inner join orders o on c.oid=o.oid
    inner join place pl on o.oid=pl.oid
group by m.name
having sum(s.price * count(c.pid) >= all (
	select sum(s.price * count(c.pid)
    from merchants m
    inner join sell s on m.mid=s.mid
    inner join contain c on s.pid=c.pid
    inner join orders o on c.oid=o.oid
    inner join place pl on o.oid=pl.oid
    group by m.name
);


-- -----------------------------------
-- Query 8: On average, what was the cheapest shipping method used ever?
-- -----------------------------------
select oid, shipping_method, avg(shipping_cost)
from orders
group by oid
having avg(orders.shipping_cost)=(
	select min(min_cost)
    from (
		select avg(orders.shipping_cost) as min_cost
        from orders
        group by orders.shipping_cost
        ) as subquery
); 

-- -----------------------------------
-- Query 9: What is the best sold ($) category for each company?
-- -----------------------------------
	-- want to find which category produced the most money for each company
    -- first need to see the revenue each category brings to each company
		-- to find this need to see orders of products * price
        -- count number of pid on contain
    -- then want to select the category under each company that's the greatest value
    -- count(con.pid) as pcount count number of products ordered 
    -- sum(p.price*con.pid) rev of money
    -- 

  
select p.pid, p.name, s.price, count(con.pid) as Orders, p.category, s.mid, m.name as Seller
from contain con
	inner join products p on con.pid=p.pid
	inner join sell s on p.pid=s.pid
    inner join merchants m on s.mid=m.mid
group by p.pid 



-- -----------------------------------
-- Query 10: For each company find out which customers have 
-- spent the most and the least amounts.
-- -----------------------------------





