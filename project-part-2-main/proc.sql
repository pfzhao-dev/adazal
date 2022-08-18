-- Triggers (1-6)
/* Q1. Each shop should sell at least one product. */
drop trigger if exists shop_at_least_one_product on shop cascade;
create or replace function shop_at_least_one_product_function()
returns trigger as 
$$
declare count integer;
begin
  select count(distinct product_id) into count
  from sells
  where shop_id = new.id;
  if count >= 1 then
    return new;
  else
    raise exception 'trigger 1: Each shop should sell at least one product.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger shop_at_least_one_product
after insert
on shop
deferrable initially deferred
for each row
execute function shop_at_least_one_product_function();

/* Q2. An order must involve one or more products from one or more shops. */
drop trigger if exists order_one_or_more_product_shop on orders cascade;
create or replace function order_one_or_more_product_shop_function()
returns trigger as 
$$
declare count_product integer;
    count_shop integer; 
begin
  select count(distinct product_id) into count_product
  from orderline
  where order_id = new.id;
  select count(distinct shop_id) into count_shop
  from orderline
  where order_id = new.id;
  if count_product >= 1 and count_shop >= 1 then
    return new;
  else
    raise exception 'trigger 2: An order must involve one or more products from one or more shops.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger order_one_or_more_product_shop
after insert
on orders
deferrable initially deferred
for each row
execute function order_one_or_more_product_shop_function();

/* Q3. A coupon can only be used on an order whose total amount (before the coupon is applied) exceeds 
the minimum order amount. */
drop trigger if exists coupon_min_order_amount on orders cascade;
create or replace function coupon_min_order_amount_function()
returns trigger as 
$$
declare min_order numeric;
        total_amount numeric;
begin
  select min_order_amount into min_order
  from coupon_batch
  where id = new.coupon_id;
  select sum(price * quantity) into total_amount
  from (
    select orderline.order_id, orderline.shop_id, orderline.product_id, orderline.sell_timestamp, sells.price, orderline.quantity
    from orderline left join sells
    on orderline.shop_id = sells.shop_id
    and orderline.product_id = sells.product_id
    and orderline.sell_timestamp = sells.sell_timestamp
    where orderline.order_id = new.id
  ) as all_orders
  where order_id = new.id;
  if new.coupon_id is null or total_amount >= min_order then
    return new;
  else 
    raise exception 'trigger 3: A coupon can only be used on an order whose total amount (before the coupon is applied) exceeds the minimum order amount.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger coupon_min_order_amount
after insert
on orders
deferrable initially deferred
for each row
execute function coupon_min_order_amount_function();

/* Q4. The refund quantity must not exceed the ordered quantity. For each order, we need to ensure that the sum of the quantifies of all refund requests (except those that have been rejected) does not exceed the ordered quantity. */
drop trigger if exists check_refund_quantity on refund_request cascade;
create or replace function check_refund_quantity_function()
returns trigger as
$$
declare old_refund_quantity integer;
    order_quantity integer;
begin
  select sum(quantity) into old_refund_quantity
  from refund_request
  where order_id = new.order_id
  and shop_id = new.shop_id
  and product_id = new.product_id
  and sell_timestamp = new.sell_timestamp
  and status != 'rejected';
  select quantity into order_quantity
  from orderline
  where order_id = new.order_id
  and shop_id = new.shop_id
  and product_id = new.product_id
  and sell_timestamp = new.sell_timestamp;
  if old_refund_quantity <= order_quantity then
    return new;
  else 
    raise exception 'trigger 4: The refund quantity must not exceed the ordered quantity.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger check_refund_quantity
after insert
on refund_request
deferrable initially deferred
for each row
execute function check_refund_quantity_function();

/* Q5. The refund request date must be within 30 days of the delivery date. */
drop trigger if exists refund_within_30_days on refund_request cascade;
create or replace function refund_within_30_days_function()
returns trigger as
$$
declare _delivery_date date;
    refund_request_date date;
begin
  select delivery_date into _delivery_date
  from orderline
  where order_id = new.order_id;
  select request_date into refund_request_date
  from refund_request
  where id = new.id;
  if refund_request_date >= _delivery_date and refund_request_date <= _delivery_date + 30 then
    return new;
  else 
    raise exception 'trigger 5: The refund request date must be within 30 days of the delivery date.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger refund_within_30_days
