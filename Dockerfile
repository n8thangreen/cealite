# Use a more comprehensive public image
FROM rocker/shiny-verse:latest

# Switch to root user to install system libraries AND R packages
USER root

# Install common system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev

# Use the 'install2.r' script (as root) to install ALL packages
RUN install2.r shiny
RUN install2.r DT
RUN install2.r shinyjs
RUN install2.r jsonlite
RUN install2.r shinyWidgets

# --- NEW STEP: Change Shiny Server port ---
# Hugging Face health checks require port 7860, not 3838
RUN sed -i 's/listen 3838;/listen 7860;/' /etc/shiny-server/shiny-server.conf

# Copy our app.R file into the server's app directory
COPY app.R /srv/shiny-server/

# Explicitly change the owner of the app file to the 'shiny' user
RUN chown shiny:shiny /srv/shiny-server/app.R

# --- Now that all installs are done, switch back to the shiny user ---
USER shiny

# --- NEW STEP: Expose the correct port ---
EXPOSE 7860

# Bypass the failing 's6' startup scripts and run shiny-server directly.
# It will now read the modified config file and run on port 7860.
CMD ["/usr/bin/shiny-server"]