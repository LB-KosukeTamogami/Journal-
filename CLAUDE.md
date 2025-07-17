# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based Journal English Learning App (ジャーナル英語学習アプリ) that helps users learn English through daily journaling. The app features AI-powered translation and correction using Gemini API, data persistence with Supabase, and deployment on Vercel.

## Key Commands

### Local Development
```bash
# Run the app locally with environment variables
./run_local.sh

# Build for web with environment variables
./build_local.sh

# Standard Flutter commands
flutter pub get
flutter run -d chrome
flutter build web
```

### Deployment
```bash
# Deploy to Vercel production
vercel --prod

# Check deployment status
vercel ls
```

### Environment Setup
Copy `.env.example` to `.env` and configure:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GEMINI_API_KEY` (optional)

## Architecture

### Core Services (`lib/services/`)
- **SupabaseService**: Handles all database operations including diary entries, words, and translation cache
- **GeminiService**: AI translation and correction via Gemini API
- **TranslationService**: Offline translation fallback and language detection
- **StorageService**: Local storage wrapper around SupabaseService
- **AuthService**: Authentication management

### Key Models (`lib/models/`)
- **DiaryEntry**: Main diary entry data structure
- **Word**: Vocabulary cards for learning
- **PhraseInfo**: Extracted phrases and words from diary entries

### Main Screens (`lib/screens/`)
- **MainNavigationScreen**: Bottom navigation container with GlobalKey for tab switching
- **HomeScreen**: Dashboard with daily mission and quick actions
- **JournalScreen**: List of diary entries sorted by date (newest first)
- **DiaryCreationScreen**: Multi-step diary creation flow
- **DiaryReviewScreen**: AI-powered review with corrections and translations
- **DiaryDetailScreen**: Detailed view with tabs for diary content and translations
- **LearningScreen**: Vocabulary cards and study features

### Database Structure (Supabase)

Tables:
- `diary_entries`: User diary entries
- `words`: Saved vocabulary cards
- `translation_cache`: Cached AI translations and corrections
  - Includes: translated_text, corrected_text, improvements, judgment, learned_phrases, extracted_words, learned_words

### Important Implementation Details

1. **Navigation Flow**: After diary review completion, app navigates to Journal tab using `MainNavigationScreen.navigatorKey.currentState.navigateToTab(1)`

2. **Sorting**: New diary entries appear at the top (sorted by created_at DESC)

3. **Skeleton Loading**: Implemented in both DiaryReviewScreen and DiaryDetailScreen

4. **Transcription Section (写経)**: 
   - Shows only when translation/correction exists
   - Hidden for correct English (judgment == '英文（正しい）')
   - Condition: `_correctedContent != widget.entry.content`

5. **Rate Limiting**: Gemini API has daily limits, fallback message: "本日のAI利用枠を使い切りました。明日また利用可能になります。"

## Deployment Configuration

### Vercel (`vercel.json`)
- Build command: Custom script `vercel-build-simple.sh`
- Output directory: `build/web`
- Environment variables must be set in Vercel dashboard

### Build Process
The custom build script handles:
- Flutter SDK installation
- Environment variable validation
- Web build with proper configuration

## Common Tasks

### Adding New Features
1. Update models if needed
2. Update SupabaseService for database operations
3. Add UI components following existing patterns
4. Use AppTheme for consistent styling
5. Add animations using flutter_animate

### Modifying Database Schema
1. Create SQL migration file
2. Update SupabaseService methods
3. Update related models
4. Test locally before deploying

### Debugging Issues
- Check Supabase initialization in console logs
- Verify environment variables are set
- Check network requests in browser dev tools
- Review error messages in Gemini API responses