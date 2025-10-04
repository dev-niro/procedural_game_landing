require 'roda'
require 'json'

class App < Roda
  # DEV URL =  strangely-distinct-longhorn.ngrok-free.app
  plugin :json
  plugin :render, engine: 'erb', views: 'views'
  plugin :public, root: 'public'

  SCORES_FILE = "scores.json"

  def read_scores
    return [] unless File.exist?(SCORES_FILE)
    content = File.read(SCORES_FILE).strip
    content.empty? ? [] : JSON.parse(content)
  end

  def write_scores(data)
    File.write(SCORES_FILE, JSON.pretty_generate(data))
  end

  route do |r|
    # Landing page (render index.erb)
    r.root do
      view("index", layout: false)
    end

    r.on "api" do
      r.on "highscores" do
        r.get do
          read_scores.sort_by { |s| -s["score"].to_i }.take(10)
        end

        r.post do
          data = r.params.empty? ? JSON.parse(r.body.read) : r.params
          scores = read_scores
          scores << { "player" => data["player"], "score" => data["score"].to_i }
          write_scores(scores)
          { status: "ok" }
        end
      end
    end
  end
end
