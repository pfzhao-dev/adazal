BEGIN TRANSACTION;
delete from complaint;
delete from refund_request;
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

insert into users(id, address, name, account_closed) values (1, 'PGPR', 'Peng Fei', FALSE);
insert into category(id, name) values (1, 'kids'), (2, 'adults');
insert into manufacturer(id, name, country) values (1, 'PF', 'China');
insert into product (id, name, description, category, manufacturer)
	values (1, 'doll', 'toy', 1, 1);
insert into shop(id, name) values (1, 'PengFei Shop');
insert into sells values (1, 1, timestamp '2022-04-07 14:47:48.813012',
	30, 20);
insert into coupon_batch(id, valid_period_start, valid_period_end, reward_amount, min_order_amount)
	values (1, '2022-04-07', '2022-04-11', 90, 90);
insert into coupon_batch(id, valid_period_start, valid_period_end, reward_amount, min_order_amount)
	values (2, '2022-04-07', '2022-04-11', 90.1, 90.1);
insert into issued_coupon values(1, 1);
insert into issued_coupon values(1, 2);
insert into employee values (1, 'roy', 999999.99);
commit;

call place_order(1, 1, 'PGPR PengFei House', ARRAY[1], ARRAY[1], ARRAY[timestamp '2022-04-07 14:47:48.813012'],
				ARRAY[4], ARRAY[4.20]);
-- Negative Trigger 3
-- call place_order(1, 2, 'PGPR PengFei House', ARRAY[1], ARRAY[1], ARRAY[timestamp '2022-04-07 14:47:48.813012'],
-- 				 ARRAY[3], ARRAY[4.20]);
CREATE OR REPLACE procedure f()
AS $$
declare _order_id int;
declare other_id int;
begin 
	select max(id) into _order_id from orders;
	call review(1, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 'bad toy', 1, timestamp '2022-04-07 14:47:48.813012');
	select max(id) into other_id from comment;
	call reply(1, other_id, 'nah', timestamp '2022-04-07 14:47:48.813012');
	-- creates refund request
	update orderline set delivery_date = '2022-03-24', status = 'delivered' where order_id = _order_id;
	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
		values (1, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 2, '2022-04-11', 'accepted', '2022-04-12', NULL);
	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
		values (1, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 1, '2022-04-11', 'accepted', '2022-04-12', NULL);
	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
		values (1, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 5, '2022-04-11', 'rejected', '2022-04-12', 'noob');
	-- NEGATIVE TRIGGER 4
-- 	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
-- 		values (1, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 1, '2022-04-11', 'being_handled', NULL, NULL);
-- 	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
-- 		values (NULL, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 1, '2022-04-11', 'pending', NULL, NULL);
-- 	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
-- 		values (1, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 1, '2022-04-11', 'accepted', '2022-04-12', NULL);

--	POSITIVE TRIGGER 5
	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
		values (1, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 5, '2022-04-22', 'rejected', '2022-06-13', 'noob');
	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
		values (1, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 5, '2022-04-23', 'rejected', '2022-06-13', 'noob');
-- NEGATIVE TRIGGER 5
-- 	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
-- 		values (1, _order_id, 1, 1, timestamp '2022-04-07 14:47:48.813012', 5, '2022-04-24', 'rejected', '2022-06-13', 'noob');
end;
$$LANGUAGE plpgsql;

call f();

-- POSITIVE TRIGGER 1
begin transaction;
	insert into users(id, address, name, account_closed) values (2, 'PGPR', 'Peng Fei2', FALSE);
	insert into manufacturer(id, name, country) values (2, 'PF2', 'China');
	insert into product (id, name, description, category, manufacturer)
		values (2, 'car', 'vehicle', 2, 2);
	insert into shop(id, name) values (2, 'PengFei2 Shop');
	insert into sells values (2, 2, timestamp '2022-04-07 14:47:48.813012',
		30, 20);
commit;

-- NEGATIVE TRIGGER 1
-- begin transaction;
-- 	insert into shop(id, name) values (3, 'PengFei3 Shop');
-- 	insert into product (id, name, description, category, manufacturer)
-- 		values (3, 'car2', 'vehicle2', 2, 2);
-- commit;

-- NEGATIVE TRIGGER 2
-- insert into orders (user_id, coupon_id, shipping_address, payment_amount)
-- 	values (1, null, 'shipping_address', 25);

-- NEGATIVE TRIGGER 3

