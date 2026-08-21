-- Office Inventory and Buddy Reward database
-- PostgreSQL / Supabase compatible
-- Run this in the SQL editor of your database provider.

create extension if not exists pgcrypto;

create table if not exists app_users (
    id uuid primary key default gen_random_uuid(),
    username text not null unique,
    email text unique,
    password_hash text not null,
    first_name text not null,
    last_name text not null,
    mobile text,
    role text not null default 'Staff' check (role in ('Administrator', 'Staff')),
    status text not null default 'pending' check (status in ('active', 'pending', 'disabled')),
    permissions jsonb not null default '[]'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists office_settings (
    id boolean primary key default true check (id),
    name text not null default 'Office Inventory',
    address text,
    phone text,
    email text,
    currency text not null default 'LKR',
    currency_symbol text not null default 'Rs.',
    logo_url text,
    updated_at timestamptz not null default now()
);

create table if not exists categories (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    description text,
    created_at timestamptz not null default now()
);

create table if not exists suppliers (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    contact_person text,
    email text,
    phone text,
    address text,
    created_at timestamptz not null default now()
);

create table if not exists items (
    id uuid primary key default gen_random_uuid(),
    code text not null unique,
    name text not null,
    category_id uuid references categories(id) on delete set null,
    unit text not null,
    price numeric(12,2) not null default 0 check (price >= 0),
    stock numeric(12,2) not null default 0 check (stock >= 0),
    minimum_stock numeric(12,2) not null default 0 check (minimum_stock >= 0),
    supplier_id uuid references suppliers(id) on delete set null,
    description text,
    image_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists stock_transactions (
    id uuid primary key default gen_random_uuid(),
    item_id uuid not null references items(id) on delete restrict,
    transaction_type text not null check (transaction_type in ('in', 'out')),
    quantity numeric(12,2) not null check (quantity > 0),
    unit_price numeric(12,2) not null default 0 check (unit_price >= 0),
    reference text,
    notes text,
    performed_by uuid references app_users(id) on delete set null,
    created_at timestamptz not null default now()
);

create table if not exists user_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references app_users(id) on delete cascade,
    login_at timestamptz not null default now(),
    logout_at timestamptz,
    active_seconds integer not null default 0 check (active_seconds >= 0)
);

create table if not exists buddy_settings (
    id boolean primary key default true check (id),
    office_name text not null default 'My Office',
    address text,
    phone text,
    email text,
    currency text not null default 'LKR',
    updated_at timestamptz not null default now()
);

-- Compatibility store used by the current browser application.
-- The users array contains the client-side user records. Each user's
-- permissions array stores stable page IDs, including main-tab IDs such as
-- 'liquor', 'buddy-system', and 'recruitment', plus their subfolder IDs.
-- The User Management screen edits these permissions in two steps without
-- changing the JSON format, so existing shared state remains compatible.
create table if not exists shared_app_state (
    id boolean primary key default true check (id),
    users jsonb not null default '[]'::jsonb,
    inventory jsonb not null default '{}'::jsonb,
    buddy jsonb not null default '{}'::jsonb,
    updated_by text,
    updated_at timestamptz not null default now()
);

create table if not exists sections (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    created_at timestamptz not null default now()
);

create table if not exists buddies (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    email text,
    mobile text,
    employee_code text unique,
    department text,
    section_id uuid references sections(id) on delete set null,
    buddy_type text not null default 'buddy',
    points integer not null default 0,
    status text not null default 'active',
    created_at timestamptz not null default now()
);

create table if not exists reward_factors (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    points integer not null default 0,
    active boolean not null default true,
    created_at timestamptz not null default now()
);

create table if not exists tiers (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    minimum_points integer not null default 0,
    maximum_points integer,
    reward_amount numeric(12,2) not null default 0,
    created_at timestamptz not null default now()
);

create table if not exists buddy_assignments (
    id uuid primary key default gen_random_uuid(),
    buddy_id uuid not null references buddies(id) on delete cascade,
    employee_id uuid not null references buddies(id) on delete cascade,
    assigned_at timestamptz not null default now(),
    ended_at timestamptz,
    check (buddy_id <> employee_id)
);

create table if not exists evaluations (
    id uuid primary key default gen_random_uuid(),
    employee_id uuid not null references buddies(id) on delete cascade,
    evaluator_id uuid references app_users(id) on delete set null,
    factor_id uuid references reward_factors(id) on delete set null,
    score integer not null default 0,
    notes text,
    evaluated_at timestamptz not null default now()
);

create table if not exists rewards (
    id uuid primary key default gen_random_uuid(),
    buddy_id uuid not null references buddies(id) on delete cascade,
    tier_id uuid references tiers(id) on delete set null,
    points integer not null default 0,
    amount numeric(12,2) not null default 0,
    status text not null default 'pending',
    awarded_at timestamptz not null default now(),
    notes text
);

create index if not exists idx_items_category on items(category_id);
create index if not exists idx_items_supplier on items(supplier_id);
create index if not exists idx_stock_transactions_item on stock_transactions(item_id);
create index if not exists idx_stock_transactions_created_at on stock_transactions(created_at);
create index if not exists idx_sessions_user on user_sessions(user_id);
create index if not exists idx_buddies_section on buddies(section_id);
create index if not exists idx_evaluations_employee on evaluations(employee_id);
create index if not exists idx_rewards_buddy on rewards(buddy_id);

insert into office_settings (id) values (true) on conflict (id) do nothing;
insert into buddy_settings (id) values (true) on conflict (id) do nothing;
insert into shared_app_state (id, users)
values (
    true,
    '[{"id":"u1","username":"admin","password":"admin123","role":"Administrator","name":"System Admin","permissions":["all"],"status":"active"}]'::jsonb
)
on conflict (id) do update
set users = case
    when jsonb_typeof(shared_app_state.users) = 'array'
         and not exists (
             select 1 from jsonb_array_elements(shared_app_state.users) user_record
             where user_record->>'username' = 'admin'
         )
    then shared_app_state.users || excluded.users
    else shared_app_state.users
end;

-- Compatibility policies for the current client-side login implementation.
-- Replace these with authenticated-user policies before using real passwords.
alter table shared_app_state enable row level security;
drop policy if exists "shared app state read" on shared_app_state;
drop policy if exists "shared app state write" on shared_app_state;
create policy "shared app state read" on shared_app_state for select using (true);
create policy "shared app state write" on shared_app_state for all using (true) with check (true);
