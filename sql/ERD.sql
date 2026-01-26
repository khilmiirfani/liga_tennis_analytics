Project liga_tenis {
  database_type: "MySQL"
  Note: "Inferred ERD based on provided table/column list. Some FKs are inferred."
}

/* =========================
   Core reference entities
========================= */

Table v_venues {
  item_id int [pk]
  title varchar
  Note: "View. Represents venue/branch items (item_type=66 in mod_items)."
}

Table courts {
  id int [pk]
  court_id int
  title varchar
  description text
  surface int
  order_index int
  active tinyint
  online_booking tinyint
  work_hours varchar
  booking_time_step int
  cover_type varchar
  type varchar
  config text
  sport_type_id int
  created_at timestamp
  deleted_at timestamp

  Note: "Contains court metadata. Many tables use court_id as branch/venue id; this ERD keeps both courts.id and courts.court_id."
}

Table courts_coords {
  court_id int
  lat float
  lng float
}

/* =========================
   Booking domain
========================= */

Table court_booking_occurrences {
  id int [pk]
  court_id int
  start_at date
  repeat_type varchar
  schedule_config text
  created_at timestamp
  deleted_at timestamp
}

Table court_bookings {
  id int [pk]
  uuid varchar
  court_id int
  occurrence_id int
  created_by int
  updated_by int

  is_public tinyint
  disable_edit tinyint

  date date
  time_from varchar
  time_to varchar
  type enum
  approved tinyint
  hidden tinyint
  hidden_at timestamp
  hidden_by int

  cancelled_no_fee tinyint
  payment_status varchar
  payment_resolved datetime

  user_id int
  coach_id int
  coach_type_id int
  event_id int

  participants_limit int
  title varchar
  name varchar
  phone varchar
  email varchar

  price float
  additional_payment float
  coins_price float
  coins_transaction_id int
  discount_id int
  rule_id int

  content text
  user_comment text
  package_id int

  created_at timestamp
  updated_at timestamp
  canceled_at timestamp
  deleted_at timestamp
  deleted_by int

  platform varchar
  tags varchar
}

Table court_bookings_participants {
  id int [pk]
  booking_id int
  user_id int
  payment_status varchar
  net_price decimal
  price decimal
  activity_player_id int
  autocancel_at datetime
  created_at timestamp
  deleted_at timestamp
  deleted_by int
}

Table court_bookings_assignments {
  id int [pk]
  booking_id int
  record_id int
  type varchar
  created_at timestamp
  deleted_at datetime
}

/* =========================
   Extras (add-ons) domain
========================= */

Table court_extras {
  id int [pk]
  court_id int
  active tinyint
  online_booking tinyint
  title varchar
  description text
  price float
  order_index int
  all_courts tinyint
  created_at timestamp
  deleted_at timestamp
}

Table court_booking_extras {
  id int [pk]
  booking_id int
  participant_id int
  extra_id int
  price float
  qty int
  created_at timestamp
  deleted_at timestamp
}

Table court_extras_assignments {
  id int [pk]
  extra_id int
  type varchar
  record_id int
  created_at timestamp
  deleted_at timestamp
}

/* =========================
   Coaching domain
========================= */

Table court_coaches {
  id int [pk]
  court_id int
  user_id int
  type_id int
  additional_type_id text
  name varchar
  email varchar
  phone varchar
  note text
  order_index int
  active tinyint
  show_description tinyint
  description text
  rate decimal
  rate_qty int
  created_at timestamp
  deleted_at timestamp
}

Table court_coaches_types {
  id int [pk]
  court_id int
  title varchar
  price float
  coins_price float
  color_label varchar
  description longtext
  config longtext
  order_index int
  created_at timestamp
  deleted_at timestamp
}

Table court_coaches_schedule {
  id int [pk]
  court_id int
  coach_id int
  date date
  time_from varchar
  time_to varchar
  type varchar
  created_at timestamp
  updated_at timestamp
}

Table court_coaches_assignments {
  id int [pk]
  coach_id int
  type varchar
  record_id int
  created_at timestamp
  deleted_at timestamp
}

/* =========================
   Events domain
========================= */

Table court_events {
  id int [pk]
  court_id int
  title varchar
  url_key varchar
  content text
  image varchar
  video varchar
  price float
  coins_price float
  is_free tinyint
  active tinyint
  online_registration tinyint
  limit int
  config text
  registration_message text
  sport_type_id int
  gender tinyint
  coach_id int
  instant_booking tinyint
  online_payments tinyint
  mondatory_online_payments tinyint
  created_at timestamp
  deleted_at timestamp
}

Table court_event_users {
  id int [pk]
  booking_id int
  event_id int
  user_id int
  user_type varchar
  type varchar
  price float
  coins_price float
  coins_transaction_id int
  discount_id int
  discount_amount float
  payment_status varchar
  package_id int
  occurrence tinyint
  tags varchar
  data longtext
  created_at timestamp
  created_by int
  updated_at timestamp
  updated_by int
  moved_from_waiting_list_at timestamp
  deleted_at timestamp
  deleted_by int
}

Table court_event_images {
  id int [pk]
  event_id int
  image varchar
  order_index int
  created_at timestamp
  deleted_at timestamp
}

/* =========================
   Orders / retail domain
========================= */

