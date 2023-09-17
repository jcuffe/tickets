# Packaging

- Extract `libpq` wrappers to a library

# DB

- Implement schemas with Sqitch migrations
- Distributed tables

# App

- Web service first iteration
  - Zap or custom wrapper for Facil.io
  - User Signup/Auth
  - Session management
  - FE integration
- Second iteration
  - Seller registration
  - Event creation
  - Ticket management
- Ticket event sourcing

# CI/CD

- Write Github workflow to test all DB operations against latest postgres/citus image
- Write Github action to perform Sqitch migrations against CI or production database
- Workflow for releases
  - Migrate DB
  - Configure cloud resources
  - Build image
  - Deploy
  - Store deployed tag for delta calculation in rollbacks
- Choose tools for platform management
  - Request hand-off to newly deployed containers
  - Automatic restarts of crashing containers
