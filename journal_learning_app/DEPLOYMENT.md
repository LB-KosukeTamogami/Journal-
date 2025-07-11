# Deployment Guide

## Required Environment Variables

### Vercel Environment Variables

The following environment variables must be set in Vercel:

1. **SUPABASE_URL**
   - Your Supabase project URL
   - Format: `https://xxxxx.supabase.co`
   - Do NOT include trailing slash

2. **SUPABASE_ANON_KEY**
   - Your Supabase anon/public key
   - This is the public key, NOT the service_role key

### How to Set Environment Variables in Vercel

1. Go to your Vercel project dashboard
2. Navigate to Settings → Environment Variables
3. Add the following variables:
   - Name: `SUPABASE_URL`
   - Value: Your Supabase URL
   - Environment: Production, Preview, Development
   
4. Add another variable:
   - Name: `SUPABASE_ANON_KEY`
   - Value: Your Supabase anon key
   - Environment: Production, Preview, Development

5. Redeploy your project

### Common Issues

- **DO NOT** use `SUPABASE_SERVICE_ROLE_KEY` - this is for server-side only
- **DO NOT** use `NEXT_PUBLIC_` prefix unless specifically required
- Make sure there are no quotes around the values in Vercel
- Make sure the URL does not have a trailing slash

### Verifying Environment Variables

After deployment, you can check if environment variables are loaded correctly:
1. Visit your deployed app
2. Click on "🔧 環境設定を確認" button on the auth landing page
3. Check if both variables show as "設定済み"