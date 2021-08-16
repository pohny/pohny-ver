FROM node:14
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install coffeescript
RUN npm install
COPY . .
RUN npm run build
CMD [ "node", "bin/www" ]
EXPOSE 3000
EXPOSE 9876
