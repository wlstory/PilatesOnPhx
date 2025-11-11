# PilatesOnPhx Sprint Planning Documentation

This directory contains comprehensive sprint planning documentation for the PilatesOnPhx Phoenix/Elixir/Ash rewrite.

## Documents Overview

### 1. SPRINT_2_3_4_ROADMAP.md (PRIMARY DOCUMENT)
**Purpose**: Complete feature specifications for Sprints 2, 3, and 4

**Contents**:
- 18 detailed feature issues (PHX-9 through PHX-26)
- User stories with personas
- Comprehensive use cases (Happy path, Edge cases, Error cases)
- Acceptance criteria
- Phoenix/Elixir/Ash-specific implementation details
- Testing strategies
- Dependencies and estimates

**Use**: Reference for creating Linear issues and development implementation

---

### 2. LINEAR_ISSUE_CREATION_GUIDE.md
**Purpose**: Step-by-step instructions for creating Linear issues from the roadmap

**Contents**:
- Project creation steps
- Label definitions
- Issue creation workflow
- Metadata assignment guide
- Dependency linking
- Validation checklist

**Use**: Follow this guide when creating issues in Linear workspace

---

### 3. SPRINT_SUMMARY.md
**Purpose**: Quick reference summary of all sprints and issues

**Contents**:
- Sprint breakdown with statistics
- Priority distribution
- Technology stack highlights
- Critical paths
- Risk mitigation strategies
- Success metrics

**Use**: High-level overview for stakeholders and sprint planning sessions

---

### 4. REQUIREMENTS_EXTRACTION_PLAN.md
**Purpose**: Guide for extracting additional requirements from NextJS and Rails teams

**Contents**:
- Extraction strategy and queries
- Pattern mapping (React/Rails → Phoenix/Ash)
- Gap analysis framework
- Issue adaptation templates
- Expected outcomes

**Use**: Extract requirements from Wlstory (NextJS) and AltBuild-Rails teams

---

## Quick Start

### For Product Managers / BSAs

1. Read `SPRINT_SUMMARY.md` for overview
2. Review `SPRINT_2_3_4_ROADMAP.md` for full specifications
3. Follow `LINEAR_ISSUE_CREATION_GUIDE.md` to create issues
4. Execute `REQUIREMENTS_EXTRACTION_PLAN.md` to find gaps

### For Developers

1. Reference `SPRINT_2_3_4_ROADMAP.md` for implementation details
2. Check technical patterns in each issue's "Technical Implementation Details" section
3. Review dependencies before starting work
4. Ensure 85%+ test coverage per testing strategy

### For Stakeholders

1. Read `SPRINT_SUMMARY.md` for timeline and scope
2. Review success metrics for each sprint
3. Understand critical paths and risks
4. Track progress against story point estimates

## Sprint Overview

### Sprint 1: Foundation (COMPLETE)
**Issues**: PHX-1 through PHX-8  
**Focus**: Ash Domain Architecture  
**Status**: Complete

### Sprint 2: LiveView Interfaces & User Workflows
**Issues**: PHX-9 through PHX-14 (6 issues, 50 points)  
**Focus**: Real-time booking and management UIs  
**Duration**: 2-3 weeks  
**Key Deliverables**:
- Class browsing with real-time availability
- Complete booking workflow
- Client, instructor, and owner dashboards
- User profile management

### Sprint 3: Background Jobs & Automations
**Issues**: PHX-15 through PHX-20 (6 issues, 68 points)  
**Focus**: Automated workflows using Oban  
**Duration**: 2-3 weeks  
**Key Deliverables**:
- Class reminder system (email/SMS)
- Waitlist automation
- Recurring class generation
- Attendance tracking
- Report generation

### Sprint 4: Integrations & Advanced Features
**Issues**: PHX-21 through PHX-26 (6 issues, 63 points)  
**Focus**: Third-party integrations and production polish  
**Duration**: 2-3 weeks  
**Key Deliverables**:
- Stripe payment integration
- Email/SMS service integrations
- Calendar export (iCal)
- Analytics dashboard
- Mobile PWA support

