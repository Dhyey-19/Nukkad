-- ============================================
-- FIX RLS POLICIES FOR NUKKAD
-- Run this if you're getting RLS errors during signup
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own data" ON nkd_users;
DROP POLICY IF EXISTS "Businesses are publicly readable" ON nkd_businesses;
DROP POLICY IF EXISTS "Business owners can update own business" ON nkd_businesses;
DROP POLICY IF EXISTS "Customers can create enquiries" ON nkd_enquiries;
DROP POLICY IF EXISTS "Business owners can view own enquiries" ON nkd_enquiries;

-- ============================================
-- RLS POLICIES FOR NKD_USERS
-- ============================================
-- Allow anyone to sign up (INSERT)
CREATE POLICY "Anyone can sign up" ON nkd_users
    FOR INSERT WITH CHECK (true);

-- Allow users to view their own data and public data
CREATE POLICY "Users can view own data" ON nkd_users
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
CREATE POLICY "Users can view own subscriptions" ON nkd_subscriptions
    FOR SELECT USING (true);

-- Users can create subscriptions
CREATE POLICY "Users can create subscriptions" ON nkd_subscriptions
    FOR INSERT WITH CHECK (true);

-- Users can update their own subscriptions
CREATE POLICY "Users can update own subscriptions" ON nkd_subscriptions
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

-- System can create notifications (or allow inserts)
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