Table court_orders {
  id int [pk]
  uuid varchar
  order_number varchar
  court_id int
  author_id int
  customer_id int
  amount float
  note text
  status varchar
  completed_at timestamp
  completed_by int
  payment_status varchar
  created_at timestamp
  deleted_at timestamp
  deleted_by int
}

Table court_orders_items {
  id int [pk]
  order_id int
  author_id int
  item_id int
  item_type varchar
  qty int
  item_price float
  subtotal_price float
  created_at timestamp
  deleted_at timestamp
}

Table court_products {
  id int [pk]
  court_id int
  title varchar
  sku varchar
  price float
  net_price float
  category_id int
  in_stock int
  active tinyint
  image varchar
  tags varchar
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp
}

Table court_products_categories {
  id int [pk]
  court_id int
  title varchar
  order_index int
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp
}

Table court_products_inventory {
  id int [pk]
  product_id int
  qty int
  order_id int
  created_at timestamp
  added_by int
}

Table court_products_tags {
  id int [pk]
  court_id int
  title varchar
  order_index int
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp
}

/* =========================
   Packages & membership
========================= */

Table courts_packages {
  id int [pk]
  court_id int
  title varchar
  type varchar
  content text
  active tinyint
  bookings_count int
  duration int
  price decimal
  config text
  created_by int
  created_at timestamp
  deleted_at timestamp
  deleted_by int
}

Table courts_customers_packages {
  id int [pk]
  court_id int
  package_id int
  customer_id int
  title varchar
  type varchar
  content text
  active tinyint
  expires_at date
  bookings_count int
  config text
  bookings_count_notified_at timestamp
  sales_person_type varchar
  sales_person_id int
  booking_future_time_limit int
  created_by int
  created_at timestamp
  deleted_at timestamp
}

Table courts_customers_memberships_history {
  id int [pk]
  customer_id int
  old_is_member tinyint
  old_member_type int
  old_membership_valid_from date
  old_membership_valid_to date
  new_is_member tinyint
  new_member_type int
  new_membership_valid_from date
  new_membership_valid_to date
  updated_by int
  updated_at timestamp
}

Table courts_member_types {
  id int [pk]
  court_id int
  title varchar
  active tinyint
  order_index int
  created_at timestamp
  deleted_at timestamp
}

Table courts_member_type_rules {
  id int [pk]
  court_id int
  type_id int
  title varchar
  type varchar
  action varchar
  active tinyint
  config text
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp
}

/* =========================
   Customers (view)
========================= */

Table v_courts_customers {
  id int [pk]
  court_id int
  user_id int
  is_member tinyint
  member_type int
  member_card_number varchar
  first_name varchar
  last_name varchar
  status varchar
  note text
  membership_valid_from date
  membership_valid_to date
  send_expire_email_at datetime
  expire_email_sent_at datetime
  has_no_fee_cancellation tinyint
  locally_based tinyint
  created_at timestamp
  deleted_at timestamp

  Note: "View. Customer dimension (memberships, profile fields)."
}

/* =========================
   Reviews & tags (optional)
========================= */

Table courts_customers_reviews {
  id int [pk]
  venue_id int
  user_id int
  customer_id int
  type varchar
  booking_id int
  space_id int
  class_id int
  coach_id int
  text longtext
  rate tinyint
  request_at timestamp
  reviewed_at timestamp
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp
}

Table courts_customers_tags {
  id int [pk]
  venue_id int
  title varchar
  created_at timestamp
  updated_at timestamp
  deleted_at timestamp
}

Table courts_customers_tags_assignments {
  id int [pk]
  customer_id int
  tag_id int
  deleted_at timestamp
}

/* =========================
   Relationships (inferred)
========================= */

Ref: courts_coords.court_id > courts.court_id

Ref: court_booking_occurrences.court_id > courts.court_id
Ref: court_bookings.occurrence_id > court_booking_occurrences.id

Ref: court_bookings_participants.booking_id > court_bookings.id
Ref: court_booking_extras.booking_id > court_bookings.id
Ref: court_booking_extras.extra_id > court_extras.id
Ref: court_booking_extras.participant_id > court_bookings_participants.id

Ref: court_extras.court_id > courts.court_id
Ref: court_extras_assignments.extra_id > court_extras.id

Ref: court_coaches.court_id > courts.court_id
Ref: court_coaches.type_id > court_coaches_types.id
Ref: court_coaches_types.court_id > courts.court_id
Ref: court_coaches_schedule.coach_id > court_coaches.id
Ref: court_coaches_schedule.court_id > courts.court_id
Ref: court_bookings.coach_id > court_coaches.id
Ref: court_bookings.coach_type_id > court_coaches_types.id

Ref: court_events.court_id > courts.court_id
Ref: court_events.coach_id > court_coaches.id
Ref: court_event_users.booking_id > court_bookings.id
Ref: court_event_users.event_id > court_events.id
Ref: court_event_images.event_id > court_events.id

Ref: court_orders.court_id > courts.court_id
Ref: court_orders_items.order_id > court_orders.id
Ref: court_products.court_id > courts.court_id
Ref: court_orders_items.item_id > court_products.id
Ref: court_products_categories.id < court_products.category_id

Ref: courts_packages.court_id > courts.court_id
Ref: court_bookings.package_id > courts_packages.id
Ref: courts_customers_packages.package_id > courts_packages.id
Ref: courts_customers_packages.court_id > courts.court_id



Ref: "court_extras"."online_booking" < "court_extras"."description"