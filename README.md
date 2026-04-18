# iTeaGrow: AI-IoT System For Tea Leaf Monitoring, Fertilization, and Powder Grading

## Project Overview
**iTeaGrow** is an integrated AI–IoT research platform designed to modernize decision-making in the Sri Lankan tea industry.  
The system replaces subjective, manual assessment practices with **data-driven, explainable, and hybrid-capable intelligence** across the full tea value chain from field-level leaf plucking to factory-grade yield estimation and market valuation.

The platform combines **computer vision**, **machine learning**, and **edge IoT sensing** to support smallholder farmers, estate supervisors, and factory-level analysts in improving productivity, consistency, and economic outcomes.

## High-Level System Architecture
iTeaGrow operates as a **hybrid edge–mobile–cloud architecture**
<img width="1536" height="1024" alt="HA" src="https://github.com/user-attachments/assets/6a2fac10-94a0-4237-81b6-d8d2de991c8d" />

## Repository Structure
This repository features a lightweight, custom-built CSS and HTML architecture to ensure maximum performance and cross-device compatibility, purposely staying well under external hosting size limits.

```text
/
├── index.html              # Homepage & Abstract
├── pages/                  # Core Content Routes
│   ├── domain.html         # Literature, Gap Analysis, Methodology
│   ├── milestones.html     # Academic Assessment Tracker
│   ├── documents.html      # Linked Report PDFs
│   ├── presentations.html  # Downloadable Slide Decks
│   ├── about.html          # Team Member Profiles
│   └── contact.html        # Inquiry & Research Contacts
├── css/                    # Modular Design System
│   ├── variables.css       # Color & Typography Tokens
│   ├── base.css            # Resets & Global Alignment
│   ├── layout.css          # Structural Grids (Header/Footer)
│   └── components.css      # Reusable UI Elements (Cards/Buttons)
└── assets/                 # Supporting Media
    ├── images/
    └── documents/
```

## Publishing Updates (Developer Guide)
This local repository is configured with a custom git macro to ensure changes are synced across multiple project forks seamlessly.

If you modify any of the HTML/CSS files, simply open your terminal in the root folder and run:
```bash
git add .
git commit -m "Your commit message"
git publish
```
The `git publish` macro automatically pushes the website mapping to:
1. The `iTeaGrow-RP-Website` branch on the primary `Thomiantrooper/iTeaGrow---Research-Project` repository.
2. The `main` branch on the `kanzur/iTeaGrow-RP-Website` deployment repository.

## Live Hosting via Railway
This static repository is fully optimized to be deployed natively on [Railway](https://railway.app/) with zero configuration. Because we explicitly have an `index.html` at the root directory, Railway automatically figures out how to natively serve it!

To take this site live:
1. Log in to your Railway dashboard and click **New Project**.
2. Select **Deploy from GitHub repo** and choose your `iTeaGrow-RP-Website` repository.
3. Railway will instantly detect the static HTML and deploy it globally.
4. Once deployed, click on your app in Railway, go to the Settings tab, and Generate a Public Domain!

---
*Developed for 2026 Academic Submissions.*