after insert
on refund_request
deferrable initially deferred
for each row
execute function refund_within_30_days_function();

/* Q6. Refund request can only be made for a delivered product. */
drop trigger if exists check_refund_delivered_product on refund_request cascade;
create or replace function check_refund_delivered_product_function()
returns trigger as
$$
declare product_delivery_status text;
begin
  select status into product_delivery_status
  from orderline
  where order_id = new.order_id
  and shop_id = new.shop_id
  and product_id = new.product_id
  and sell_timestamp = new.sell_timestamp;
  if product_delivery_status = 'delivered' then
    return new;
  else
    raise exception 'trigger 6: Refund request can only be made for a delivered product.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger check_refund_delivered_product
after insert
on refund_request
deferrable initially deferred
for each row
execute function check_refund_delivered_product_function();

-- Triggers (7-12)
/* Comment related: */
/* (7) A user can only make a product review for a product that they themselves purchased. */
drop trigger if exists check_product_review_identity on review cascade;
create or replace function check_product_review_identity_function()
returns trigger as 
$$
declare user_id_from_comment integer;
        user_id_from_orders integer;
begin
  select user_id into user_id_from_comment
  from comment
  where id = new.id;
  select orders.user_id into user_id_from_orders
  from orderline left join orders on orderline.order_id = orders.id
  where orderline.order_id = new.order_id
  and orderline.shop_id = new.shop_id
  and orderline.product_id = new.product_id
  and orderline.sell_timestamp = new.sell_timestamp;
  if user_id_from_comment = user_id_from_orders then
    return new;
  else
    raise exception 'Trigger 7: A user can only make a product review for a product that they themselves purchased.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger check_product_review_identity
after insert
on review
deferrable initially deferred
for each row
execute function check_product_review_identity_function();

/* (8) A comment is either a review or a reply, not both (non-overlapping and covering). */
-- 8.1
drop trigger if exists comment_is_review_or_reply on comment cascade;
create or replace function comment_is_review_or_reply_function()
returns trigger as 
$$
declare total_cnt integer;
        review_cnt integer;
        reply_cnt integer;
begin
  select count(*) into review_cnt
  from review
  where id = new.id;
  select count(*) into reply_cnt
  from reply
  where id = new.id;
  total_cnt := review_cnt + reply_cnt;
  if total_cnt = 1 then
    return new;
  else
    raise exception 'Trigger 8: A comment is either a review or a reply, not both (non-overlapping and covering).';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger comment_is_review_or_reply
after insert
on comment
deferrable initially deferred
for each row
execute function comment_is_review_or_reply_function();

-- 8.2
drop trigger if exists review_is_not_reply on review cascade;
create or replace function review_is_not_reply_function()
returns trigger as 
$$
declare total_cnt integer;
        reply_cnt integer;
begin
  select count(*) into total_cnt
  from comment
  where id = new.id;
  select count(*) into reply_cnt
  from reply
  where id = new.id;
  if total_cnt = 1 and reply_cnt = 0 then
    return new;
  else
    raise exception 'Trigger 8: A comment is either a review or a reply, not both (non-overlapping and covering).';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger review_is_not_reply
after insert
on review
deferrable initially deferred
for each row
execute function review_is_not_reply_function();

-- 8.3
drop trigger if exists reply_is_not_review on reply cascade;
create or replace function reply_is_not_review_function()
returns trigger as 
$$
declare total_cnt integer;
        review_cnt integer;
begin
  select count(*) into total_cnt
  from comment
  where id = new.id;
  select count(*) into review_cnt
  from review
  where id = new.id;
  if total_cnt = 1 and review_cnt = 0 then
    return new;
  else
    raise exception 'Trigger 8: A comment is either a review or a reply, not both (non-overlapping and covering).';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger reply_is_not_review
after insert
on reply
deferrable initially deferred
for each row
execute function reply_is_not_review_function();


/* (9) A reply has at least one reply version. */
drop trigger if exists reply_has_at_least_one_reply_version on reply cascade;
create or replace function reply_has_at_least_one_reply_version_function()
returns trigger as 
$$
declare cnt integer;
begin
  select count(*) into cnt
  from reply_version
  where reply_id = new.id;
  if cnt >= 1 then
    return new;
  else
    raise exception 'Trigger 9: A reply has at least one reply version.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger reply_has_at_least_one_reply_version