-- begin transaction;
-- 	insert into users(id, address, name, account_closed) values (3, 'usr_addr', 'usr', FALSE);
-- 	insert into manufacturer(id, name, country) values (4, 'manufacturer', 'SG');
-- 	insert into product (id, name, description, category, manufacturer)
-- 		values (5, 'cs2102', 'database', 2, 4);
-- 	insert into shop(id, name) values (7, 'db shop');
-- 	insert into sells (shop_id, product_id, sell_timestamp, price, quantity)
-- 		values (7, 5, timestamp '2022-04-10 12:06:48.813012', 50, 1000);
-- 	insert into orders (id, user_id, shipping_address, payment_amount) values (10, 3, 'asfsdf', 1000);
-- 	insert into orderline (order_id, shop_id, product_id, sell_timestamp, quantity, shipping_cost, status, delivery_date)
-- 		values (10, 7, 5, timestamp '2022-04-10 12:06:48.813012', 20, 0, 'delivered', '2022-04-09');
-- 	insert into refund_request (id, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status)
-- 		values (20, 10, 7, 5, timestamp '2022-04-10 12:06:48.813012', 15, '2022-04-19', 'pending');
-- commit;

-- POSITIVE TRIGGER 11
CREATE OR REPLACE procedure g()
AS $$
declare _order_id int;
declare _comment_id int;
declare _review_id int;
begin
	call place_order(2, null, 'PGPR PengFei House', ARRAY[2], ARRAY[2], ARRAY[timestamp '2022-04-07 14:47:48.813012'],
				ARRAY[4], ARRAY[3.20]);
	select max(id) into _order_id from orders;
	-- comment next line for NEGATIVE TRIGGER 11
	update orderline set delivery_date = '2022-04-10', status = 'delivered' where order_id = _order_id;
	insert into complaint values(1, 'complaint', 'being_handled', 2, 1);
	-- NEGATIVE TRIGGER 7: A user can only make a product review for a product that they themselves purchased.
	-- call review(1, _order_id, 2, 2, timestamp '2022-04-07 14:47:48.813012', 'good job!', 5, timestamp '2022-04-07 14:47:48.813012');
	
	insert into comment (user_id) values (2);
  	select max(id) into _comment_id from comment;
	insert into review (id, order_id, shop_id, product_id, sell_timestamp) 
    	values (_comment_id, _order_id, 2, 2, timestamp '2022-04-07 14:47:48.813012');
	select max(id) into _review_id from review;
  	insert into review_version (review_id, review_timestamp, content, rating)
    	values (_review_id, timestamp '2022-04-07 14:47:48.813012', 'content', 1);
	insert into review_version (review_id, review_timestamp, content, rating)
    	values (_review_id, timestamp '2022-04-08 14:47:48.813012', 'content2', 2);
	-- NEGATIVE TRIGGER 8,9,10,11
	--insert into reply (id, other_comment_id) values (_comment_id, _comment_id);
  	--select max(id) into _review_id from reply;
  	--insert into reply_version (reply_id, reply_timestamp, content)
    	--values (_review_id, timestamp '2022-04-07 14:47:48.813012', 'content');
	
	select max(id) into _review_id from review;
	--  uncomment next few lines to test NEGATIVE TRIGGER 12
		insert into shop_complaint values(1, 2);
	-- 	insert into comment_complaint values(1, _review_id);
	--	insert into delivery_complaint values(1, _order_id, 2, 2, timestamp '2022-04-07 14:47:48.813012');
	insert into complaint values(2, 'complaint', 'being_handled', 1, 1);
		insert into delivery_complaint values(2, _order_id, 2, 2, timestamp '2022-04-07 14:47:48.813012');
	--	insert into shop_complaint values(2, 2);
	insert into refund_request(handled_by, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status, handled_date, rejection_reason)
		values (1, _order_id, 2, 2, timestamp '2022-04-07 14:47:48.813012', 4, '2022-04-11', 'accepted', '2022-04-12', NULL);
end;
$$LANGUAGE plpgsql;
call g();

BEGIN TRANSACTION;
	insert into product (id, name, description, category, manufacturer)
		values (3, 'doll', 'toy2', 1, 1);
	insert into shop(id, name) values (3, 'PengFeiS Shop');
	insert into sells values (3, 3, timestamp '2022-04-07 14:47:48.813012',
		30, 20);
	call reply(1, 89, 'reply 2', timestamp '2022-04-07 14:47:48.813012');
COMMIT;

select * from view_comments(2, 2, timestamp '2022-04-07 14:47:48.813012');

select * from get_most_returned_products_from_manufacturer (1, 3);

select * from get_worst_shops(3);
