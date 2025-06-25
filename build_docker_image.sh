#!/bin/bash

echo "🧹 Stopping existing containers..."
docker-compose down

echo "🏗️  Rebuilding images..."
docker-compose build

echo "🚀 Starting services..."
docker-compose up

echo "✅ Build complete!"
echo ""
echo "To run the services:"
echo "  docker-compose up"
echo ""
echo "To run individually:"
echo "  docker run -p 5000:5000 project-corridor-server"
echo "  docker run -p 5001:5001 project-corridor-dashboard"
echo ""
echo "Dashboard will be available at: http://localhost:5001"
echo "Server WebSocket endpoint: ws://localhost:5000/ws"
