# Software Requirements Specification (SRS)
## Standard: IEEE 830

### 1. Introduction
#### 1.1 Purpose
This document specifies the software requirements for the Nukkad Business Directory application. It is intended for academic submission, and for reviewers, developers, and testers.

#### 1.2 Scope
Nukkad is a mobile-first business directory that connects customers with local businesses. Customers can search and view businesses, post enquiries, save businesses, and access emergency numbers. Business owners can register, manage profiles and offers, receive enquiries, and track analytics. A subscription model provides a limited number of free connects and a paid yearly plan for unlimited connects.

#### 1.3 Definitions, Acronyms, Abbreviations
- App: Nukkad mobile application
- Business owner: User with business role
- Connect: A credit consumed when a customer posts an enquiry
- DFD: Data Flow Diagram
- ERD: Entity Relationship Diagram
- SRS: Software Requirements Specification
- Supabase: Backend-as-a-service used for database and APIs

#### 1.4 References
- Supabase schema: supabase_complete_schema.sql
- Project summary: PROJECT_COMPLETION_SUMMARY.md

#### 1.5 Overview
Section 2 provides the overall description. Section 3 lists specific requirements. Appendices include a data overview and diagram references.

### 2. Overall Description
#### 2.1 Product Perspective
The system is a Flutter client application using Supabase as the backend. It is a self-contained product with external dependencies for location, storage, and connectivity.

#### 2.2 Product Functions (High Level)
- User onboarding and role selection
- Authentication (signup, login)
- Business profile creation and updates
- Business search, browse, and view
- Enquiry creation and management
- Offers management
- Subscription and connects management
- Emergency numbers directory
- Notifications and analytics tracking

#### 2.3 User Classes and Characteristics
- Customer: Searches businesses, posts enquiries, saves businesses, views offers and emergency numbers
- Business owner: Manages business profile, offers, enquiries, and subscription
- Admin (system role): Manages categories, emergency data, and moderation (assumed)

#### 2.4 Operating Environment
- Flutter app on Android, iOS, and web (primary target: Android)
- Supabase backend and PostgreSQL database
- Device services: geolocation, phone dialer, and external links

#### 2.5 Design and Implementation Constraints
- Uses Supabase database schema and RLS policies
- Mobile network connectivity required for core flows
- Connects system limited by subscription rules
- Data consistency enforced by database triggers

#### 2.6 User Documentation
- In-app onboarding and role selection screens
- This SRS and diagram set

#### 2.7 Assumptions and Dependencies
- Supabase project is provisioned and configured
- Payment gateway is not defined in code; transactions are recorded by ID
- Admin actions are out of scope in the current UI

### 3. Specific Requirements
#### 3.1 External Interface Requirements
##### 3.1.1 User Interfaces
- Mobile UI with onboarding, login/signup, customer dashboard, business dashboard
- Search and filter UI for businesses
- Enquiry form UI and status views
- Business profile edit UI and public business view
- Subscription payment UI
- Emergency numbers list and call action

##### 3.1.2 Hardware Interfaces
- GPS for nearby businesses (if enabled)
- Phone dialer for emergency numbers and business contacts

##### 3.1.3 Software Interfaces
- Supabase REST and database APIs
- Local storage for onboarding and role state

##### 3.1.4 Communications Interfaces
- HTTPS calls to Supabase backend

#### 3.2 Functional Requirements
FR-1 The system shall allow users to sign up with phone and password.
FR-2 The system shall allow users to log in and persist role selection.
FR-3 The system shall allow customers to browse and search businesses by category and location.
FR-4 The system shall allow customers to view business profiles and offers.
FR-5 The system shall allow customers to post enquiries to a business.
FR-6 The system shall decrement connects for a customer when an enquiry is created, except for unlimited subscription.
FR-7 The system shall allow business owners to create and update their business profiles.
FR-8 The system shall allow business owners to manage offers (create, edit, deactivate).
FR-9 The system shall allow business owners to view and respond to enquiries.
FR-10 The system shall support a yearly subscription with unlimited connects.
FR-11 The system shall show emergency numbers categorized by service.
FR-12 The system shall record analytics events for business views and actions.
FR-13 The system shall support notifications for enquiries and system events.
FR-14 The system shall allow customers to save and unsave businesses.
FR-15 The system shall allow customers to leave reviews for businesses.

#### 3.3 Performance Requirements
- Search results should load within 3 seconds on typical mobile networks.
- Enquiry creation should complete within 5 seconds under normal load.

#### 3.4 Logical Database Requirements
- Data stored in Supabase Postgres tables defined in supabase_complete_schema.sql
- Relationships: users to businesses, businesses to offers/enquiries/reviews
- Enquiries and subscriptions follow connects and status rules

#### 3.5 Design Constraints
- Flutter and Dart for client
- Supabase for backend and data storage
- Role-based data access enforced by RLS

#### 3.6 Software System Attributes
##### 3.6.1 Reliability
- Retry failed network operations with user-friendly messages

##### 3.6.2 Availability
- The app should handle intermittent connectivity gracefully

##### 3.6.3 Security
- Passwords stored as hashes
- Role-based access enforced by database policies

##### 3.6.4 Maintainability
- Services in lib/services/ isolate backend access

##### 3.6.5 Portability
- Flutter supports Android, iOS, and web

### 4. Appendices
#### 4.1 Data Entities (Summary)
- nkd_users
- nkd_businesses
- nkd_subscriptions
- nkd_enquiries
- nkd_offers
- nkd_reviews
- nkd_saved_businesses
- nkd_emergency_numbers
- nkd_business_analytics
- nkd_notifications
- business_categories

#### 4.2 Diagram References
See documentation/diagrams/README.md for Mermaid diagrams.
