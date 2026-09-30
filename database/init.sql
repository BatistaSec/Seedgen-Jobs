-- init.sql
-- Script de inicialização do banco de dados Seedgen-jobs

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS candidate_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    profile_data JSONB NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS jobs (
    id SERIAL PRIMARY KEY,
    source VARCHAR(100) NOT NULL,
    external_id VARCHAR(255),
    title VARCHAR(255) NOT NULL,
    company VARCHAR(255),
    location VARCHAR(255),
    remote_type VARCHAR(50),
    salary VARCHAR(255),
    description TEXT,
    url TEXT,
    published_at TIMESTAMP WITH TIME ZONE,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    hash VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(50) DEFAULT 'NEW'
);

CREATE TABLE IF NOT EXISTS job_analysis (
    id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES jobs(id) ON DELETE CASCADE,
    overall_score INTEGER,
    internship_score INTEGER,
    java_score INTEGER,
    node_score INTEGER,
    react_score INTEGER,
    fullstack_score INTEGER,
    skill_match JSONB,
    missing_skills JSONB,
    required_skills JSONB,
    preferred_skills JSONB,
    seniority VARCHAR(50),
    location_match BOOLEAN,
    education_match BOOLEAN,
    explanation TEXT,
    recommendation_reason TEXT,
    analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(job_id)
);

CREATE TABLE IF NOT EXISTS applications (
    id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES jobs(id),
    status VARCHAR(50) DEFAULT 'REVIEW',
    date_applied TIMESTAMP WITH TIME ZONE,
    resume_version VARCHAR(255),
    cover_letter TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS automation_runs (
    id SERIAL PRIMARY KEY,
    workflow_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    jobs_processed INTEGER DEFAULT 0,
    new_jobs_found INTEGER DEFAULT 0,
    ai_requests_made INTEGER DEFAULT 0,
    errors TEXT,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS ats_analysis (
    id SERIAL PRIMARY KEY,
    job_id INTEGER REFERENCES jobs(id) ON DELETE CASCADE,
    job_title_adapted VARCHAR(255),
    ats_keyword_score INTEGER,
    keyword_coverage INTEGER,
    required_keyword_coverage INTEGER,
    important_keyword_coverage INTEGER,
    matched_keywords JSONB,
    missing_keywords JSONB,
    partial_matches JSONB,
    recommended_keywords JSONB,
    validation_passed BOOLEAN,
    analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(job_id)
);
