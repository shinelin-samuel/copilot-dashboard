FROM node:18-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm --no-frozen-lockfile

# Set pnpm store location
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN pnpm config set store-dir /pnpm

# Copy package files
COPY package*.json ./
COPY pnpm-lock.yaml* ./
COPY tsconfig.json ./

# Install dependencies with frozen lockfile
RUN pnpm install --no-frozen-lockfile

# Copy the rest of the application
COPY . .

# Set environment variables
ENV NODE_ENV=development
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000

# Enable Node.js Inspector for debugging
# ENV NODE_OPTIONS='--inspect=0.0.0.0:9229'

# Clean up pnpm store
RUN pnpm store prune

# Expose the port the app runs on
EXPOSE 3000
# EXPOSE 9229

# Command to run the development server
CMD ["pnpm", "run", "dev"]
