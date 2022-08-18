drop table if exists users, shop, category, manufacturer, product, sells, coupon_batch, issued_coupon, orders, orderline, comment, review, review_version, reply, reply_version, employee, refund_request, complaint, shop_complaint, comment_complaint, delivery_complaint cascade;

drop type if exists orderline_status, refund_status, complaint_status cascade;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    address TEXT,
    name TEXT,
    account_closed BOOLEAN
);

CREATE TABLE shop (
    id SERIAL PRIMARY KEY,
    name TEXT
);

-- Combines Category, Has
CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    name TEXT,
    parent INTEGER REFERENCES category(id)
);

CREATE TABLE manufacturer (
    id SERIAL PRIMARY KEY,
    name TEXT,
    country TEXT
);

-- Combines Product, Belongs to, Manufactured by
CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    name TEXT,
    description TEXT,
    -- Enforce Key+TP constraint
    category INTEGER NOT NULL REFERENCES category(id),
    -- Enforce Key+TP constraint
    manufacturer INTEGER NOT NULL REFERENCES manufacturer(id)
);

CREATE TABLE sells (
    shop_id INTEGER REFERENCES shop(id),
    product_id INTEGER REFERENCES product(id),
    sell_timestamp TIMESTAMP,
    price NUMERIC,
    quantity INTEGER,
    PRIMARY KEY (shop_id, product_id, sell_timestamp)
);

CREATE TABLE coupon_batch (
    id SERIAL PRIMARY KEY,
    valid_period_start DATE,
    valid_period_end DATE,
    reward_amount NUMERIC,
    min_order_amount NUMERIC,
    -- Enforce constraint that reward amount is lower than minimum order_amount
    CHECK (reward_amount <= min_order_amount),
    -- Enforce cnonstraint that start date <= end date
    CHECK (valid_period_start <= valid_period_end)
);

CREATE TABLE issued_coupon (
    user_id INTEGER REFERENCES users(id),
    coupon_id INTEGER REFERENCES coupon_batch(id),
    PRIMARY KEY (user_id, coupon_id)
);

-- Combines Order, Places, Applies
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
     -- Enforce Key+TP constraint
    user_id INTEGER REFERENCES users(id) NOT NULL,
    coupon_id INTEGER,
    shipping_address TEXT,
    payment_amount NUMERIC,
    -- Enforce constraint that user can only use a coupon that was issued to them
    FOREIGN KEY (user_id, coupon_id) REFERENCES issued_coupon(user_id, coupon_id),
    -- Enforce constraint that a particular issued coupon can only be applied once
    UNIQUE (user_id, coupon_id)
);

CREATE TYPE orderline_status AS ENUM (
    'being_processed', 
    'shipped', 
    'delivered'
);

-- Rename Involves to Orderline
CREATE TABLE orderline (
    order_id INTEGER REFERENCES orders(id),
    shop_id INTEGER,
    product_id INTEGER,
    sell_timestamp TIMESTAMP,
    quantity INTEGER,
    shipping_cost NUMERIC,
    status orderline_status,
    delivery_date DATE,
    FOREIGN KEY (shop_id, product_id, sell_timestamp) REFERENCES sells(shop_id, product_id, sell_timestamp),
    PRIMARY KEY (order_id, shop_id, product_id, sell_timestamp),
    -- Enforce constraint that delivery date is null when being_processed, and not null otherwise
    CHECK ((status = 'being_processed' AND delivery_date IS NULL) OR (status <> 'being_processed' AND delivery_date IS NOT NULL))
);

-- Combines Comment, Makes
CREATE TABLE comment (
    id SERIAL PRIMARY KEY,
    -- Enforce Key+TP constraint
    user_id INTEGER REFERENCES users(id) NOT NULL
);

