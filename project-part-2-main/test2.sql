--- for trigger 4

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

begin transaction;
	 insert into category(id, name) values (1, 'kids'), (2, 'adults');
	 insert into users(id, address, name, account_closed) values (3, 'usr_addr', 'usr', FALSE);
	 insert into manufacturer(id, name, country) values (4, 'manufacturer', 'SG');
	 insert into product (id, name, description, category, manufacturer)
	  values (5, 'cs2102', 'database', 2, 4);
	 insert into shop(id, name) values (7, 'db shop');
	 insert into sells (shop_id, product_id, sell_timestamp, price, quantity)
	  values (7, 5, timestamp '2022-04-10 12:06:48.813012', 50, 1000);
	 insert into orders (id, user_id, shipping_address, payment_amount) values (10, 3, 'asfsdf', 1000);
	 insert into orderline (order_id, shop_id, product_id, sell_timestamp, quantity, shipping_cost, status, delivery_date)
	  values (10, 7, 5, timestamp '2022-04-10 12:06:48.813012', 20, 0, 'delivered', '2022-04-09');
commit;

begin transaction;
	insert into refund_request (id, order_id, shop_id, product_id, sell_timestamp, quantity, request_date, status)
	  values (20, 10, 7, 5, timestamp '2022-04-10 12:06:48.813012', 15, '2022-04-19', 'pending');
commit;