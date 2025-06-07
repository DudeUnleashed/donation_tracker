# Use an official Node.js runtime as a parent image
FROM node:18

# Set the working directory in the container
WORKDIR /web

# Copy the package.json and install dependencies
COPY package.json /web/package.json
COPY package-lock.json /web/package-lock.json
RUN npm install

# Copy the rest of the app
COPY . /web

# Expose port 3000
EXPOSE 3000

# Start the React app
CMD ["npm", "start"]
