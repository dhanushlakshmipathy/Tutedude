# DevOps Project: Node.js Frontend + Flask Backend

This project consists of a Node.js (Express) frontend and a Flask backend, containerized with Docker and orchestrated using Docker Compose.

## Project Structure

- `frontend/`: Node.js Express application serving the frontend.
- `backend/`: Python Flask application handling API requests.
- `docker-compose.yaml`: Orchestration file to run both services.

## Prerequisites

- Docker
- Docker Compose

## Running Locally

1.  Build and start the services:
    ```bash
    docker-compose up --build
    ```

2.  Access the frontend at `http://localhost:3000`.

3.  Submit the form. The data will be sent to the backend (running on port 5000).

## Docker Hub Deployment

To push the images to Docker Hub:

1.  Login to Docker Hub:
    ```bash
    docker login
    ```

2.  Tag the images:
    ```bash
    docker tag tutedude-frontend <your-dockerhub-username>/devops-project-frontend:latest
    docker tag tutedude-backend <your-dockerhub-username>/devops-project-backend:latest
    ```

3.  Push the images:
    ```bash
    docker push <your-dockerhub-username>/devops-project-frontend:latest
    docker push <your-dockerhub-username>/devops-project-backend:latest
    ```

## GitHub Repository

1.  Initialize Git (if not already done):
    ```bash
    git init
    ```

2.  Add files:
    ```bash
    git add .
    ```

3.  Commit changes:
    ```bash
    git commit -m "Initial commit: Frontend, Backend, and Docker configuration"
    ```

4.  Push to GitHub:
    ```bash
    git remote add origin <your-github-repo-url>
    git push -u origin main
    ```