after insert
on reply
deferrable initially deferred
for each row
execute function reply_has_at_least_one_reply_version_function();

/* (10) A review has at least one review version. */
drop trigger if exists review_has_at_least_one_review_version on review cascade;
create or replace function review_has_at_least_one_review_version_function()
returns trigger as 
$$
declare cnt integer;
begin
  select count(*) into cnt
  from review_version
  where review_id = new.id;
  if cnt >= 1 then
    return new;
  else
    raise exception 'Trigger 10: A review has at least one review version.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger review_has_at_least_one_review_version
after insert
on review
deferrable initially deferred
for each row
execute function review_has_at_least_one_review_version_function();

/* Complaint related: */
/* (11) A delivery complaint can only be made when the product has been delivered. */
drop trigger if exists check_delivery_complaint_on_delivered_product on delivery_complaint cascade;
create or replace function check_delivery_complaint_on_delivered_product_function()
returns trigger as
$$
declare product_delivery_status text;
begin
  select status into product_delivery_status
  from orderline
  where order_id = new.order_id
  and shop_id = new.shop_id
  and product_id = new.product_id
  and sell_timestamp = new.sell_timestamp;
  if product_delivery_status = 'delivered' then
    return new;
  else
    raise exception 'Trigger 11: A delivery complaint can only be made when the product has been delivered.';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger check_delivery_complaint_on_delivered_product
after insert
on delivery_complaint
deferrable initially deferred
for each row
execute function check_delivery_complaint_on_delivered_product_function();

/* (12) A complaint is either a delivery-related complaint,
a shop-related complaint or a comment-related complaint (non-overlapping and covering). */
-- 12.1
drop trigger if exists complaint_is_delivery_or_shop_or_comment_related on complaint cascade;
create or replace function complaint_is_delivery_or_shop_or_comment_related_function()
returns trigger as 
$$
declare total_cnt integer;
        shop_complaint_cnt integer;
        comment_complaint_cnt integer;
        delivery_complaint_cnt integer;
begin
  select count(*) into shop_complaint_cnt
  from shop_complaint
  where id = new.id;
  select count(*) into comment_complaint_cnt
  from comment_complaint
  where id = new.id;
  select count(*) into delivery_complaint_cnt
  from delivery_complaint
  where id = new.id;
  total_cnt := shop_complaint_cnt + comment_complaint_cnt + delivery_complaint_cnt;
  if total_cnt = 1 then
    return new;
  else
    raise exception 'Trigger 12: A complaint is either a delivery-related complaint, a shop-related complaint or a comment-related complaint (non-overlapping and covering).';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger complaint_is_delivery_or_shop_or_comment_related
after insert
on complaint
deferrable initially deferred
for each row
execute function complaint_is_delivery_or_shop_or_comment_related_function();

-- 12.2
drop trigger if exists delivery_is_not_shop_or_comment on delivery_complaint cascade;
create or replace function delivery_is_not_shop_or_comment_function()
returns trigger as 
$$
declare total_cnt integer;
        shop_complaint_cnt integer;
        comment_complaint_cnt integer;
begin
  select count(*) into shop_complaint_cnt
  from shop_complaint
  where id = new.id;
  select count(*) into comment_complaint_cnt
  from comment_complaint
  where id = new.id;
  select count(*) into total_cnt
  from complaint
  where id = new.id;
  if total_cnt = 1 and shop_complaint_cnt = 0 and comment_complaint_cnt = 0 then
    return new;
  else
    raise exception 'Trigger 12: A complaint is either a delivery-related complaint, a shop-related complaint or a comment-related complaint (non-overlapping and covering).';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger delivery_is_not_shop_or_comment
after insert
on delivery_complaint
deferrable initially deferred
for each row
execute function delivery_is_not_shop_or_comment_function();

-- 12.3
drop trigger if exists shop_is_not_delivery_or_comment on shop_complaint cascade;
create or replace function shop_is_not_delivery_or_comment_function()
returns trigger as 
$$
declare total_cnt integer;
        delivery_complaint_cnt integer;
        comment_complaint_cnt integer;
