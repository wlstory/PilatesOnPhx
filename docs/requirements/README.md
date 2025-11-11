# Requirements Documentation

This directory contains comprehensive documentation for extracting and mapping requirements from the NextJS and Rails rewrites to Phoenix/Elixir/Ash.

## Documents

### 1. PHOENIX_REQUIREMENTS_FRAMEWORK.md
**Purpose:** Complete reference framework for mapping NextJS/Rails patterns to Phoenix/Elixir/Ash

**Contents:**
- 13 domain category definitions
- Pattern mapping (NextJS → Phoenix, Rails → Phoenix)
- Sprint assignment criteria
- Issue creation template with detailed example (PHX-25: Studio Onboarding Wizard)
- Testing philosophy (what to test vs what NOT to test)
- Coverage analysis framework

**Use this when:** You need to understand how to map a NextJS or Rails feature to Phoenix/Elixir/Ash patterns.

### 2. REQUIREMENTS_EXTRACTION_GUIDE.md
**Purpose:** Step-by-step execution guide for extracting ALL requirements

**Contents:**
- Data extraction methods (Linear CLI, API, MCP tools)
- Categorization approach
- Batch creation strategy (5 batches, 75+ issues)
- Quality checklist for each issue
- Expected deliverables

**Use this when:** You're ready to start the extraction process and create Phoenix issues in Linear.

## Quick Start

### For Product Managers:
1. Read **PHOENIX_REQUIREMENTS_FRAMEWORK.md** to understand the 13 domain categories
2. Review the **Issue Creation Template** (Part 3) and **Example Issue** (Part 7)
3. Follow **REQUIREMENTS_EXTRACTION_GUIDE.md** to execute in batches
4. Start with **Batch 1: Sprint 2 Core (15 issues)** focusing on essential workflows

### For Developers:
1. Reference **PHOENIX_REQUIREMENTS_FRAMEWORK.md Part 5** for pattern mapping examples
2. Use the **Technical Implementation Details** section of the template for implementation guidance
3. Follow **AGENTS.md** and **CLAUDE.md** for Phoenix/Elixir/Ash best practices
4. Ensure 85%+ test coverage focusing on business logic (not framework features)

## Domain Categories

The requirements are organized into 13 domains:

1. **Authentication & Multi-Tenant** - User management, organizations, roles
2. **Studio Management** - Studio setup, onboarding, settings, branding
3. **Class Management** - Class types, scheduling, recurring classes, rooms
4. **Client Management** - Client profiles, preferences, emergency contacts
5. **Package System** - Package types, credits, expiration, conversions
6. **Booking System** - Bookings, waitlists, cancellations, check-in
7. **Attendance & Check-In** - Check-in, no-shows, attendance tracking
8. **Payments & Billing** - Stripe integration, invoices, refunds
9. **Communications** - Email, SMS, push notifications, reminders
10. **Reporting & Analytics** - Reports, dashboards, exports
11. **Automation & Background Jobs** - Oban workers, scheduled tasks
12. **Mobile/PWA Features** - Offline support, mobile optimization
13. **Admin Tools & Data Management** - Data import/export, system tools

## Sprint Planning

### Sprint 1 (Complete - PHX-1 through PHX-8)
Foundational Ash resources and authentication

### Sprint 2 (15-25 issues to create)
Core user workflows:
- Studio onboarding
- Class scheduling (single and recurring)
- Client booking
- Basic settings

### Sprint 3 (15-20 issues to create)
Automation and background jobs:
- Oban workers
- Email/SMS notifications
- Scheduled reports
- Waitlist automation

### Sprint 4 (15-20 issues to create)
Integrations and advanced features:
- Stripe payments
- Advanced reporting
- Admin tools
- Data management

### Sprint 5+ (10-15 issues to create)
Polish and mobile:
- PWA features
- Mobile optimization
- Advanced UI/UX
- Performance enhancements

## Key Principles

### Pattern Mapping
- **React Components** → LiveView Components
- **React State** → LiveView Assigns + PubSub
- **NextJS Server Actions** → Ash Actions
- **REST APIs** → Ash Actions (exposed via LiveView or AshJsonApi)
- **Background Jobs (pg-boss)** → Oban Workers
- **Supabase RLS** → Ash Policies with Multi-tenant
- **Webhooks** → Phoenix Channels/Controllers

### Testing Focus
- Test PilatesOnPhx business logic (85%+ coverage)
- Test authorization policies (multi-tenant isolation)
- Test user workflows end-to-end
- Do NOT test Ash framework features (sorting, filtering, basic CRUD)
- Focus on what makes PilatesOnPhx unique

### Issue Quality Standards
Every Phoenix issue must include:
- Original requirement reference (WLS-XXX or RAILS-XXX)
- User story with persona from Catalio.Documentation.Persona
- Use cases in Gherkin format (Happy Path, Edge Cases, Error Cases)
- 5-10 testable acceptance criteria
- Comprehensive technical implementation details
- References to AGENTS.md and CLAUDE.md with line numbers
- Clear dependencies on Sprint 1 resources
- Testing strategy aligned with AGENTS.md guidelines

## Example Issue

See **PHOENIX_REQUIREMENTS_FRAMEWORK.md Part 7** for a complete example:
**PHX-25: Studio Onboarding Wizard (6-Step Process)**

This example demonstrates:
- Proper user story format
- Comprehensive use cases
- Detailed technical implementation
- Security and performance considerations
- Testing strategy with 90%+ coverage target

Use this as your template for all Phoenix issues.

## Tools and Resources

### Linear Integration
- Linear MCP Server (configured in Claude environment)
- Linear CLI: `npm install -g @linear/cli`
- Linear API: https://developers.linear.app/

### Documentation References
- **AGENTS.md**: Phoenix/Elixir/Ash development patterns
- **CLAUDE.md**: Project-specific conventions
- **Ash Framework Docs**: https://hexdocs.pm/ash/
- **Phoenix LiveView Docs**: https://hexdocs.pm/phoenix_live_view/

## Questions?

Refer to:
- **PHOENIX_REQUIREMENTS_FRAMEWORK.md** for pattern mapping questions
- **REQUIREMENTS_EXTRACTION_GUIDE.md** for execution questions
- **AGENTS.md** for Phoenix/Elixir/Ash development questions
- **CLAUDE.md** for project-specific questions
