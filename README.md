# PilatesOnPhx

A comprehensive Pilates studio management application built with Phoenix, Elixir, and Ash Framework.

## Overview

PilatesOnPhx is a production-ready Pilates studio management system that provides:

- **Studio Management**: Multi-tenant support for multiple studio locations
- **Class Scheduling**: Flexible class scheduling with capacity management
- **Client Management**: Comprehensive client profiles and booking history
- **Instructor Management**: Staff scheduling and class assignments
- **Booking System**: Real-time class bookings with waitlist support
- **Package Management**: Credit-based class packages and memberships
- **Automated Reminders**: Email and SMS reminders for upcoming classes
- **Check-in System**: Attendance tracking and client check-in

## Tech Stack

- **Phoenix 1.8** - Modern web framework with LiveView for real-time features
- **Elixir 1.19** - Functional, concurrent programming language
- **Ash Framework 3.7+** - Declarative resource management and business logic
- **PostgreSQL** - Reliable relational database
- **Oban** - Background job processing
- **Tailwind CSS** - Utility-first CSS framework

## Prerequisites

- **Elixir** 1.19.0 with OTP 28
- **Erlang** 28.1
- **Node.js** 22.14.0 (for asset compilation)
- **PostgreSQL** 16+
- **mise** or **asdf** (version manager)

## Getting Started

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/PilatesOnPhx.git
   cd PilatesOnPhx
   ```

2. Install dependencies and setup database:
   ```bash
   mix setup
   ```

3. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

   Or start with interactive Elixir shell:
   ```bash
   iex -S mix phx.server
   ```

4. Visit [`localhost:4000`](http://localhost:4000) from your browser.

### Development Workflow

#### Running Tests

```bash
# Run all tests with coverage
mix test

# Run specific test file
mix test test/pilates_on_phx/studios_test.exs

# Re-run only failed tests
mix test --failed
```

#### Quality Checks

Before committing, run the comprehensive quality check:

```bash
mix precommit
```

This runs:
- Code compilation with warnings as errors
- Unused dependency check
- Code formatting
- Credo (static analysis)
- Sobelow (security scan)
- Dependency audit
- Dialyzer (type checking)
- Full test suite with coverage

#### Interactive Development

Use IEx for testing and experimentation:

```bash
iex -S mix

# Test functions directly
iex> PilatesOnPhx.Studios.list_studios!()

# Create resources
iex> attrs = %{name: "Downtown Studio"}
iex> PilatesOnPhx.Studios.Studio
...> |> Ash.Changeset.for_create(:create, attrs)
...> |> Ash.create!()
```

#### Database Management

```bash
# Run migrations
mix ecto.migrate

# Reset database
mix ecto.reset

# Setup Ash resources
mix ash.setup
```

## Project Structure

```
lib/
├── pilates_on_phx/           # Business logic and domain
│   ├── accounts/             # User authentication and authorization
│   ├── studios/              # Studio management
│   ├── classes/              # Class scheduling and management
│   ├── clients/              # Client management
│   └── bookings/             # Booking and waitlist management
├── pilates_on_phx_web/       # Web interface
│   ├── controllers/          # HTTP controllers
│   ├── live/                 # LiveView components
│   ├── components/           # Reusable UI components
│   └── router.ex             # Application routes
priv/
├── repo/migrations/          # Database migrations
└── static/                   # Static assets
test/                         # Test suites
assets/                       # CSS, JavaScript, images
```

## Development Guidelines

See [CLAUDE.md](CLAUDE.md) for comprehensive development guidelines including:

- Ash Framework patterns and best practices
- Testing philosophy and coverage requirements
- Business domain rules and concepts
- Git workflow and commit conventions
- Linear integration for issue tracking

See [AGENTS.md](AGENTS.md) for detailed Phoenix/Elixir/Ash development patterns.

## Key Features

### Multi-Tenant Architecture

Each studio operates independently with complete data isolation:
- Studios have separate client lists, classes, and bookings
- Cross-studio queries are prevented by Ash policies
- Role-based access control per studio

### Real-Time Features

Built with Phoenix LiveView for instant updates:
- Live class availability updates
- Real-time booking confirmations
- Dynamic waitlist management
- Instant attendance tracking

### Background Jobs

Oban handles asynchronous tasks:
- Email and SMS reminder delivery
- Recurring class generation
- Report generation
- Data exports

### Admin Dashboard

Ash Admin provides administrative interface for:
- Data management
- Background job monitoring
- User administration
- System configuration

Access at `/admin` in development.

## Testing

The project maintains 85%+ test coverage with focus on:

- Business logic validation
- Authorization and multi-tenant isolation
- User workflows and edge cases
- Integration testing across domains

Run tests with coverage report:

```bash
mix test --cover
```

## Deployment

Ready to deploy? This application is configured for deployment on:

- **Fly.io** - Primary deployment platform
- **Heroku** - Alternative deployment option
- **Docker** - Containerized deployment

See Phoenix [deployment guides](https://hexdocs.pm/phoenix/deployment.html) for details.

## Contributing

1. Create a Linear issue for the feature or bug
2. Use `/sdlc` command with issue ID for structured development
3. Follow TDD principles (red-green-refactor)
4. Ensure `mix precommit` passes
5. Create PR linked to Linear issue

## Resources

### Phoenix & Elixir

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Elixir Documentation](https://elixir-lang.org/docs.html)

### Ash Framework

- [Ash Framework](https://ash-hq.org/)
- [Ash Documentation](https://hexdocs.pm/ash/)
- [Ash Phoenix](https://hexdocs.pm/ash_phoenix/)
- [Ash Authentication](https://hexdocs.pm/ash_authentication/)

### Community

- [Elixir Forum](https://elixirforum.com/)
- [Elixir Slack](https://elixir-slackin.herokuapp.com/)
- [Ash Discord](https://discord.gg/D7FNG2q)

## License

Copyright © 2025 PilatesOnPhx

## Acknowledgments

This project is structurally based on [Catalio](https://github.com/catalio/catalio) and follows its architectural patterns and development standards.