begin
  select count(*) into delivery_complaint_cnt
  from delivery_complaint
  where id = new.id;
  select count(*) into comment_complaint_cnt
  from comment_complaint
  where id = new.id;
  select count(*) into total_cnt
  from complaint
  where id = new.id;
  if total_cnt = 1 and delivery_complaint_cnt = 0 and comment_complaint_cnt = 0 then
    return new;
  else
    raise exception 'Trigger 12: A complaint is either a delivery-related complaint, a shop-related complaint or a comment-related complaint (non-overlapping and covering).';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger shop_is_not_delivery_or_comment
after insert
on shop_complaint
deferrable initially deferred
for each row
execute function shop_is_not_delivery_or_comment_function();

-- 12.4
drop trigger if exists comment_is_not_delivery_or_shop on comment_complaint cascade;
create or replace function comment_is_not_delivery_or_shop_function()
returns trigger as 
$$
declare total_cnt integer;
        delivery_complaint_cnt integer;
        shop_complaint_cnt integer;
begin
  select count(*) into delivery_complaint_cnt
  from delivery_complaint
  where id = new.id;
  select count(*) into shop_complaint_cnt
  from shop_complaint
  where id = new.id;
  select count(*) into total_cnt
  from complaint
  where id = new.id;
  if total_cnt = 1 and delivery_complaint_cnt = 0 and shop_complaint_cnt = 0 then
    return new;
  else
    raise exception 'Trigger 12: A complaint is either a delivery-related complaint, a shop-related complaint or a comment-related complaint (non-overlapping and covering).';
    return null;
  end if;
end;
$$
language plpgsql;

create constraint trigger comment_is_not_delivery_or_shop
after insert
on comment_complaint
deferrable initially deferred
for each row
execute function comment_is_not_delivery_or_shop_function();

-- Procedures
create or replace procedure place_order(u_id INTEGER, c_id INTEGER, shipping_address TEXT, shop_ids INTEGER[],
product_ids INTEGER[], sell_timestamps TIMESTAMP[], quantities INTEGER[], shipping_costs
NUMERIC[])
as $$
declare
  total_amount NUMERIC := 0;
  num_items INT := array_length(shop_ids, 1);
  coupon_discount NUMERIC := 0;
  minimum_amount NUMERIC := 0;
  order_id INT;
  amount NUMERIC;
  item_count INT;
begin
  -- Ensure all arrays have equal length
  if not (array_length(shop_ids, 1) = array_length(product_ids, 1)
  and array_length(shop_ids, 1) = array_length(sell_timestamps, 1)
  and array_length(shop_ids, 1) = array_length(quantities, 1)
  and array_length(shop_ids, 1) = array_length(shipping_costs, 1)) then
    raise exception 'Invalid array length';
  end if;

  -- Assign discount and min amount
  if (c_id is not null) then
    select min_order_amount, reward_amount into minimum_amount, coupon_discount
      from coupon_batch where id = c_id;
  end if;

  -- Calculate total amount of orders
  for i in 1..num_items loop
    -- Check if product belongs to shop
    if (select count(*) from sells where product_id = product_ids[i] and shop_id = shop_ids[i]) = 0 then
      raise exception 'Product % does not belong to shop %', product_ids[i], shop_ids[i];
    end if;

    select price, quantity into amount, item_count from sells where product_id = product_ids[i] and shop_id = shop_ids[i];
    
    -- Check if item is in stock
    if (item_count < quantities[i]) then
      raise exception 'Product % does not have enough stock for % quantity', product_ids[i], quantities[i];
    end if;
    
    -- Add to total amount
    total_amount := total_amount + amount * quantities[i] + shipping_costs[i];

  end loop;

  -- Apply coupon
  if (total_amount < coupon_discount) then
    total_amount = 0;
  else
    total_amount = total_amount - coupon_discount;
  end if;

  -- Create Order
  insert into orders (user_id, coupon_id, shipping_address, payment_amount)
    values (u_id, c_id, shipping_address, total_amount);
  select max(id) into order_id from orders;

  -- Create Order_lines and update sells table with new quantities
  for i in 1..num_items loop
    insert into orderline (order_id, shop_id, product_id, sell_timestamp, quantity, shipping_cost, status)
    values (order_id, shop_ids[i], product_ids[i], sell_timestamps[i], quantities[i], shipping_costs[i], 'being_processed');
    update sells set quantity = quantity - quantities[i] where product_id = product_ids[i] and shop_id = shop_ids[i];
  end loop;