-- Combines Review, On
CREATE TABLE review (
    id INTEGER PRIMARY KEY REFERENCES comment(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    order_id INTEGER NOT NULL,
    shop_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    sell_timestamp TIMESTAMP NOT NULL,
    FOREIGN KEY (order_id, shop_id, product_id, sell_timestamp) REFERENCES orderline(order_id, shop_id, product_id, sell_timestamp),
    -- Enforce constraint that a particular product purchase can only be reviewed once
    UNIQUE (order_id, shop_id, product_id, sell_timestamp)
);

-- Combines ReviewVersion, HasReviewVersion
CREATE TABLE review_version (
    review_id INTEGER REFERENCES review ON DELETE CASCADE,
    review_timestamp TIMESTAMP,
    content TEXT,
    rating INTEGER,
    PRIMARY KEY (review_id, review_timestamp),
    -- Enforce range of values for rating
    CHECK (1 <= rating AND rating <= 5)
);

-- Combines Reply, To
CREATE TABLE reply (
    id INTEGER PRIMARY KEY REFERENCES comment(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    other_comment_id INTEGER REFERENCES comment(id) NOT NULL
);

-- Combines Reply_Version, HasReplyVersion
CREATE TABLE reply_version (
    reply_id INTEGER REFERENCES reply ON DELETE CASCADE,
    reply_timestamp TIMESTAMP,
    content TEXT,
    PRIMARY KEY (reply_id, reply_timestamp)
);

CREATE TABLE employee (
    id SERIAL PRIMARY KEY,
    name TEXT,
    salary NUMERIC
);

CREATE TYPE refund_status AS ENUM (
    'pending',
    'being_handled',
    'accepted',
    'rejected'
);

-- Combines RefundRequest, HandlesRefund, For
CREATE TABLE refund_request (
    id SERIAL PRIMARY KEY,
    -- Enforce key constraint
    handled_by INTEGER REFERENCES employee(id),
    -- Enforce key + tp constraint
    order_id INTEGER NOT NULL,
    shop_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    sell_timestamp TIMESTAMP NOT NULL,
    quantity INTEGER,
    request_date DATE,
    status refund_status,
    handled_date DATE,
    rejection_reason TEXT,
    FOREIGN KEY (order_id, shop_id, product_id, sell_timestamp) REFERENCES orderline(order_id, shop_id, product_id, sell_timestamp),
    -- Enforce constraint that refund is accepted/rejected after the request is made
    CHECK (handled_date >= request_date),
    -- Enforce constraint that rejection reason should be null unless refund request is rejected
    CHECK ((status = 'rejected' AND rejection_reason IS NOT NULL) OR (status <> 'rejected' AND rejection_reason IS NULL)),
    -- Enforce constraint that refund handled_date should be null unless refund is handled
    CHECK (((status = 'pending' OR status = 'being_handled') AND handled_date IS NULL) OR ((status = 'accepted' OR status = 'rejected') AND handled_date IS NOT NULL)),
    -- Enforce constraint that refund handled_by should be null if status is pending, and non-null otherwise
    CHECK (((status = 'pending' AND handled_by IS NULL) OR (status <> 'pending' AND handled_by IS NOT NULL)))
);

CREATE TYPE complaint_status AS ENUM (
    'pending',
    'being_handled',
    'addressed'
);

-- Combines Complaint, HandlesComplaint, Files
CREATE TABLE complaint (
    id SERIAL PRIMARY KEY,
    content TEXT,
    status complaint_status,
    user_id INTEGER REFERENCES users(id),
    -- Enforce key constraint
    handled_by INTEGER REFERENCES employee(id),
    -- Enforce valid values for status and handled_by
    CHECK ((status = 'pending' AND handled_by IS NULL) OR (status <> 'pending' AND handled_by IS NOT NULL))
);

-- Combines ShopComplaint, ConcernsShop
CREATE TABLE shop_complaint (
    id INTEGER PRIMARY KEY REFERENCES complaint(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    shop_id INTEGER REFERENCES shop(id) NOT NULL
);

-- Combines CommentComplaint, ConcernsComment
CREATE TABLE comment_complaint (
    id INTEGER PRIMARY KEY REFERENCES complaint(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    comment_id INTEGER REFERENCES comment(id) NOT NULL
);

-- Combines DeliveryComplaint, ConcernsDelivery
CREATE TABLE delivery_complaint (
    id INTEGER PRIMARY KEY REFERENCES complaint(id) ON DELETE CASCADE,
    -- Enforce Key+TP constraint
    order_id INTEGER NOT NULL,
    shop_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    sell_timestamp TIMESTAMP NOT NULL,
    FOREIGN KEY (order_id, shop_id, product_id, sell_timestamp) REFERENCES orderline(order_id, shop_id, product_id, sell_timestamp)
);
