# iTeaGrow - MERN Stack Web Application

iTeaGrow is a modern web application designed for the Tea Industry, built using the MERN stack (MongoDB, Express.js, React, Node.js).

### 🌐 [View Web Application: iteagrow-web-app.up.railway.app](https://iteagrow-web-app.up.railway.app/)

## 🚀 Features

- **Modern Frontend**: Built with Vite + React for lightning-fast performance.
- **Backend API**: Robust Node.js & Express server connected to MongoDB.
- **Visual Effects**:
    - **Tea Background**: Custom animated CSS background simulating a lush tea garden.
    - **Glowing Typography**: "iTeaGrow" title with a pulsating green glow.
    - **Typewriter Effect**: "Coming Soon" text animation.
    - **Custom Favicon**: Tea leaf SVG icon.
- **Routing**: Client-side routing with `react-router-dom` (auto-redirects to `/dashboard`).
- **Modular Architecture**: Clean separation of concerns with dedicated folders for `pages`, `components`, `css`, and `assets`.

## 🛠️ Tech Stack

- **Frontend**: React (Vite), JavaScript, CSS3 (Animations/Gradients).
- **Backend**: Node.js, Express.js.
- **Database**: MongoDB (Mongoose ORM).
- **Styling**: Vanilla CSS with a modular file structure.

## 📂 Project Structure

```
iTeaGrow-Web-Application/
├── backend/            # Express Server & API functionality
│   ├── config/         # Database configuration (db.js)
│   ├── controllers/    # Route controllers
│   ├── models/         # Mongoose models
│   ├── routes/         # API routes
│   ├── middleware/     # Custom middleware
│   └── server.js       # Entry point
│
└── frontend/           # React Application (Vite)
    ├── src/
    │   ├── assets/     # Static assets (images, icons)
    │   ├── components/ # Reusable UI components (TeaBackground)
    │   ├── css/        # Dedicated CSS files (Dashboard.css, index.css)
    │   ├── pages/      # Page components (Dashboard.jsx)
    │   ├── routes/     # Routing configuration (AppRoutes.jsx)
    │   ├── App.jsx     # Main App component
    │   └── main.jsx    # DOM rendering
    └── vite.config.js  # Vite configuration
```

## ⚙️ Setup & Installation

### Prerequisites
- Node.js & npm installed.
- MongoDB Atlas URI.

### 1. Clone the Repository
```bash
git clone https://github.com/kanzur/iTeaGrow-Web-Application.git
cd iTeaGrow-Web-Application
```

### 2. Repositories & Branch Management
This project is maintained across two repositories:
1.  **Main Deployment Repo**: [kanzur/iTeaGrow-Web-Application](https://github.com/kanzur/iTeaGrow-Web-Application) (Branch: `main`)
    -   *Used for Railway deployment.*
2.  **Research Tracking Repo**: [Thomiantrooper/iTeaGrow---Research-Project](https://github.com/Thomiantrooper/iTeaGrow---Research-Project) (Branch: `iTeaGrow-Web-Application`)
    -   *Used for research tracking purposes.*

**To push changes to BOTH repositories simultaneously:**
```bash
npm run push-all
```
*This command pushes your local `main` branch to both remotes automatically.*

### 3. Install Dependencies (One-Step)
We've provided a helper script to install dependencies for the root, backend, and frontend in one go:
```bash
npm run setup
```
*Alternatively, you can install them manually by running `npm install` in the root, `backend/`, and `frontend/` directories respectively.*

### 4. Environment Setup
**Note:** `.env` files are currently included in the repository for ease of setup.
- **Backend**: `backend/.env` is pre-configured.
  ```env
  PORT=5000
  MONGODB_URI=your_mongodb_connection_string
  ```
- **Frontend**: Create `frontend/.env` with:
  ```env
  VITE_API_URL=http://localhost:5000/api
  ```

### 5. Run the Application

**Option A: Run Full Stack (Recommended)**
Run both frontend and backend concurrently:
```bash
npm start
```

**Option B: Run Separately**
- **Backend Only**:
  ```bash
  npm run server
  # OR
  npm run backend
  ```
- **Frontend Only**:
  ```bash
  npm run client
  # OR
  npm run frontend
  ```

## 🚀 Deployment (Railway)

This project is configured for seamless deployment on Railway.

### Option 1: Single Service (Recommended)
1.  **Push** your code to GitHub.
2.  **Login** to Railway and create a new project from your GitHub repo.
3.  **Settings**:
    -   Root Directory: `/` (default)
    -   Build Command: `npm run build`
    -   Start Command: `npm run server`
4.  **Variables**: Add `MONGODB_URI` and `NODE_ENV=production`.

### Option 2: Two Services
You can also deploy `backend` and `frontend` as separate services by setting the "Root Directory" to `/backend` and `/frontend` respectively in Railway settings.
