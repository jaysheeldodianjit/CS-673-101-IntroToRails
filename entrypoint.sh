#!/bin/bash
set -e

APP_DIR="/app/rottenpotatoes"

# Create Rails app if not present
if [ ! -d "$APP_DIR" ]; then
  cd /app
  rails _4.2.11.3_ new rottenpotatoes --skip-test-unit --skip-turbolinks --skip-spring
  cd rottenpotatoes

  # Pin sqlite3 and ffi
  sed -i "s/^gem 'sqlite3'.*/gem 'sqlite3', '~> 1.3.0'/" Gemfile
  printf "\n# Pin ffi for Ruby 2.6 / old RubyGems\ngem 'ffi', '1.15.5'\n" >> Gemfile

  bundle _1.17.3_ install
  bundle _1.17.3_ update sqlite3

  # Generate migration, model, and add columns
  rails generate migration create_movies
  rake db:migrate

  printf "class Movie < ActiveRecord::Base\nend\n" > app/models/movie.rb

  rails g migration add_core_fields_to_movies title:string rating:string description:text release_date:datetime
  rake db:migrate

  # Seed data
  cat > db/seeds.rb <<'RUBY'
more_movies = [
  { title: 'Aladdin',               rating: 'G',     release_date: '25-Nov-1992' },
  { title: 'When Harry Met Sally',  rating: 'R',     release_date: '21-Jul-1989' },
  { title: 'The Help',              rating: 'PG-13', release_date: '10-Aug-2011' },
  { title: 'Raiders of the Lost Ark', rating: 'PG',  release_date: '12-Jun-1981' }
]
more_movies.each { |m| Movie.create!(m) }
RUBY

  rake db:seed

  # Routes
  cat > config/routes.rb <<'RUBY'
Rails.application.routes.draw do
  resources :movies
  root :to => redirect('/movies')
end
RUBY

  # Scaffold controller
  rails g scaffold_controller Movie title rating description release_date --skip-test
fi

cd $APP_DIR
rails server -b 0.0.0.0 -p 3000