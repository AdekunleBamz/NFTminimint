-- NFTminimint Database Initialization
-- This file is used to initialize any database if needed

-- Enable UUID extension (if using PostgreSQL)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create tables for NFT data, users, etc. (if needed)
-- Add any initial schema setup here

-- Example: NFT metadata table (adjust as needed)
-- CREATE TABLE IF NOT EXISTS nfts (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     token_id BIGINT UNIQUE NOT NULL,
--     contract_address VARCHAR(42) NOT NULL,
--     owner_address VARCHAR(42) NOT NULL,
--     metadata JSONB,
--     minted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
--     updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
-- );

-- Example: Minting events table (adjust as needed)
-- CREATE TABLE IF NOT EXISTS mint_events (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     transaction_hash VARCHAR(66) UNIQUE NOT NULL,
--     token_id BIGINT NOT NULL,
--     minter_address VARCHAR(42) NOT NULL,
--     contract_address VARCHAR(42) NOT NULL,
--     block_number BIGINT NOT NULL,
--     block_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
-- );

-- Add any other initial database setup here