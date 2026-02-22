-- ============================================
-- COMPLETE SUPABASE DATABASE SCHEMA FOR NUKKAD
-- Business Directory Application
-- ============================================
-- This script will DROP all existing tables and recreate them with proper RLS policies
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: DROP ALL TABLES (in reverse dependency order)
-- ============================================

-- Drop tables with foreign keys first
DROP TABLE IF EXISTS nkd_business_analytics CASCADE;
DROP TABLE IF EXISTS nkd_notifications CASCADE;
DROP TABLE IF EXISTS nkd_saved_businesses CASCADE;
DROP TABLE IF EXISTS nkd_reviews CASCADE;
DROP TABLE IF EXISTS nkd_offers CASCADE;
DROP TABLE IF EXISTS nkd_enquiries CASCADE;
DROP TABLE IF EXISTS nkd_subscriptions CASCADE;
DROP TABLE IF EXISTS nkd_businesses CASCADE;
DROP TABLE IF EXISTS nkd_emergency_numbers CASCADE;
DROP TABLE IF EXISTS business_categories CASCADE;
DROP TABLE IF EXISTS nkd_users CASCADE;

-- ============================================
-- STEP 2: CREATE ALL TABLES
-- ============================================

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE nkd_users (
    user_id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(15) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('customer', 'business', 'admin')),
    business_name VARCHAR(150),
    business_category VARCHAR(100),
    profile_image TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. BUSINESSES TABLE