end;

$$ language plpgsql;

create or replace procedure review(user_id INTEGER, order_id INTEGER, shop_id INTEGER, product_id INTEGER, sell_timestamp
TIMESTAMP, content TEXT, rating INTEGER, comment_timestamp TIMESTAMP)
as $$
declare
  comment_id INT;
  review_id INT;
begin
  insert into comment (user_id) values (user_id);
  select max(id) into comment_id from comment;
  insert into review (id, order_id, shop_id, product_id, sell_timestamp) 
    values (comment_id, order_id, shop_id, product_id, sell_timestamp);
  select max(id) into review_id from review;
  insert into review_version (review_id, review_timestamp, content, rating)
    values (review_id, comment_timestamp, content, rating);
end;

$$ language plpgsql;

create or replace procedure reply(user_id INTEGER, other_comment_id INTEGER, content TEXT, reply_timestamp TIMESTAMP)
as $$
declare
  comment_id INT;
  reply_id INT;
begin
  insert into comment (user_id) values (user_id);
  select max(id) into comment_id from comment;
  insert into reply (id, other_comment_id) values (comment_id, other_comment_id);
  select max(id) into reply_id from reply;
  insert into reply_version (reply_id, reply_timestamp, content)
    values (reply_id, reply_timestamp, content);
end;

$$ language plpgsql;

-- Functions

CREATE OR REPLACE FUNCTION view_comments(IN shop_id_input INTEGER, IN product_id_input INTEGER, IN sell_timestamp_input TIMESTAMP )
RETURNS TABLE ( username TEXT, content TEXT, rating INTEGER, comment_timestamp TIMESTAMP ) AS $$

with RECURSIVE included_replies(id) AS (
    SELECT id 
    FROM review R 
    WHERE R.shop_id = shop_id_input
    AND R.product_id = product_id_input
    AND R.sell_timestamp = sell_timestamp_input
    UNION ALL 
    SELECT R.id
    FROM included_replies IR, reply R
    WHERE R.other_comment_id = IR.id
),
all_comment_ids AS (
    SELECT * FROM included_replies
),
all_comments AS (
    SELECT user_id, RV.review_id as comment_id, RV.content, RV.rating, RV.review_timestamp as comment_timestamp
    FROM review_version RV 
        LEFT JOIN comment C
        ON RV.review_id = C.id
    WHERE RV.review_id IN (
        SELECT * FROM all_comment_ids
        )
        AND RV.review_timestamp >= all (
            SELECT review_timestamp
            FROM review_version RV2
            WHERE RV.review_id = RV2.review_id
        )
    UNION ALL
    SELECT user_id, RE.reply_id as comment_id, RE.content, NULL AS rating, RE.reply_timestamp as comment_timestamp
    FROM reply_version RE
        LEFT JOIN comment C
        ON RE.reply_id = C.id
    WHERE RE.reply_id IN (
        SELECT * FROM all_comment_ids
        )
        AND RE.reply_timestamp >= all (
            SELECT reply_timestamp
            FROM reply_version RE2
            WHERE RE.reply_id = RE2.reply_id
        )
)
SELECT case 
        when U.account_closed 
        then 'A Deleted User' 
        else U.name
       end as username, AC.content, AC.rating, AC.comment_timestamp
FROM users U, all_comments AC
WHERE U.id = AC.user_id
ORDER BY AC.comment_timestamp, AC.comment_id; 

$$ LANGUAGE sql;




CREATE OR REPLACE FUNCTION get_most_returned_products_from_manufacturer(IN manufacturer_id INTEGER, IN n INTEGER)
RETURNS TABLE (product_id INTEGER, product_name TEXT, return_rate NUMERIC(3, 2)) AS $$

with product_manufacturer as (
  select id, name from product
  where manufacturer = manufacturer_id
)

