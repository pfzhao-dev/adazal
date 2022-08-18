BEGIN TRANSACTION;
delete from reply;
delete from comment;
delete from orderline;
delete from orders;
delete from sells;
delete from shop;
delete from issued_coupon;
delete from users;
delete from product;
delete from category;
delete from manufacturer;
delete from coupon_batch;
delete from employee;
delete from refund_request;
delete from complaint;

insert into users(id, address, name, account_closed) values (1, 'PGPR', 'Peng Fei', FALSE), (2, 'a', 'Xiao Ming', TRUE);
insert into category(id, name) values (1, 'kids'), (2, 'adults');
insert into manufacturer(id, name, country) values (1, 'PF', 'China');
insert into product (id, name, description, category, manufacturer)
	values (1, 'doll', 'toy', 1, 1);
insert into shop(id, name) values (1, 'PengFei Shop');
insert into sells values (1, 1, timestamp '2022-04-07 14:47:48.813012',
	30, 20);
insert into coupon_batch(id, valid_period_start, valid_period_end, reward_amount, min_order_amount)
	values (1, '2022-04-07', '2022-04-11', 15, 20);
insert into issued_coupon values(1, 1);
insert into employee values (1, 'roy', 9999.99);
insert into orders values (1,1,1,'a',1.0) ,(2,2,2,'a', 2.0);
insert into orderline values (1, 1, 1, timestamp '2022-04-07 14:47:48.813012',1,1.0,'delivered',date'2022-04-08');
insert into comment values(1, 1), (2,1), (3,1), (4,1), (5,1), (6,1);
insert into review values(1,1, 1, 1, timestamp '2022-04-07 14:47:48.813012');
insert into review_version values(1,timestamp '2022-04-08 14:47:48.813012', 'good', 4),
(1,timestamp '2022-04-08 15:47:48.813012', 'ok', 3);
insert into refund_request values (1,1,1,1,1,timestamp '2022-04-07 14:47:48.813012',1,date'2022-04-07', 'accepted',date '2022-04-07',null);
insert into reply values (2,1), (3,1), (4,2), (5,2), (6,5);
insert into reply_version values (2, '2022-04-09 14:47:48.813012', 'haha'),(3, '2022-04-09 16:47:48.813012', 'hahaha'), (4, '2022-04-09 17:47:48.813012', 'hahahaha'), (5, '2022-04-09 18:47:48.813012', 'hahahahaha'), (6, '2022-04-09 19:47:48.813012', 'hahahahahaha');
commit;


select * from view_comments(1, 1, timestamp '2022-04-07 14:47:48.813012');
select * from get_most_returned_products_from_manufacturer(1, 1);
select * from get_worst_shops(1);