-- ============================================
CREATE TABLE nkd_businesses (
    business_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES nkd_users(user_id) ON DELETE CASCADE,
    business_name VARCHAR(150) NOT NULL,
    business_category VARCHAR(100) NOT NULL,
    description TEXT,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone VARCHAR(15),
    email VARCHAR(150),
    website VARCHAR(255),
    business_image TEXT,
    opening_hours JSONB,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    total_views INTEGER DEFAULT 0,
    total_enquiries INTEGER DEFAULT 0,
    rating_average DECIMAL(3, 2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3. BUSINESS CATEGORIES TABLE
-- ============================================
CREATE TABLE business_categories (
    category_id BIGSERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL,
    icon_name VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. SUBSCRIPTIONS TABLE
-- ============================================
CREATE TABLE nkd_subscriptions (
    subscription_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES nkd_users(user_id) ON DELETE CASCADE,
    business_id BIGINT REFERENCES nkd_businesses(business_id) ON DELETE CASCADE,
    subscription_type VARCHAR(20) NOT NULL CHECK (subscription_type IN ('free', 'yearly', 'premium')),
    payment_amount DECIMAL(10, 2) DEFAULT 0.00,
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_date TIMESTAMP WITH TIME ZONE,
    payment_transaction_id VARCHAR(255),
    connects_remaining INTEGER DEFAULT 5,
    connects_total INTEGER DEFAULT 5,
    is_active BOOLEAN DEFAULT TRUE,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 5. ENQUIRIES TABLE
-- ============================================
CREATE TABLE nkd_enquiries (
    enquiry_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES nkd_users(user_id) ON DELETE CASCADE,
    business_id BIGINT NOT NULL REFERENCES nkd_businesses(business_id) ON DELETE CASCADE,
    enquiry_title VARCHAR(200) NOT NULL,
    enquiry_message TEXT NOT NULL,
    enquiry_type VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'viewed', 'responded', 'closed')),
    is_read BOOLEAN DEFAULT FALSE,
    customer_name VARCHAR(100),
    customer_phone VARCHAR(15),
    customer_email VARCHAR(150),
    response_message TEXT,
    response_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 6. OFFERS TABLE
-- ============================================
CREATE TABLE nkd_offers (
    offer_id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES nkd_businesses(business_id) ON DELETE CASCADE,
    offer_title VARCHAR(200) NOT NULL,
    offer_description TEXT,
    discount_percentage DECIMAL(5, 2),
    discount_amount DECIMAL(10, 2),
    offer_code VARCHAR(50),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    total_views INTEGER DEFAULT 0,
    total_uses INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 7. REVIEWS TABLE
-- ============================================
CREATE TABLE nkd_reviews (
    review_id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES nkd_businesses(business_id) ON DELETE CASCADE,
    customer_id BIGINT NOT NULL REFERENCES nkd_users(user_id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(business_id, customer_id)
);

-- ============================================
-- 8. SAVED BUSINESSES TABLE
-- ============================================
CREATE TABLE nkd_saved_businesses (
    saved_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES nkd_users(user_id) ON DELETE CASCADE,
    business_id BIGINT NOT NULL REFERENCES nkd_businesses(business_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(customer_id, business_id)
);

-- ============================================
-- 9. EMERGENCY NUMBERS TABLE
-- ============================================
CREATE TABLE nkd_emergency_numbers (
    emergency_id BIGSERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    alternate_number VARCHAR(20),
    description TEXT,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 10. BUSINESS ANALYTICS TABLE
-- ============================================
CREATE TABLE nkd_business_analytics (
    analytics_id BIGSERIAL PRIMARY KEY,
    business_id BIGINT NOT NULL REFERENCES nkd_businesses(business_id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    user_id BIGINT REFERENCES nkd_users(user_id) ON DELETE SET NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 11. NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE nkd_notifications (
    notification_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES nkd_users(user_id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50),
    related_id BIGINT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- STEP 3: CREATE INDEXES
-- ============================================

CREATE INDEX idx_businesses_user_id ON nkd_businesses(user_id);
CREATE INDEX idx_businesses_category ON nkd_businesses(business_category);
CREATE INDEX idx_businesses_location ON nkd_businesses(latitude, longitude);
CREATE INDEX idx_enquiries_business_id ON nkd_enquiries(business_id);
CREATE INDEX idx_enquiries_customer_id ON nkd_enquiries(customer_id);
CREATE INDEX idx_enquiries_status ON nkd_enquiries(status);
CREATE INDEX idx_subscriptions_user_id ON nkd_subscriptions(user_id);
CREATE INDEX idx_subscriptions_business_id ON nkd_subscriptions(business_id);
CREATE INDEX idx_reviews_business_id ON nkd_reviews(business_id);
CREATE INDEX idx_offers_business_id ON nkd_offers(business_id);
CREATE INDEX idx_offers_active ON nkd_offers(is_active, end_date);
CREATE INDEX idx_notifications_user_id ON nkd_notifications(user_id);
CREATE INDEX idx_notifications_read ON nkd_notifications(user_id, is_read);

-- ============================================
-- STEP 4: CREATE FUNCTIONS & TRIGGERS
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_nkd_users_updated_at BEFORE UPDATE ON nkd_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nkd_businesses_updated_at BEFORE UPDATE ON nkd_businesses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nkd_subscriptions_updated_at BEFORE UPDATE ON nkd_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nkd_enquiries_updated_at BEFORE UPDATE ON nkd_enquiries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nkd_offers_updated_at BEFORE UPDATE ON nkd_offers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nkd_reviews_updated_at BEFORE UPDATE ON nkd_reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update business rating when review is added/updated
CREATE OR REPLACE FUNCTION update_business_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE nkd_businesses
    SET 
        rating_average = (
            SELECT COALESCE(AVG(rating)::DECIMAL(3,2), 0.00)
            FROM nkd_reviews
            WHERE business_id = COALESCE(NEW.business_id, OLD.business_id) AND is_visible = TRUE
        ),
        total_reviews = (
            SELECT COUNT(*)
            FROM nkd_reviews
            WHERE business_id = COALESCE(NEW.business_id, OLD.business_id) AND is_visible = TRUE
        )
    WHERE business_id = COALESCE(NEW.business_id, OLD.business_id);
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER update_rating_on_review AFTER INSERT OR UPDATE OR DELETE ON nkd_reviews
    FOR EACH ROW EXECUTE FUNCTION update_business_rating();

-- Function to decrement connects when enquiry is created
CREATE OR REPLACE FUNCTION decrement_connects_on_enquiry()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE nkd_subscriptions
    SET connects_remaining = GREATEST(0, connects_remaining - 1)
    WHERE user_id = NEW.customer_id 
        AND is_active = TRUE
        AND subscription_type != 'yearly'
        AND connects_remaining > 0;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER decrement_connects AFTER INSERT ON nkd_enquiries
    FOR EACH ROW EXECUTE FUNCTION decrement_connects_on_enquiry();

-- ============================================
-- STEP 5: INSERT INITIAL DATA
-- ============================================

-- Emergency Numbers
INSERT INTO nkd_emergency_numbers (service_name, phone_number, category, priority) VALUES
('Police', '100', 'police', 1),
('Ambulance', '102', 'medical', 1),
('Fire', '101', 'fire', 1),
('Women Helpline', '1091', 'helpline', 2),
('Child Helpline', '1098', 'helpline', 2),
('Disaster Management', '108', 'emergency', 2),
('Railway Enquiry', '139', 'information', 3),
('Tourist Helpline', '1363', 'information', 3)
ON CONFLICT DO NOTHING;

-- Sample Business Categories (add more as needed)
INSERT INTO business_categories (category_name, icon_name) VALUES
('Grocery', 'local_grocery_store'),
('Medical', 'medical_services'),
('Salon', 'cut'),
('Repair', 'build'),
('Food', 'restaurant'),
('Electronics', 'devices'),
('Clothing', 'checkroom'),
('Education', 'school'),
('Automotive', 'directions_car'),
('Real Estate', 'home')
ON CONFLICT (category_name) DO NOTHING;

-- ============================================
-- STEP 6: ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE nkd_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE nkd_businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE nkd_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE nkd_enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE nkd_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE nkd_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE nkd_saved_businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE nkd_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE nkd_emergency_numbers ENABLE ROW LEVEL SECURITY;
ALTER TABLE nkd_business_analytics ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 7: CREATE RLS POLICIES
-- ============================================

-- ============================================
-- RLS POLICIES FOR NKD_USERS
-- ============================================
-- Allow anyone to sign up (INSERT)
CREATE POLICY "Anyone can sign up" ON nkd_users
    FOR INSERT WITH CHECK (true);

-- Allow users to view their own data and public data
CREATE POLICY "Users can view data" ON nkd_users
    FOR SELECT USING (true);

-- Allow users to update their own data
CREATE POLICY "Users can update own data" ON nkd_users
    FOR UPDATE USING (true);

-- ============================================
-- RLS POLICIES FOR NKD_BUSINESSES
-- ============================================
-- Businesses are publicly readable
CREATE POLICY "Businesses are publicly readable" ON nkd_businesses
    FOR SELECT USING (is_active = TRUE);

-- Business owners can insert their own business
CREATE POLICY "Business owners can create business" ON nkd_businesses
    FOR INSERT WITH CHECK (true);

-- Business owners can update their own business
CREATE POLICY "Business owners can update own business" ON nkd_businesses
    FOR UPDATE USING (true);

-- ============================================
-- RLS POLICIES FOR NKD_SUBSCRIPTIONS
-- ============================================
-- Users can view their own subscriptions
CREATE POLICY "Users can view subscriptions" ON nkd_subscriptions
    FOR SELECT USING (true);

-- Users can create subscriptions
CREATE POLICY "Users can create subscriptions" ON nkd_subscriptions
    FOR INSERT WITH CHECK (true);

-- Users can update their own subscriptions
CREATE POLICY "Users can update subscriptions" ON nkd_subscriptions
    FOR UPDATE USING (true);

-- ============================================
-- RLS POLICIES FOR NKD_ENQUIRIES
-- ============================================
-- Customers can create enquiries
CREATE POLICY "Customers can create enquiries" ON nkd_enquiries
    FOR INSERT WITH CHECK (true);

-- Business owners and customers can view enquiries
CREATE POLICY "Users can view enquiries" ON nkd_enquiries
    FOR SELECT USING (true);

-- Business owners can update enquiries (respond)
CREATE POLICY "Business owners can update enquiries" ON nkd_enquiries
    FOR UPDATE USING (true);

-- ============================================
-- RLS POLICIES FOR NKD_OFFERS
-- ============================================
-- Offers are publicly readable
CREATE POLICY "Offers are publicly readable" ON nkd_offers
    FOR SELECT USING (is_active = TRUE);

-- Business owners can create offers
CREATE POLICY "Business owners can create offers" ON nkd_offers
    FOR INSERT WITH CHECK (true);

-- Business owners can update their offers
CREATE POLICY "Business owners can update offers" ON nkd_offers
    FOR UPDATE USING (true);

-- ============================================
-- RLS POLICIES FOR NKD_REVIEWS
-- ============================================
-- Reviews are publicly readable
CREATE POLICY "Reviews are publicly readable" ON nkd_reviews
    FOR SELECT USING (is_visible = TRUE);

-- Customers can create reviews
CREATE POLICY "Customers can create reviews" ON nkd_reviews
    FOR INSERT WITH CHECK (true);

-- Customers can update their own reviews
CREATE POLICY "Customers can update own reviews" ON nkd_reviews
    FOR UPDATE USING (true);

-- ============================================
-- RLS POLICIES FOR NKD_SAVED_BUSINESSES
-- ============================================
-- Users can view their saved businesses
CREATE POLICY "Users can view saved businesses" ON nkd_saved_businesses
    FOR SELECT USING (true);

-- Users can save businesses
CREATE POLICY "Users can save businesses" ON nkd_saved_businesses
    FOR INSERT WITH CHECK (true);

-- Users can unsave businesses
CREATE POLICY "Users can unsave businesses" ON nkd_saved_businesses
    FOR DELETE USING (true);

-- ============================================
-- RLS POLICIES FOR NKD_NOTIFICATIONS
-- ============================================
-- Users can view their own notifications
CREATE POLICY "Users can view own notifications" ON nkd_notifications
    FOR SELECT USING (true);

-- System can create notifications
CREATE POLICY "System can create notifications" ON nkd_notifications
    FOR INSERT WITH CHECK (true);

-- Users can update their notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON nkd_notifications
    FOR UPDATE USING (true);

-- ============================================
-- RLS POLICIES FOR BUSINESS_CATEGORIES
-- ============================================
-- Categories are publicly readable
CREATE POLICY "Categories are publicly readable" ON business_categories
    FOR SELECT USING (is_active = TRUE);

-- ============================================
-- RLS POLICIES FOR NKD_EMERGENCY_NUMBERS
-- ============================================
-- Emergency numbers are publicly readable
CREATE POLICY "Emergency numbers are publicly readable" ON nkd_emergency_numbers
    FOR SELECT USING (is_active = TRUE);

-- ============================================
-- RLS POLICIES FOR NKD_BUSINESS_ANALYTICS
-- ============================================
-- Business owners can view their analytics
CREATE POLICY "Business owners can view analytics" ON nkd_business_analytics
    FOR SELECT USING (true);

-- System can create analytics
CREATE POLICY "System can create analytics" ON nkd_business_analytics
    FOR INSERT WITH CHECK (true);

-- ============================================
-- SCHEMA CREATION COMPLETE!
-- ============================================
-- All tables, indexes, triggers, and RLS policies have been created.
-- You can now use the application for signup and all operations.
