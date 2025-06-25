# Build the image
docker build -t project-corridor-server . -f Dockerfile.server

docker build -t project-corridor-dashboard . -f Dockerfile.dashboard

#docker run -p 5000:5000 project-corridor-server
#docker run -p 5001:5001 project-corridor-dashboard

docker-compose up
