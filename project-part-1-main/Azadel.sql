-- -- CS2102 Project (Part 1)
-- -- Group 56

-- -- For convenience. https://stackoverflow.com/questions/3327312/how-can-i-drop-all-the-tables-in-a-postgresql-database
-- -- Note that all names of all schema are public. This will delete all functions views, etc. defined in the public schema.
-- -- But it will not remove the system tables as they are in a different schema.
-- drop schema public cascade;
-- create schema public;

create table Shop (
    shop_id     integer,
    shop_name   varchar(50) not null,
    primary key (shop_id)
);

create table Category (
    category_id         integer,
    category_name       varchar(50) not null,
    parent_category_id  integer,
    primary key (category_id),
    foreign key (parent_category_id) references Category
);

create table Manufacturer (
    manufacturer_id         integer,
    manufacturer_name       varchar(50) not null,
    manufacturer_country    varchar(50) not null,
    primary key (manufacturer_id)
);

create table Product (
    product_id          integer,
    product_name        varchar(50) not null,
    category_id         integer not null, --key & total (Belongs)
    manufacturer_id     integer not null, --key & total (Produces)
    product_description text,
    primary key (product_id),
    foreign key (category_id) references Category,
    foreign key (manufacturer_id) references Manufacturer
);

create table Sells (
    shop_id     integer references Shop on delete cascade,
    product_id  integer,
    quantity    integer not null,
    price       float not null,
    primary key (shop_id, product_id),
    foreign key (product_id) references Product on delete cascade
);

create table Employee (
    employee_id     integer,
    employee_name   varchar(50) not null,
    monthly_salary  float not null,
    primary key (employee_id)
);

create table Customer (
    user_id         integer,
    user_name       varchar(50) not null,
    account_status  varchar(20) default 'active' not null, 
    user_address    text,
    primary key (user_id),
    check(account_status in ('active', 'deleted'))
);

create table Order_item ( -- this is an order table for order items
    -- if a product in the product table is deleted,
    -- then the order item will also be deleted (weak entity)
    order_id                    integer,
    user_id                     integer not null, --key & total (Places)
    product_id                  integer, -- key & total (Involves)
    ordered_product_quantity    integer not null,
    shipping_cost               float not null,
    shipping_address            text not null,
    total_cost                  float not null,
    order_status                varchar(20) default 'being processed' not null,
    estimated_delivery_date     date,
    actual_delivery_date        date,
    primary key (order_id, product_id), -- weak entity
    foreign key (user_id) references Customer,
    foreign key (product_id) references Product on delete cascade, -- weak entity
    check(order_status in ('being processed', 'shipped', 'delivered', 'requested for refund')),
    check((order_status <> 'request for refund') or (ordered_product_quantity > 1))
);

create table Refund_request (
    refund_request_id               integer,
    order_id                        integer not null,
    product_id                      integer not null,
    employee_id                     integer,
    reason_of_rejection             text,
    number_of_instances             integer not null,
    date_of_request                 date not null,
    request_status                  varchar(20) default 'pending' not null,
    date_of_acceptance_or_rejection date,
    primary key (refund_request_id),
    foreign key (order_id, product_id) references Order_item
                on delete cascade,
    foreign key (employee_id) references Employee,
    check(request_status in ('accepted', 'rejected', 'pending')),
    check(
        ((reason_of_rejection is null) or (request_status = 'rejected'))
        and ((reason_of_rejection is not null) or (request_status <> 'rejected'))
    ),
    check(
        ((date_of_acceptance_or_rejection is null) or (request_status <> 'pending'))
        and ((date_of_acceptance_or_rejection is not null) or (request_status = 'pending'))
    )
);

create table Review (
    review_id       integer,
    order_id        integer not null,
    product_id      integer not null,
    rate            integer,
    comment         text,
    rate_status     varchar(20) default 'active',
    comment_status  varchar(20) default 'active',
    primary key (review_id),
    unique (order_id, product_id),
    foreign key (order_id, product_id) references Order_item(order_id, product_id)
                on delete cascade,
    check(rate in (1, 2, 3, 4, 5)),
    check(rate_status in ('active', 'deleted')),
    check(comment_status in ('active', 'deleted')),
    check((rate is not null and rate_status is not null) or ((comment is not null) and (comment_status is not null)))
);

