# Food Delivery App — Task Index

All implementation work is broken into service-level task files. Each file contains granular subtasks, acceptance criteria, and relevant technical notes drawn from `ARCHITECTURE.md`.

---

## Task Files

| # | File | Service / Area | Port |
|---|------|---------------|------|
| 01 | [01-infrastructure.md](./01-infrastructure.md) | Infrastructure (Docker, DB init, RabbitMQ setup) | — |
| 02 | [02-restaurant-menu-service.md](./02-restaurant-menu-service.md) | Restaurant & Menu Service | 3001 |
| 03 | [03-order-service.md](./03-order-service.md) | Order Service | 3002 |
| 04 | [04-driver-location-service.md](./04-driver-location-service.md) | Driver Location Service | 3003 |
| 05 | [05-notification-service.md](./05-notification-service.md) | Notification Service | 3004 |
| 06 | [06-api-gateway.md](./06-api-gateway.md) | API Gateway | 8080 |

---

## Recommended Build Order

```
01-infrastructure   ← Start here (shared infra must exist before services)
        │
        ├──▶ 02-restaurant-menu-service   (simplest, no messaging)
        │
        ├──▶ 03-order-service             (depends on RabbitMQ publisher)
        │
        ├──▶ 04-driver-location-service   (depends on Redis GEO + RabbitMQ)
        │
        └──▶ 05-notification-service      (depends on RabbitMQ consumers + Redis session)
                    │
                    └──▶ 06-api-gateway   (wire everything together last)
```

---

## Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 20 + TypeScript |
| Database | PostgreSQL 16 |
| Cache / GEO Store | Redis 7 |
| Message Broker | RabbitMQ 3 |
| Containerisation | Docker + Docker Compose |
| Real-time Protocol | WebSocket (ws library) |
