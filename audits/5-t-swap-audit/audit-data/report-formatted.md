---
title: Protocol Audit Report
author: Tura11
date:  2 march 2026
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
  - [TSwap Pools](#tswap-pools)
- [Disclaimer](#disclaimer)
- [Risk Classification](#risk-classification)
- [Audit Details](#audit-details)
  - [Scope](#scope)
  - [Roles](#roles)
- [Executive Summary](#executive-summary)
  - [Issues found'](#issues-found)
- [Findings](#findings)
- [High](#high)
- [Low](#low)
- [Informational](#informational)
- [Gas](#gas)
  - [\[G-1\] Unused error](#g-1-unused-error)
  - [\[G-2\] function totalLiquidityTokenSupply() should be external](#g-2-function-totalliquiditytokensupply-should-be-external)

# Protocol Summary


This project is meant to be a permissionless way for users to swap assets between each other at a fair price. You can think of T-Swap as a decentralized asset/token exchange (DEX). 
T-Swap is known as an [Automated Market Maker (AMM)](https://chain.link/education-hub/what-is-an-automated-market-maker-amm) because it doesn't use a normal "order book" style exchange, instead it uses "Pools" of an asset. 
It is similar to Uniswap. To understand Uniswap, please watch this video: [Uniswap Explained](https://www.youtube.com/watch?v=DLu35sIqVTM)

## TSwap Pools
The protocol starts as simply a `PoolFactory` contract. This contract is used to create new "pools" of tokens. It helps make sure every pool token uses the correct logic. But all the magic is in each `TSwapPool` contract. 

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
./src/
#-- PoolFactory.sol
#-- TSwapPool.sol
```
## Roles

- Liquidity Providers: Users who have liquidity deposited into the pools. Their shares are represented by the LP ERC20 tokens. They gain a 0.3% fee every time a swap is made. 
- Users: Users who want to swap tokens.

# Executive Summary

Ive learnt a lot from this audit, process was pretty easliy and fast.
## Issues found'


| Severity | Number of issues found |
| -------- | ---------------------- |
| High     | 5                      |
| Medium   | 2                      |
| Low      | 2                      |
| Info     | 9                      |
| Gas      | 3                      |
| Total    | 21                     |

# Findings
# High
[H-1] TSwapPool::deposit is missing deadline check causing transactions to complete even after the deadline

[H-2] Incorrect fee calculation in TSwapPool::getInputAmountBasedOnOutput causes protocll to take too many tokens from users, resulting in lost fees

[H-3] Lack of slippage protection in TSwapPool::swapExactOutput causes users to potentially receive way fewer tokens

[H-4] TSwapPool::sellPoolTokens mismatches input and output tokens causing users to receive the incorrect amount of tokens

[H-5] In TSwapPool::_swap the extra tokens given to users after every swapCount breaks the protocol invariant of x * y = k 

# Low 
[L-1] TSwapPool::LiquidityAdded event has parameters out of order

[L-2] Default value returned by TSwapPool::swapExactInput results in incorrect return value given
# Informational
[I-1] PoolFactory::PoolFactory__PoolDoesNotExist is not used and should be removed
[I-2] Lacking zero address checks 

[I-3] PoolFacotry::createPool should use .symbol() instead of .name()


[I-4] Event is missing indexed field
# Gas 
## [G-1] Unused error

## [G-2] function totalLiquidityTokenSupply() should be external