## Technology Stack

### Core Framework
- **Phoenix 1.8**: Web framework
- **Elixir 1.19**: Programming language
- **Ash Framework 3.7+**: Resource management

### Key Libraries
- **LiveView**: Real-time UI without JavaScript
- **Oban + AshOban**: Background job processing
- **Phoenix PubSub**: Real-time broadcasts
- **Ecto**: Database layer

### External Services
- **Stripe**: Payment processing
- **Resend/SendGrid**: Transactional email
- **Twilio**: SMS notifications
- **S3/Cloud Storage**: File storage

## Project Statistics

- **Total Sprints**: 4 (including foundation)
- **Total Issues**: 26 (PHX-1 through PHX-26)
- **Total Story Points**: 231+ (Sprint 1: 50, Sprints 2-4: 181)
- **Estimated Duration**: 9-12 weeks total
- **Target Test Coverage**: 85%+

## Issue Breakdown by Type

### Feature Types
- **LiveView Interfaces**: 6 issues (PHX-9, 10, 11, 12, 13, 14, 25)
- **Background Jobs**: 6 issues (PHX-15, 16, 17, 18, 19, 20)
- **Integrations**: 4 issues (PHX-21, 22, 23, 24)
- **Mobile**: 1 issue (PHX-26)

### Priority Distribution
- **Urgent**: 2 issues (13 points)
- **High**: 4 issues (47 points)
- **Medium**: 6 issues (72 points)
- **Low**: 7 issues (62 points)

## Critical Dependencies

### Sprint 2 Dependencies
All Sprint 2 issues depend on Sprint 1 foundation (PHX-1 through PHX-8)

### Sprint 3 Dependencies
Sprint 3 builds on Sprint 2 user interfaces for notifications and job triggering

### Sprint 4 Dependencies
Sprint 4 integrates with all previous sprint features

## Success Criteria

### Overall Success
- [ ] All critical path features implemented and tested
- [ ] 85%+ test coverage on business logic
- [ ] Real-time features perform well under load
- [ ] Payment processing works end-to-end
- [ ] Mobile PWA installable and functional
- [ ] Production deployment ready

### Sprint-Specific Criteria
See `SPRINT_SUMMARY.md` for detailed success criteria per sprint

## Next Steps

1. **Immediate** (This Week)
   - [ ] Create Sprint 2, 3, 4 projects in Linear
   - [ ] Create all 18 issues (PHX-9 through PHX-26) in Linear
   - [ ] Assign priorities, labels, and estimates
   - [ ] Link dependencies between issues

2. **Short Term** (Next Week)
   - [ ] Extract requirements from NextJS team (Wlstory)
   - [ ] Extract requirements from Rails team (AltBuild-Rails)
   - [ ] Identify gaps and create additional issues
   - [ ] Conduct Sprint 2 planning session
   - [ ] Assign developers to Sprint 2 issues

3. **Medium Term** (Next 2-3 Weeks)
   - [ ] Begin Sprint 2 development
   - [ ] Weekly sprint reviews and retrospectives
   - [ ] Update issue estimates based on velocity
   - [ ] Refine Sprint 3 and 4 backlog

## Resources

### Documentation
- [CLAUDE.md](/CLAUDE.md) - Development guidelines and patterns
- [AGENTS.md](/AGENTS.md) - Phoenix/Elixir/Ash detailed conventions
- [README.md](/README.md) - Project overview and setup

### External Resources
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Ash Framework](https://ash-hq.org/)
- [Oban Documentation](https://hexdocs.pm/oban/)
- [LiveView Guide](https://hexdocs.pm/phoenix_live_view/)

## Contact

For questions about sprint planning or issue specifications:
- **Product Manager**: [Your PM contact]
- **BSA**: catalio-product-manager agent
- **Tech Lead**: [Your tech lead contact]

---

**Last Updated**: 2025-11-10  
**Version**: 1.0  
**Status**: Ready for Linear issue creation
