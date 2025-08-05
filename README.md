# Blockchain-Based Public Health Restaurant Inspection System

A comprehensive smart contract system for managing restaurant health inspections, violations, certifications, and public health alerts on the Stacks blockchain.

## System Overview

This system consists of five interconnected smart contracts that manage the complete lifecycle of restaurant health inspections and food safety monitoring:

### 1. Health Inspection Scheduling Contract (`inspection-scheduler.clar`)
- Coordinates routine and complaint-driven restaurant inspections
- Manages inspector assignments and scheduling
- Tracks inspection frequencies and compliance requirements
- Handles emergency inspection requests

### 2. Violation Tracking and Remediation Contract (`violation-tracker.clar`)
- Records health code violations discovered during inspections
- Monitors correction efforts and remediation progress
- Tracks violation severity levels and repeat offenses
- Manages compliance deadlines and follow-up inspections

### 3. Food Handler Certification Contract (`certification-manager.clar`)
- Verifies employee food safety training and certification status
- Manages certification renewals and expiration tracking
- Records training completion and competency assessments
- Maintains certification authority approvals

### 4. Supply Chain Safety Monitoring Contract (`supply-chain-monitor.clar`)
- Tracks food suppliers and vendor relationships
- Identifies potential contamination sources
- Monitors supplier certifications and safety records
- Manages supply chain traceability for outbreak investigations

### 5. Public Health Alert Distribution Contract (`health-alerts.clar`)
- Notifies consumers of foodborne illness outbreaks
- Manages restaurant closure and reopening announcements
- Distributes public health warnings and advisories
- Coordinates with health authorities for emergency communications

## Key Features

### Transparency & Accountability
- All inspection records are immutably stored on-chain
- Public access to restaurant safety scores and violation history
- Transparent tracking of remediation efforts and compliance

### Automated Compliance Monitoring
- Smart contract-based scheduling ensures regular inspections
- Automated alerts for expired certifications and overdue inspections
- Real-time violation tracking and escalation procedures

### Data Integrity
- Cryptographic verification of all inspection data
- Tamper-proof violation records and remediation tracking
- Secure certification management with expiration monitoring

### Public Health Protection
- Rapid alert distribution for health emergencies
- Comprehensive supply chain traceability
- Evidence-based decision making for restaurant operations

## Contract Architecture

### Data Models

**Restaurant Registration**
- Unique restaurant ID and business information
- Operating licenses and permit tracking
- Inspection history and compliance status

**Inspector Management**
- Certified inspector registry
- Assignment tracking and workload management
- Performance metrics and accountability measures

**Violation Classification**
- Standardized violation codes and severity levels
- Remediation requirements and timelines
- Escalation procedures for repeat violations

**Certification Tracking**
- Employee certification records
- Training provider verification
- Renewal schedules and compliance monitoring

### Security Features

- Multi-signature requirements for critical operations
- Role-based access control for different user types
- Audit trails for all system modifications
- Emergency override capabilities for health authorities

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for contract deployment

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Usage

The system supports multiple user roles:

**Health Inspectors**
- Schedule and conduct inspections
- Record violations and compliance issues
- Verify remediation efforts

**Restaurant Operators**
- View inspection schedules and results
- Submit remediation documentation
- Manage employee certifications

**Public Health Officials**
- Monitor system-wide compliance trends
- Issue public health alerts
- Coordinate emergency responses

**General Public**
- Access restaurant safety information
- Receive health alerts and notifications
- Report potential health concerns

## Testing

The system includes comprehensive test coverage using Vitest:

- Unit tests for individual contract functions
- Integration tests for cross-contract workflows
- Edge case testing for error conditions
- Performance testing for high-volume scenarios

Run tests with: `npm test`

## Deployment

Contracts are deployed in dependency order:
1. certification-manager.clar
2. supply-chain-monitor.clar
3. inspection-scheduler.clar
4. violation-tracker.clar
5. health-alerts.clar

## Contributing

Please read the PR-DETAILS.md file for contribution guidelines and development standards.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