SELECT product_id, product_name, 
(case when num_delivered = 0 then 0.00 else CAST(coalesce(num_returned/num_delivered, 0) AS NUMERIC(3,2)) end) AS return_rate
FROM (
  SELECT product_manufacturer.id AS product_id, product_manufacturer.name as product_name, CAST(coalesce(temp.num_returned, 0.0) AS NUMERIC(3,2)) AS num_returned, CAST(coalesce(temp.num_delivered, 0.0) AS NUMERIC(3,2)) AS num_delivered
  FROM (product_manufacturer LEFT JOIN (
      
      SELECT t1.product_id, t1.num_delivered, t2.num_returned
      FROM (
          (SELECT orderline.product_id, sum(orderline.quantity) AS num_delivered
          FROM orderline
          WHERE orderline.status = 'delivered' AND orderline.product_id IN (
              SELECT id
              FROM product
              WHERE manufacturer = manufacturer_id
              )
          GROUP BY orderline.product_id
          ) AS t1   
          LEFT JOIN 
          (SELECT refund_request.product_id, sum(refund_request.quantity) AS num_returned
          FROM refund_request
          WHERE refund_request.status = 'accepted' AND refund_request.product_id IN (
              SELECT id
              FROM product
              WHERE manufacturer = manufacturer_id
              )
          GROUP BY refund_request.product_id
          ) AS t2
          ON t1.product_id = t2.product_id
      )
  ) AS temp ON product_manufacturer.id = temp.product_id)
) AS temp2

ORDER BY return_rate DESC, product_id
LIMIT n;

$$ LANGUAGE sql;




CREATE OR REPLACE FUNCTION get_worst_shops (IN n INTEGER)
RETURNS TABLE ( shop_id INTEGER, shop_name TEXT, num_negative_indicators INTEGER ) AS $$

with t1 AS (
    SELECT shop_id, count(*) as c1
    FROM (SELECT DISTINCT order_id, shop_id, product_id, sell_timestamp
        FROM refund_request) AS distinct_order_requests
    GROUP BY shop_id
),
t2 AS (
    SELECT shop_id, count(*) as c2
    FROM shop_complaint
    GROUP BY shop_id
),
t3 AS (
    SELECT shop_id, count(*) as c3
    FROM (SELECT DISTINCT order_id, shop_id, product_id, sell_timestamp
        FROM delivery_complaint 
        where (
          select status from orderline
          where order_id = delivery_complaint.order_id
          and shop_id = delivery_complaint.shop_id
          and product_id = delivery_complaint.product_id
          and sell_timestamp = delivery_complaint.sell_timestamp
        ) = 'delivered') AS distinct_order_complaints
    GROUP BY shop_id
),
t4 AS(
    with one_star_reviews AS (
        SELECT review_id, rating 
        FROM review_version RV
        WHERE review_timestamp >= all (
            SELECT review_timestamp
            FROM review_version RV2
            WHERE RV.review_id = RV2.review_id
        ) AND rating = 1
    ) 
    SELECT shop_id, count(*) as c4
    FROM one_star_reviews LEFT JOIN review ON one_star_reviews.review_id = review.id
    GROUP BY shop_id
),
t12 AS (
    SELECT case when t1.shop_id IS NOT NULL
                then t1.shop_id
                else t2.shop_id
            end as s12, coalesce(c1, 0) AS c1, coalesce(c2, 0) AS c2
    FROM t1 FULL OUTER JOIN t2 ON t1.shop_id = t2.shop_id
),
t123 AS (
    SELECT case when t12.s12 IS NOT NULL
                then t12.s12
                else t3.shop_id
            end as s123, coalesce(c1, 0) as c1, coalesce(c2, 0) as c2, coalesce(c3, 0) AS c3
    FROM t12 FULL OUTER JOIN t3 ON t12.s12 = t3.shop_id 
),
t1234 AS (
    SELECT case when t123.s123 IS NOT NULL
                then t123.s123
                else t4.shop_id
            end as s1234, coalesce(c1, 0) as c1, coalesce(c2, 0) as c2, coalesce(c3, 0) as c3, coalesce(c4, 0) AS c4
    FROM t123 FULL OUTER JOIN t4 ON t123.s123 = t4.shop_id
)

SELECT shop.id as shop_id, shop.name as shop_name, coalesce(c1 + c2 + c3 + c4, 0) as num_negative_indicators
FROM shop LEFT JOIN t1234 ON t1234.s1234 = shop.id
ORDER BY num_negative_indicators DESC, shop_id
LIMIT n;

$$ LANGUAGE sql;

