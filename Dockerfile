FROM ruby:2.6.10-bullseye

# OS deps for Rails 4.2 + SQLite + nokogiri compile
RUN apt-get update && apt-get install -y \
    nodejs build-essential git sqlite3 libsqlite3-dev \
    libxml2-dev libxslt1-dev pkg-config \
  && rm -rf /var/lib/apt/lists/*

# Bundler 1.x
RUN gem install bundler -v 1.17.3 --no-document

# ---- Pre-pin old-but-compatible gems (Ruby 2.6) ----
RUN gem install nokogiri -v 1.13.10 --no-document -- --use-system-libraries && \
    gem install loofah -v 2.19.1 --no-document && \
    gem install rails-html-sanitizer -v 1.4.4 --no-document

RUN gem install mail -v 2.7.1 --no-document && \
    gem install net-imap -v 0.3.9 --no-document && \
    gem install net-smtp -v 0.3.3 --no-document || true && \
    gem install net-pop -v 0.1.1 --no-document || true

RUN gem install rails -v 4.2.11.3 --no-document

# Set working directory
WORKDIR /app

# Copy the repository app into the image
COPY rottenpotatoes /app/rottenpotatoes

WORKDIR /app/rottenpotatoes

# Install dependencies (Gemfile already has sqlite3 ~> 1.3.0 and ffi 1.15.5 pinned)
RUN bundle _1.17.3_ install --jobs 4 --retry 3

# Copy the entrypoint into image
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]