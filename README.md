# Tokenized Decentralized Porch Light Installation Services

A blockchain-based platform for managing porch light installation services through smart contracts on the Stacks blockchain using Clarity.

## Overview

This system tokenizes porch light installation services through five independent smart contracts, each handling a specific aspect of the installation process:

1. **Electrical Safety Contract** - Ensures proper wiring and code compliance
2. **Design Consultation Contract** - Provides lighting style and placement recommendations
3. **Installation Verification Contract** - Confirms secure mounting and functionality
4. **Energy Efficiency Contract** - Promotes LED and solar-powered lighting options
5. **Warranty Management Contract** - Handles product guarantees and service follow-up

## Features

- **Tokenized Services**: Each service is represented as a token that can be purchased and redeemed
- **Decentralized Verification**: Community-driven verification system for service completion
- **Transparent Pricing**: All service costs are transparent and stored on-chain
- **Quality Assurance**: Built-in rating and feedback system
- **Energy Incentives**: Rewards for choosing energy-efficient lighting options

## Contract Architecture

Each contract operates independently without cross-contract calls, ensuring modularity and gas efficiency:

### Electrical Safety Contract
- Manages electrical safety certifications
- Tracks code compliance verification
- Handles safety inspector assignments

### Design Consultation Contract
- Manages design consultation tokens
- Stores style preferences and recommendations
- Tracks consultation completion

### Installation Verification Contract
- Verifies installation completion
- Manages mounting security checks
- Handles functionality testing

### Energy Efficiency Contract
- Promotes LED and solar options
- Manages efficiency ratings
- Distributes energy efficiency rewards

### Warranty Management Contract
- Handles warranty token issuance
- Manages warranty claims
- Tracks service follow-ups

## Getting Started

### Prerequisites
- Stacks wallet
- STX tokens for transaction fees
- Clarity development environment

### Installation

1. Clone the repository
2. Deploy contracts to Stacks testnet/mainnet
3. Interact with contracts through web interface or CLI

### Usage

1. **Purchase Service Tokens**: Buy tokens for required services
2. **Schedule Services**: Use tokens to schedule installations
3. **Verify Completion**: Confirm service completion through verification system
4. **Claim Warranties**: Use warranty tokens for future service needs

## Testing

Tests are written using Vitest and cover all contract functions:

\`\`\`bash
npm test
\`\`\`

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the GitHub repository.
