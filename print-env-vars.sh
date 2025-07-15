#!/bin/bash
# Vercelビルド時の環境変数を確認するスクリプト

echo "==== PRINT ENV VARS ===="
echo "Current directory: $(pwd)"
echo "User: $(whoami)"
echo "Date: $(date)"
echo ""

echo "==== All Environment Variables ===="
env | sort
echo ""

echo "==== Filtered Supabase Variables ===="
env | grep -i supabase || echo "No Supabase variables found"
echo ""

echo "==== System Info ===="
echo "OS: $(uname -a)"
echo "Shell: $SHELL"
echo "==== END ====="