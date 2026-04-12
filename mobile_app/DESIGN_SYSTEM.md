# StreetWatch Design System

## Overview
StreetWatch is a premium mobile-first civic-tech application with a strong focus on gamification, clean UI, and motivating user experience.

## Design Principles
- **Modern & Premium**: High-quality mobile app experience
- **Energetic**: Dynamic colors and engaging animations
- **Motivating**: Gamification elements throughout
- **Civic-Focused**: Community-driven aesthetic
- **Clean but Expressive**: Balanced visual hierarchy

## Color Palette

### Primary Colors
- **Civic Blue**: `#1e3a8a` - Main brand color
- **Civic Blue Light**: `#3b82f6` - Interactive elements
- **Electric Orange**: `#f97316` - Accent and CTAs
- **Emerald**: `#10b981` - Gamification success
- **Lime**: `#84cc16` - XP and achievements

### Semantic Colors
- **Success**: `#10b981` (Green)
- **Warning**: `#eab308` (Yellow)
- **Danger**: `#ef4444` (Red)
- **Info**: `#3b82f6` (Blue)

### Neutral Colors
- **Background**: `#f8fafc` - Soft light background
- **Card**: `#ffffff` - White cards
- **Text Primary**: `#0f172a` - Dark text
- **Text Secondary**: `#64748b` - Muted text
- **Border**: `rgba(0, 0, 0, 0.08)` - Subtle borders

## Typography

### Font Family
- **Primary**: Inter (Google Fonts)
- **Fallback**: System fonts (-apple-system, SF Pro)

### Font Weights
- Regular: 400
- Medium: 500
- Semibold: 600
- Bold: 700
- Extrabold: 800
- Black: 900

### Type Scale
- **Hero**: 48px / 3rem (Onboarding)
- **Display**: 36px / 2.25rem (Page titles)
- **Heading 1**: 30px / 1.875rem
- **Heading 2**: 24px / 1.5rem
- **Heading 3**: 20px / 1.25rem
- **Body Large**: 18px / 1.125rem
- **Body**: 16px / 1rem (Default)
- **Body Small**: 14px / 0.875rem
- **Caption**: 12px / 0.75rem
- **Tiny**: 10px / 0.625rem

## Spacing System
Based on 4px grid:
- xs: 4px
- sm: 8px
- md: 12px
- base: 16px
- lg: 20px
- xl: 24px
- 2xl: 32px
- 3xl: 48px
- 4xl: 64px

## Border Radius
- **Small**: 12px - Badges, tags
- **Medium**: 16px - Buttons, inputs
- **Large**: 20px - Cards
- **XL**: 24px - Featured cards
- **2XL**: 32px - Modal sheets
- **Full**: 9999px - Circles, pills

## Shadows
- **Small**: `0 1px 2px rgba(0,0,0,0.05)`
- **Medium**: `0 4px 6px rgba(0,0,0,0.1)`
- **Large**: `0 10px 15px rgba(0,0,0,0.1)`
- **XL**: `0 20px 25px rgba(0,0,0,0.15)`
- **2XL**: `0 25px 50px rgba(0,0,0,0.25)`

## Components

### Buttons
1. **Primary**: Gradient blue, white text
2. **Secondary**: Light gray background
3. **Accent**: Orange gradient, white text
4. **Ghost**: Transparent with colored text

### Cards
- White background
- Rounded corners (16-24px)
- Subtle border or shadow
- Padding: 16-20px

### Badges (Gamification)
- Common: Gray gradient
- Rare: Blue gradient
- Epic: Purple gradient
- Legendary: Gold gradient

### Progress Bars
- Background: `#f1f5f9`
- Fill: Green to lime gradient
- Height: 12px
- Rounded full
- Animated on mount

### Navigation
- Bottom tab bar
- 4 main sections
- Active state with top indicator
- Icon + label

## Gamification Elements

### XP System
- Progress bar with gradient
- Current/Max display
- Level indicator
- Animated fills

### Badges
- 9 total badges
- 4 rarity levels
- Large emoji icons
- Locked/unlocked states
- Celebration on unlock

### Leaderboard
- Top 3 podium design
- Rank indicators
- Avatar + stats
- Current user highlight

### Severity Indicators
- Critical: Red
- High: Orange
- Medium: Yellow
- Low: Green

## Screen Layouts

### Mobile Container
- Max width: 430px
- Height: 932px (iPhone 14 Pro Max)
- Rounded corners: 48px
- Shadow: Large
- Centered on desktop

### Screen Structure
1. Header (gradient background)
2. Content area (scrollable)
3. Bottom navigation (fixed)

## Animations

### Transitions
- Duration: 0.3s default
- Easing: ease-out
- Scale on tap: 0.95-0.98

### Motion
- Slide in from right
- Fade in from bottom
- Scale spring for success
- Confetti on achievements

## States

### Loading
- Spinner animation
- Progress bar
- Skeleton loaders

### Success
- Green checkmark
- Confetti animation
- Gradient background

### Error
- Red color scheme
- Alert icon
- Retry button

## Accessibility
- Focus visible outlines
- Sufficient color contrast
- Touch targets: 44px minimum
- Screen reader support
- Semantic HTML

## Implementation Notes
- Built with React + TypeScript
- Styled with Tailwind CSS v4
- Animations with Framer Motion
- Mobile-first responsive
- Optimized for iOS Safari
