require 'sinatra'
require 'json'

set :public_folder, 'public'

# Landing page
get '/' do
  erb :index
end

# Highscores API
SCORES_FILE = "scores.json"

helpers do
  def read_scores
    File.exist?(SCORES_FILE) ? JSON.parse(File.read(SCORES_FILE)) : []
  end
  def write_scores(data)
    File.write(SCORES_FILE, JSON.pretty_generate(data))
  end
end

get '/api/highscores' do
  content_type :json
  read_scores.sort_by { |s| -s["score"] }.take(10).to_json
end

post '/api/highscores' do
  content_type :json
  request.body.rewind
  data = JSON.parse(request.body.read) rescue {}
  if data["player"] && data["score"]
    scores = read_scores
    scores << { "player" => data["player"], "score" => data["score"], "time" => Time.now.to_s }
    write_scores(scores)
    { status: "ok" }.to_json
  else
    halt 400, { error: "Invalid payload" }.to_json
  end
end

