# Build the image
docker build -t project-corridor-backend .

# Run the container
docker run -p 5000:5000 project-corridor-backend
