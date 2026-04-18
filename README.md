# iTeaGrow | Research Project Website

Welcome to the static presentation and documentation website for the **iTeaGrow** research project. This platform serves as a central hub for our academic findings, tracking project milestones, and securely sharing final documentation on IoT-based Tea Leaf Disease Detection.

## Project Overview
The iTeaGrow research initiative focuses on bridging the gap between hardware and software in precision agriculture. The project heavily targets edge-optimized Computer Vision integrated with real-time IoT sensor telemetry to rapidly diagnose and treat tea leaf anomalies in the field.

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
