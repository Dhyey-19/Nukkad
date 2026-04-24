-- Dummy Data Insertion Script
-- Ensure you have at least 2 users in the 'nkd_users' table before running this script.
-- You can replace the subqueries with actual user_ids if needed.

-- 1. Insert Business Categories
INSERT INTO business_categories (category_name, icon_name, is_active) VALUES
('Restaurants', 'restaurant', true),
('Plumbers', 'plumbing', true),
('Electricians', 'electrical_services', true),
('Grocery Stores', 'local_grocery_store', true),
('Pharmacies', 'local_pharmacy', true)
ON CONFLICT (category_name) DO NOTHING;

-- 2. Insert Businesses
INSERT INTO nkd_businesses (
    user_id, business_name, business_category, description, address, city, state, pincode, 
    latitude, longitude, phone, email, website, is_verified, is_active, rating_average, total_reviews
) VALUES
(
    (SELECT user_id FROM nkd_users ORDER BY user_id LIMIT 1), 
    'Sharma Sweets & Snacks', 'Restaurants', 'Authentic Indian sweets and snacks.', 
    '12, Main Market Road', 'Mumbai', 'Maharashtra', '400001', 
    18.9220, 72.8347, '+91-9876543210', 'info@sharmasweets.com', 'www.sharmasweets.com', 
    true, true, 4.5, 120
),
(
    (SELECT user_id FROM nkd_users ORDER BY user_id OFFSET 1 LIMIT 1), 
    'QuickFix Plumbing', 'Plumbers', '24/7 plumbing services for residential and commercial.', 
    'Shop No 4, Station Road', 'Mumbai', 'Maharashtra', '400052', 
    19.0760, 72.8777, '+91-9988776655', 'contact@quickfixplumbing.in', NULL, 
    true, true, 4.2, 45
);

-- 3. Insert Subscriptions
INSERT INTO nkd_subscriptions (
    user_id, business_id, subscription_type, payment_amount, payment_status, payment_date, 
    connects_remaining, connects_total, is_active, start_date, end_date
) VALUES
(
    (SELECT user_id FROM nkd_users ORDER BY user_id LIMIT 1), 
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'Sharma Sweets & Snacks' LIMIT 1), 
    'yearly', 4999.00, 'completed', NOW() - INTERVAL '10 days', 
    100, 100, true, NOW() - INTERVAL '10 days', NOW() + INTERVAL '355 days'
),
(
    (SELECT user_id FROM nkd_users ORDER BY user_id OFFSET 1 LIMIT 1), 
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'QuickFix Plumbing' LIMIT 1), 
    'premium', 9999.00, 'completed', NOW() - INTERVAL '5 days', 
    500, 500, true, NOW() - INTERVAL '5 days', NOW() + INTERVAL '360 days'
);

-- 4. Insert Enquiries
INSERT INTO nkd_enquiries (
    customer_id, business_id, enquiry_title, enquiry_message, enquiry_type, status, is_read, 
    customer_name, customer_phone, customer_email
) VALUES
(
    (SELECT user_id FROM nkd_users ORDER BY user_id OFFSET 1 LIMIT 1), 
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'Sharma Sweets & Snacks' LIMIT 1), 
    'Bulk Order for Festival', 'Need 50 boxes of mixed sweets for Diwali.', 'bulk_order', 'pending', false, 
    'Rahul Verma', '+91-9012345678', 'rahul.v@example.com'
),
(
    (SELECT user_id FROM nkd_users ORDER BY user_id LIMIT 1), 
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'QuickFix Plumbing' LIMIT 1), 
    'Leaking Pipe', 'Emergency: Pipe leaking in the kitchen.', 'service_request', 'resolved', true, 
    'Amit Kumar', '+91-9123456789', 'amit.k@example.com'
);

-- 5. Insert Offers
INSERT INTO nkd_offers (
    business_id, offer_title, offer_description, discount_percentage, offer_code, 
    start_date, end_date, is_active
) VALUES
(
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'Sharma Sweets & Snacks' LIMIT 1), 
    'Diwali Special 10%', 'Get 10% off on bulk orders above Rs 1000.', 10.00, 'DIWALI10', 
    NOW(), NOW() + INTERVAL '30 days', true
);

-- 6. Insert Reviews
INSERT INTO nkd_reviews (
    business_id, customer_id, rating, review_text, is_verified, is_visible
) VALUES
(
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'Sharma Sweets & Snacks' LIMIT 1), 
    (SELECT user_id FROM nkd_users ORDER BY user_id OFFSET 1 LIMIT 1), 
    5, 'Excellent quality sweeps and very fresh!', true, true
),
(
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'QuickFix Plumbing' LIMIT 1), 
    (SELECT user_id FROM nkd_users ORDER BY user_id LIMIT 1), 
    4, 'Arrived on time and fixed the leak quickly. Recommended.', true, true
)
ON CONFLICT (business_id, customer_id) DO NOTHING;

-- 7. Insert Saved Businesses
INSERT INTO nkd_saved_businesses (customer_id, business_id) VALUES
(
    (SELECT user_id FROM nkd_users ORDER BY user_id OFFSET 1 LIMIT 1), 
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'Sharma Sweets & Snacks' LIMIT 1)
),
(
    (SELECT user_id FROM nkd_users ORDER BY user_id LIMIT 1), 
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'QuickFix Plumbing' LIMIT 1)
)
ON CONFLICT (customer_id, business_id) DO NOTHING;

-- 8. Insert Emergency Numbers
INSERT INTO nkd_emergency_numbers (
    service_name, phone_number, alternate_number, description, category, is_active, priority
) VALUES
('Police', '100', '112', 'National Police Helpline', 'Law Enforcement', true, 1),
('Ambulance', '102', '108', 'Medical Emergency', 'Medical', true, 1),
('Fire Brigade', '101', '', 'Fire Emergency', 'Fire', true, 1);

-- 9. Insert Business Analytics
INSERT INTO nkd_business_analytics (
    business_id, event_type, user_id, metadata
) VALUES
(
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'Sharma Sweets & Snacks' LIMIT 1), 
    'profile_view', 
    (SELECT user_id FROM nkd_users ORDER BY user_id OFFSET 1 LIMIT 1), 
    '{"source": "search", "device": "mobile"}'
),
(
    (SELECT business_id FROM nkd_businesses WHERE business_name = 'QuickFix Plumbing' LIMIT 1), 
    'call_click', 
    (SELECT user_id FROM nkd_users ORDER BY user_id LIMIT 1), 
    '{"source": "business_page", "device": "desktop"}'
);

-- 10. Insert Notifications
INSERT INTO nkd_notifications (
    user_id, title, message, type, is_read
) VALUES
(
    (SELECT user_id FROM nkd_users ORDER BY user_id LIMIT 1), 
    'Welcome to Nukkad', 'Thank you for registering your business with us.', 'system', false
),
(
    (SELECT user_id FROM nkd_users ORDER BY user_id OFFSET 1 LIMIT 1), 
    'New Offer Available', 'Check out the Diwali special from Sharma Sweets & Snacks!', 'promotional', false
);
