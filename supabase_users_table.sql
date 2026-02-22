-- PostgreSQL schema for nkd_users table in Supabase

CREATE TABLE nkd_users (
    user_id BIGSERIAL PRIMARY KEY,

    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(15) UNIQUE,

    password VARCHAR(255) NOT NULL,

    role VARCHAR(20) NOT NULL
        CHECK (role IN ('customer', 'business', 'admin')),

    business_name VARCHAR(150),
    business_category VARCHAR(100),

    profile_image TEXT,

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);