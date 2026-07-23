# Fincore Architecture

## Overview

Fincore is designed as a scalable application using Clean Architecture.

## Layers

### Presentation

Responsible for:
- UI
- User interaction
- State management

Technology:
- Flutter
- Riverpod

---

### Domain

Framework independent layer.

Contains:

- Entities
- Value Objects
- Use Cases
- Repository interfaces

---

### Data

Responsible for:

- API communication
- Local storage
- External services

---

## Principles

- SOLID
- Clean Architecture
- Dependency Injection
- Testability
