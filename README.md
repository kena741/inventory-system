# Zulu Inventory

Flutter client for an inventory and operations app backed by **Supabase**. It supports **role-based** workflows for a tailoring-style business: customer orders, stock, raw-material purchasing, expenses, vendors, and staff tools (tailors, sellers, managers, admins).

## Features

### Authentication & roles

- Sign-in via Supabase Auth; the home shell and tabs depend on **admin**, **manager**, **seller**, or **tailor**.
- **Profile** is available from the app bar on all roles.

### Customer orders

- List orders with status, payments, cloth code, and delivery date.
- **Create order**: customer name, phone (`customer_number`), address, interest, cloth code, quantity, initial vs remaining payment, **total derived as initial + remaining** (read-only), delivery date, description.
- Initial payment channel (**cash / bank**); when an order is **completed**, optional **final payment** channel can be recorded.
- **Order detail**: summary, dates, assignments, measurements per item, and workflow actions appropriate to the role.

### Stock & catalog

- **Stock** screen for inventory overview (admin / manager tabs).
- **Raw materials** (under **More**): maintain material definitions used across purchasing and requests.

### Raw material requests & purchasing

- Create and track **raw material requests** with statuses aligned to your DB (including receipt completion and workflow events).
- **Receipt completion** can record purchases, update stock, and tie into **price history** from received lines where the schema supports it.

### Sellers

- **Orders**, **seller performance** (metrics over time), and **Purchases** (raw material request flow for sellers).

### Tailors

- **Assigned orders**, personal **performance**, and **time logs** (clock in / out).

### Managers

- **Orders**, **Stock**, **Requests**, and **More** (same management entries as admin minus full dashboard).

### Admins

- **Home dashboard**: overview stats (orders, requests, expenses, etc.).
- **Stock**, **Orders**, **Requests**, **More**.
- **More → Performance → Tailor team performance**: week-oriented view across tailors.

### Settings & administration (More)

- **Raw materials**, **Expenses**, **Locations**.
- **Users**: Tailors, Sellers, Managers; **Vendors** (admin only).
- App **About** dialog.

## Tech stack

| Layer | Choice |
|--------|--------|
| UI | Flutter (Material 3) |
| State / routing | [GetX](https://pub.dev/packages/get) |
| Backend | [Supabase](https://supabase.com/) (Auth + Postgres + APIs) |
| Local prefs | [get_storage](https://pub.dev/packages/get_storage) |
| Env | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) |

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (see `environment.sdk` in `pubspec.yaml`).
- A Supabase project with tables and policies matching this app (SQL migrations live under `supabase/migrations/`).

## Setup

1. Clone the repo and install dependencies:

   ```bash
   cd zulu_inventory
   flutter pub get
   ```

2. Create a **`.env`** file in the project root (it is loaded at startup and listed under `flutter.assets` in `pubspec.yaml`). Set your project URL and anon key (either naming style works):

   ```env
   SUPABASE_URL=https://YOUR_PROJECT.supabase.co
   SUPABASE_ANON_KEY=your_anon_key
   ```

   Or:

   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
   ```

3. Apply database migrations to your Supabase project (CLI or SQL editor), using the files in `supabase/migrations/` in timestamp order.

## Run

```bash
flutter run
```

Use `-d chrome`, `-d macos`, or a device ID as needed.

## Repository layout (high level)

- `lib/app/modules/` — feature modules (views, controllers, bindings).
- `lib/core/services/` — Supabase-facing services (e.g. `erp_repository.dart`, DB access).
- `supabase/migrations/` — incremental SQL for schema and constraints.

## License / publication

This project is configured as **private** (`publish_to: 'none'` in `pubspec.yaml`). Adjust licensing if you open-source it.