create table Writes_review (
    user_id     integer not null,
    review_id   integer,
    order_id    integer not null,
    product_id  integer not null,

    primary key (review_id),
    unique (order_id, product_id),
    foreign key (user_id) references Customer,
    foreign key (review_id) references Review(review_id) on delete cascade, -- deletion of review_id technically should not happen, because if a review (comment) is inactive, we can just change the 'comment_status' attribute without deleting the tuple in the 'Review' entity. We are putting 'on delete cascade' here just in case the database manager wants to make such changes.
    foreign key (order_id, product_id) references Order_item on delete cascade
);

create table Reply (
    reply_id        integer,
    reply_content   text not null,
    review_id       integer not null,
    reply_status    varchar(20) default 'active' not null,
    primary key (reply_id),
    foreign key (review_id) references Review(review_id)
                on delete cascade,
    check (reply_status in ('active', 'deleted'))
    -- It is possible that the referenced review_id is a review with only rate and no comment. This constraint is not captured in this relational schema but we think might be enforced by more advanced features later.
);

create table Writes_reply (
    user_id     integer not null,
    review_id   integer not null,
    reply_id    integer,
    primary key (reply_id),
    foreign key (user_id) references Customer,
    foreign key (reply_id) references Reply on delete cascade, -- deletion of reply_id technically should not happen, because if a reply is inactive, we can just change the 'reply_status' attribute without deleting the tuple in the Reply entity. We are putting 'on delete cascade' here just to be safe.
    foreign key (review_id) references Review(review_id) on delete cascade -- Similarly, the deletion of a review_id technically should not happen, because if a review (comment) is inactive, we can just change the 'comment_status' attribute without deleting the tuple in the Review entity. We are putting 'on delete cascade' here just in case the database manager wants to make such changes.
    -- It is possible that the referenced review_id is a review with only rate and no comment. This constraint is not captured in this relational schema but we think might be enforced by more advanced features later.
);

create table Coupon (
    coupon_id       integer,
    batch_id        integer not null,
    min_order_value float not null,
    validity_period date not null,
    reward          float not null,
    order_id        integer,
    product_id      integer,
    primary key (coupon_id),
    unique (order_id),
    foreign key (order_id, product_id) references Order_item (order_id, product_id) on delete set null
);

create table Uses (
    user_id     integer not null,
    coupon_id   integer,
    order_id    integer not null,
    product_id  integer not null,
    primary key (coupon_id),
    unique (order_id),
    foreign key (user_id) references Customer,
    foreign key (coupon_id) references Coupon on delete cascade,
    foreign key (order_id, product_id) references Order_item (order_id, product_id) on delete cascade
);

create table Complaint (
    complaint_id        integer,
    complaint_content   text not null,
    complaint_status    varchar(20) default 'pending' not null,
    employee_id         integer,
    user_id             integer not null, -- files
    primary key (complaint_id),
    foreign key (user_id) references Customer,
    foreign key (employee_id) references Employee,
    check (complaint_status in ('pending', 'being processed', 'addressed')),
    check ((employee_id is null) or (complaint_status <> 'pending')),
    check ((employee_id is not null) or (complaint_status <> 'being processed'))
);

create table ProductComplaint (
    complaint_id            integer primary key references Complaint
                            on delete cascade,
    order_id                integer not null,
    product_id              integer not null,
    foreign key (order_id, product_id) references Order_item on delete cascade
);

create table ShopComplaint (
    complaint_id        integer primary key references Complaint
                        on delete cascade,
    shop_id             integer not null,
    foreign key (shop_id) references Shop on delete cascade
);

create table CommentComplaint (
    complaint_id            integer primary key references Complaint
                            on delete cascade,
    review_id               integer not null,
    category                varchar(50),
    foreign key (review_id) references Review(review_id) on delete cascade
);
