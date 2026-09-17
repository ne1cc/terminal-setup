#!/usr/bin/env bash

# ==============================================================================
# macos-defaults.sh — Apply keyboard optimizations for development
# ==============================================================================

echo "Applying keyboard optimizations..."

# 1. Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# 2. Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# 3. Disable automatic capitalization as it's annoying when typing code
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# 4. Disable smart dashes as they're annoying when typing code
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# 5. Disable automatic period substitution as it's annoying when typing code
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# 6. Disable smart quotes as they're annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# 7. Disable auto-correct spelling
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

echo "Keyboard optimizations applied! Restart your applications or log out and back in for changes to take effect."
