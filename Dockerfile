FROM ruby:2.6.10-bullseye

# OS deps for Rails 4.2 + SQLite + nokogiri compile
RUN apt-get update && apt-get install -y     nodejs build-essential git sqlite3 libsqlite3-dev     libxml2-dev libxslt1-dev pkg-config     && rm -rf /var/lib/apt/lists/*

# Bundler 1.x
RUN gem install bundler -v 1.17.3 --no-document

# ---- Pre-pin old-but-compatible gems (Ruby 2.6) ----
# Nokogiri + sanitizer stack
RUN gem install nokogiri -v 1.13.10 --no-document -- --use-system-libraries &&     gem install loofah -v 2.19.1 --no-document &&     gem install rails-html-sanitizer -v 1.4.4 --no-document

# Mail stack that plays nice with Rails 4.2 on Ruby 2.6
# - actionmailer 4.2 accepts mail >= 2.5.4; we pin 2.7.1 to avoid the newer net-* split
# - preinstall net-* fallbacks in case rubygems still tries to upgrade them
RUN gem install mail -v 2.7.1 --no-document &&     gem install net-imap -v 0.3.9 --no-document &&     gem install net-smtp -v 0.3.3 --no-document || true &&     gem install net-pop  -v 0.1.1 --no-document || true

# Finally, Rails 4.2
RUN gem install rails -v 4.2.11.3 --no-document

WORKDIR /app
COPY rottenpotatoes /app/rottenpotatoes
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["/app/entrypoint.sh"]