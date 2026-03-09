---
title: Protocol Audit Report
author: Tura11
date:  8 march 2026
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---
---
title: Protocol Audit Report
author: Tura11
date:  8 march 2026
header-includes:
  - \usepackage{titling}
  - \usepackage{graphicx}
---

\begin{titlepage}
    \centering
    \begin{figure}[h]
        \centering
        \includegraphics[width=0.5\textwidth]{logo1.pdf} 
    \end{figure}
    \vspace*{2cm}
    {\Huge\bfseries Protocol Audit Report\par}
    \vspace{1cm}
    {\Large Version 1.0\par}
    \vspace{2cm}
    {\Large\itshape Tura11\par}
    \vfill
    {\large \today\par}
\end{titlepage}

\maketitle

<!-- Your report starts here! -->

Prepared by: [Tura11](https://github.com/tura11)
Lead Auditor: 
Tura11

# Table of Contents
- [Table of Contents](#table-of-contents)
- [Protocol Summary](#protocol-summary)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
- [Executive Summary](#executive-summary)
  - [Issues found'](#issues-found)
- [Findings](#findings)
- [High](#high)

# Protocol Summary



Roses are red, violets are blue, use this DatingDapp and love will find you.! Dating Dapp lets users mint a soulbound NFT as their verified dating profile. To express interest in someone, they pay 1 ETH to "like" their profile. If the like is mutual, all their previous like payments (minus a 10% fee) are pooled into a shared multisig wallet, which both users can access for their first date. This system ensures genuine connections, and turns every match into a meaningful, on-chain commitment.

- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
    - [Optional Gitpod](#optional-gitpod)
- [Usage](#usage)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Audit Scope Details](#audit-scope-details)
  - [Compatibilities](#compatibilities)
- [Roles](#roles)
- [Known Issues](#known-issues)


# Disclaimer

The Tura11 team makes all effort to find as many vulnerabilities in the code in the given time period, but holds no responsibilities for the findings provided in this document. A security audit by the team is not an endorsement of the underlying business or product. The audit was time-boxed and the review of the code was solely on the security aspects of the Solidity implementation of the contracts.

# Risk Classification

|            |        | Impact |        |     |
| ---------- | ------ | ------ | ------ | --- |
|            |        | High   | Medium | Low |
|            | High   | H      | H/M    | M   |
| Likelihood | Medium | H/M    | M      | M/L |
|            | Low    | M      | M/L    | L   |

We use the [CodeHawks](https://docs.codehawks.com/hawks-auditors/how-to-evaluate-a-finding-severity) severity matrix to determine severity. See the documentation for more details.

# Audit Details 
- Commit Hash: e643a8d4c2c802490976b538dd009b351b1c8dda
- In Scope:
## Scope 
```js
src/
 LikeRegistry.sol
 MultiSig.sol
 SoulboundProfileNFT.sol
```


# Executive Summary

Ive learnt a lot from this audit, process was pretty easliy and fast.
## Issues found'


| Severity | Number of issues found |
| -------- | ---------------------- |
| High     | 2                      |
| Medium   | 3                      |
| Low      | 1                      |
| Info     | 0                      |
| Gas      | 4                      |
| Total    | 10                     |

# Findings
# High
HIGH-01 — Reentrancy in mintProfile allows minting multiple profiles

HIGH-02 — userBalances never updated, ETH permanently locked

MEDIUM-01 — DoS risk from deploying MultiSigWallet on every match

MEDIUM-02 — Centralization risk: owner can delete any user's profile

MEDIUM-03 — burnProfile does not follow CEI pattern

LOW-01 — executeTransaction does not check contract balance

GAS-01 — FIXEDFEE should be constant not immutable

GAS-02 — owner1 and owner2 should be immutable

GAS-03 — Unused Like struct in LikeRegistry

GAS-04 — Unused custom error NotEnoughApprovals
