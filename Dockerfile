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

WORKDIR /app

# Generate the rails app at build time
RUN rails _4.2.11.3_ new rottenpotatoes --skip-test-unit --skip-turbolinks --skip-spring

WORKDIR /app/rottenpotatoes

# Pin sqlite3 and ffi in Gemfile before bundling
RUN sed -i "s/^gem 'sqlite3'.*/gem 'sqlite3', '~> 1.3.0'/" Gemfile && \
    printf "\n# Pin ffi for Ruby 2.6 / old RubyGems\ngem 'ffi', '1.15.5'\n" >> Gemfile

RUN bundle _1.17.3_ install --jobs 4 --retry 3
RUN bundle _1.17.3_ update sqlite3

# DB + model + seeds + CRUD routes and scaffold controller
RUN rails generate migration create_movies && \
    rake db:migrate && \
    printf "class Movie < ActiveRecord::Base\nend\n" > app/models/movie.rb

# Seed the database
RUN cat > db/seeds.rb <<'RUBY' 
more_movies = [
  { title: 'Aladdin',               rating: 'G',     release_date: '25-Nov-1992' },
  { title: 'When Harry Met Sally',  rating: 'R',     release_date: '21-Jul-1989' },
  { title: 'The Help',              rating: 'PG-13', release_date: '10-Aug-2011' },
  { title: 'Raiders of the Lost Ark', rating: 'PG',  release_date: '12-Jun-1981' }
]
more_movies.each { |m| Movie.create!(m) }
RUBY

# Add core fields migration and run it
RUN rails g migration add_core_fields_to_movies title:string rating:string description:text release_date:datetime && \
    rake db:migrate && \
    rake db:seed

# (Optional) add timestamps
RUN rails g migration add_timestamps_to_movies created_at:datetime updated_at:datetime && \
    rake db:migrate

# Update routes
RUN cat > config/routes.rb <<'RUBY' 
Rails.application.routes.draw do
  resources :movies
  root :to => redirect('/movies')
end
RUBY

# Generate scaffold controller
RUN rails g scaffold_controller Movie title rating description release_date --skip-test

# Copy the entrypoint into image
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]