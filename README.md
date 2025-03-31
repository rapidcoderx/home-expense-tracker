# Home Expense Tracker
A full-stack app to manage household expenses and inventory.

## Project Plan
- **Stage 1:** Minimal setup (Weeks 1-2) - *Completed*
  - Backend: Express on port 4001 with /api/health endpoint
  - Frontend: React on port 4000, calls backend health check
  - Added `runapp.sh` to start/stop both apps
- **Stage 2a:** CRUD APIs and UI (Weeks 3-6)
- **Stage 2b:** Budgets, alerts, sharing (Weeks 7-11)
- **Stage 3:** Caching and config (Weeks 12-14)
- **Stage 5:** Docs and observability (Weeks 15-17)
- **Stage 6:** Deployment and testing (Weeks 18-22)
- **Stage 7:** Advanced features (Weeks 23-28)

## Tools
- Backend: Node.js, Express (port 4001)
- Frontend: React (port 4000)
- AI: Grok (planning), Claude (coding), Cursor (deployment)
- Utility: `runapp.sh` for app management

## Running Locally
1. Clone the repo: `git clone https://github.com/rapidcoderx/home-expense-tracker.git`
2. Install dependencies:
   - `cd backend && npm install`
   - `cd frontend && npm install`
3. Run: `./runapp.sh start`
4. Stop: `./runapp.sh stop`