class MoviesController < ApplicationController
  # GET /movie - Get All Movies List
  # GET /movie?category=genre - Get All Movies List Categorized Bu "genre"
  # GET /movie?sort=release_date - Get All Movies List Sorted By "release_date"
  # GET /movie?week_limit=1 - Get All Movies List Released Within "1" week
  # GET /movie?featured=true - Get All Featured Movies List
  def index
    @movies = Movie.all
    query_params = request.query_parameters

    if query_params.has_key?("category")
      category_opt = query_params["category"]
      @movies = @movies.group_by { |movie| movie[category_opt] }
    end

    if query_params.has_key?("sort")
      sort_opt = query_params["sort"]
      @movies = @movies.sort_by { |movie| movie[sort_opt] }
    end

    if query_params.has_key?("week_limit")
      week_limit_no = query_params["week_limit"]
      @movies = @movies.where('release_date > ?', week_limit_no.week.ago)
    end

    if query_params.has_key?("featured")
      is_featured = ActiveModel::Type::Boolean.new.cast(query_params["featured"])
      @movies = @movies.where(featured: is_featured)
    end

    render json: @movies, status: 200
  end

  # GET /movie/:id - Get Movie By ID From Movies List
  def show
    movie_id = params[:id]
    if Movie.exists?(id: movie_id)
      return render json: Movie.find(movie_id), status: 200
    end
    render json: "Movie Not Found", status: 404
  end

  # POST /movie - Add A New Movie To Movies List
  def create
    movie = Movie.create(movie_params)

    params["actors_ids"].present? && params["actors_ids"].each do
    |actor_id|
      if Celebrity.exists?(id: actor_id, celebrity_type: "celebrity")
        movie.movie_celebrities.build({ celebrity_id: actor_id })
      end
    end

    params["awards_ids"].present? && params["awards_ids"].each do
    |award_id|
      if Award.exists?(id: award_id)
        movie.movie_awards.build({ award_id: award_id })
      end
    end

    params["genres_ids"].present? && params["genres_ids"].each do
    |genre_id|
      if Genre.exists?(id: genre_id)
        movie.movie_genres.build({ genre_id: genre_id })
      end
    end

    if params["director_id"].present?
      director_id = params["director_id"]
      if Celebrity.exists?(id: director_id, celebrity_type: "director")
        movie.director_id = director_id
      end
    end

    movie.save!
    render json: movie, status: 201
  end

  # PUT/PATCH /movie/:id - Update A Movie By ID From Movies List
  # User Can Use This To Add/Remove Movies To/From Featured Movies List
  def update
    begin
      @movie = Movie.update(movie_params)
    rescue
      return render status: 500
    end
    render json: @movie, status: 202
  end

  # DELETE /movie/:id - Delete Movie By ID From Movies List
  def destroy
    movie_id = params[:id]
    if Movie.exists?(id: movie_id)
      Movie.find(movie_id).destroy!
      return render json: "Movie Deleted Successfully", status: 204
    end
    render json: "Movie Not Found", status: 404
  end

  # post /movie/:id/rate - Add User Rate from 0 to 10 To A Movie
  def addMovieRate
    req_params = movie_user_rate_params
    movie_id = params[:id]
    movie = Movie.find(movie_id)
    movie.movie_rates.build({ user_id: req_params["user_id"] }).save!
    render json: "Rate Submitted", status: 200
  end

  # post /movie/:id/watchlist - Add A Movie For A User Watchlist
  def addMovieToUserWatchlist
    req_params = movie_user_rate_params
    movie_id = params[:id]
    movie = Movie.find(movie_id)
    movie.watchlists.build({ user_id: req_params["user_id"] }).save!
    render json: "Added To Watchlist", status: 200
  end

  # post /movie/:id/comment - Add A User Comment/Review On A Movie
  def addUserCommentToMovie
    req_params = movie_user_rate_params
    movie_id = params[:id]
    movie = Movie.find(movie_id)
    movie.comments.build({ user_id: req_params["user_id"] }).save!
    render json: "Comment Submitted", status: 200
  end

  # GET /movie/search?query=something - Search In News Content About Word "something"
  def search
    return unless request.query_parameters['query']
    query = request.query_parameters['query']
    movies = Movie.search_movie_title(query)
    render json: movies
  end

  private

  def movie_params
    params.permit(:title, :description, :rating, :release_date, :film_rate_id, :featured, :actors_ids, :awards_ids, :genres_ids, :director_id, :poster_path, :language)
  end

  def movie_details_params
    params.permit(:actors_ids, :awards_ids, :genres_ids, :director_id)
  end

  def movie_user_rate_params
    params.permit(:user_id, :rate)
  end

  def movie_user_watchlist_params
    params.permit(:user_id)
  end

  def movie_user_comment_params
    params.permit(:user_id, :comment)
  end
end
