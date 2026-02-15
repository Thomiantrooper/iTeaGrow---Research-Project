# SendGrid Setup for Railway (Production Email)

## Why SendGrid?
Gmail SMTP (port 587) is **blocked by Railway** and most cloud platforms to prevent spam. SendGrid is designed for cloud deployments and has a **free tier** (100 emails/day).

## Setup Steps:

### 1. Create SendGrid Account
1. Go to https://signup.sendgrid.com/
2. Sign up for a **FREE account** (no credit card required)
3. Verify your email address

### 2. Create API Key
1. Log in to SendGrid dashboard
2. Go to **Settings** → **API Keys**
3. Click **Create API Key**
4. Name it: `iTeaGrow-Railway`
5. Select **Full Access** (or at minimum: Mail Send permissions)
6. Click **Create & View**
7. **COPY THE API KEY** (you won't see it again!)

### 3. Verify Sender Email
1. Go to **Settings** → **Sender Authentication**
2. Click **Verify a Single Sender**
3. Enter your admin email: `testmailkanzur@gmail.com`
4. Fill in the form and submit
5. Check your email and click the verification link

### 4. Add to Railway Environment Variables
1. Go to Railway dashboard → Your project
2. Click **Variables** tab
3. Add new variable:
   - **Name**: `SENDGRID_API_KEY`
   - **Value**: `SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (paste your API key)
4. The app will automatically redeploy

## How It Works:
- **Production (Railway)**: Uses SendGrid automatically when `NODE_ENV=production` and `SENDGRID_API_KEY` is set
- **Local Development**: Uses Gmail SMTP (your existing setup)

## Testing:
After adding the API key to Railway, try sending a reply from the Feedback module. You should see:
```
SendGrid email sent successfully: 202
```

## Troubleshooting:
- **"SendGrid delivery failed"**: Check that your sender email is verified in SendGrid
- **"Unauthorized"**: Double-check the API key in Railway variables
- **Still using Gmail**: Make sure `NODE_ENV=production` is set in Railway
