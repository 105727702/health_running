# Firebase Firestore Structure Setup Guide

## Required Collections Structure

Based on your code, you need to create the following structure in Firebase Console:

```
users/
└── {userId}/
    ├── activities/           # Individual tracking sessions
    │   └── {sessionId}
    │       ├── distance: number
    │       ├── calories: number
    │       ├── duration: number
    │       ├── activityType: string
    │       ├── startTime: string (ISO)
    │       ├── endTime: string (ISO)
    │       ├── route: array of {latitude, longitude}
    │       ├── createdAt: timestamp
    │       └── date: string (YYYY-MM-DD)
    │
    └── daily_summaries/      # Daily summary data
        └── {YYYY-MM-DD}
            ├── date: string
            ├── totalDistance: number
            ├── totalCalories: number
            ├── totalSteps: number
            ├── sessionCount: number
            └── updatedAt: timestamp
```

## Steps to Create Data Structure

1. **In Firebase Console:**
   - Click "Start collection" 
   - Name: `users`
   - Click "Next"

2. **Create User Document:**
   - Document ID: Use your user UID (visible in Authentication tab)
   - Add a field: `createdAt` (timestamp)
   - Click "Save"

3. **Create Activities Subcollection:**
   - Click on your user document
   - Click "Start collection"
   - Collection ID: `activities`
   - Add a sample document with the fields shown above

4. **Create Daily Summaries Subcollection:**
   - Go back to your user document
   - Click "Start collection" 
   - Collection ID: `daily_summaries`
   - Add a sample document with date as document ID (e.g., "2025-06-29")
